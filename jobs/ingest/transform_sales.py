#!/usr/bin/env python3
"""
transform_sales.py

Reads raw sales CSV from ADLS, applies simple cleansing/aggregation,
and writes Parquet results back to a different container path.

Can be run:
  - As a Databricks Job (entry point file)
  - Locally with PySpark: python transform_sales.py --input_path ./sample --output_path ./out
"""

from __future__ import annotations

import argparse
import logging
import sys
from pathlib import Path

from pyspark.sql import SparkSession, DataFrame
from pyspark.sql import functions as F
from pyspark.sql.types import DoubleType

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Configuration helpers
# ---------------------------------------------------------------------------

def get_config() -> dict:
    """Return job config from CLI args (local) or Databricks widgets (cloud)."""
    try:
        # Running inside Databricks – use dbutils widgets
        import dbutils  # type: ignore  # noqa: F401
        from dbruntime.dbutils import RemoteDbUtils  # type: ignore
        dbutils = RemoteDbUtils()
        return {
            "input_path": dbutils.widgets.get("input_path"),
            "output_path": dbutils.widgets.get("output_path"),
            "env": dbutils.widgets.get("env"),
        }
    except ImportError:
        # Running locally
        parser = argparse.ArgumentParser(description="Sales transform job")
        parser.add_argument("--input_path",  required=True, help="Raw data path (ADLS or local)")
        parser.add_argument("--output_path", required=True, help="Output path (ADLS or local)")
        parser.add_argument("--env",         default="dev",  help="Environment tag")
        args = parser.parse_args()
        return vars(args)


# ---------------------------------------------------------------------------
# Spark session
# ---------------------------------------------------------------------------

def get_spark(env: str) -> SparkSession:
    """Return or create a SparkSession. On Databricks the session already exists."""
    builder = (
        SparkSession.builder
        .appName(f"mad-ingest-transform-sales-{env}")
    )
    if env == "dev":
        builder = builder.master("local[*]")
    return builder.getOrCreate()


# ---------------------------------------------------------------------------
# Business logic (pure functions – easy to unit test)
# ---------------------------------------------------------------------------

def read_raw_sales(spark: SparkSession, path: str) -> DataFrame:
    """Read raw CSV sales data."""
    log.info("Reading raw sales from %s", path)
    return (
        spark.read
        .option("header", True)
        .option("inferSchema", True)
        .csv(path)
    )


def cleanse(df: DataFrame) -> DataFrame:
    """Drop nulls on key columns and cast amount to double."""
    return (
        df
        .dropna(subset=["order_id", "amount", "sale_date"])
        .withColumn("amount", F.col("amount").cast(DoubleType()))
        .filter(F.col("amount") > 0)
    )


def aggregate_daily(df: DataFrame) -> DataFrame:
    """Aggregate to daily totals per store."""
    return (
        df
        .groupBy("sale_date", "store_id")
        .agg(
            F.sum("amount").alias("total_sales"),
            F.count("order_id").alias("order_count"),
        )
        .orderBy("sale_date", "store_id")
    )


def write_parquet(df: DataFrame, path: str) -> None:
    """Write results as Parquet, partitioned by sale_date."""
    log.info("Writing results to %s", path)
    (
        df.write
        .mode("overwrite")
        .partitionBy("sale_date")
        .parquet(path)
    )
    log.info("Write complete.")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main() -> None:
    cfg = get_config()
    spark = get_spark(cfg["env"])

    raw   = read_raw_sales(spark, cfg["input_path"])
    clean = cleanse(raw)
    agg   = aggregate_daily(clean)
    write_parquet(agg, cfg["output_path"])


if __name__ == "__main__":
    main()
