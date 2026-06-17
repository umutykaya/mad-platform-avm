"""Unit tests for transform_sales business logic.
Run with: pytest jobs/ingest/tests/
"""

import pytest
from pyspark.sql import SparkSession
from pyspark.sql import Row

import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
from transform_sales import cleanse, aggregate_daily


@pytest.fixture(scope="module")
def spark():
    return (
        SparkSession.builder
        .master("local[1]")
        .appName("test-transform-sales")
        .getOrCreate()
    )


def test_cleanse_drops_nulls(spark):
    data = [
        Row(order_id="1", amount=10.0, sale_date="2024-01-01", store_id="A"),
        Row(order_id=None,  amount=5.0,  sale_date="2024-01-01", store_id="A"),  # null order_id
        Row(order_id="3", amount=-1.0, sale_date="2024-01-01", store_id="A"),  # negative amount
    ]
    df = spark.createDataFrame(data)
    result = cleanse(df)
    assert result.count() == 1
    assert result.first()["order_id"] == "1"


def test_aggregate_daily_sums(spark):
    data = [
        Row(order_id="1", amount=100.0, sale_date="2024-01-01", store_id="A"),
        Row(order_id="2", amount=200.0, sale_date="2024-01-01", store_id="A"),
        Row(order_id="3", amount=50.0,  sale_date="2024-01-01", store_id="B"),
    ]
    df = spark.createDataFrame(data)
    result = aggregate_daily(df).collect()
    store_a = next(r for r in result if r["store_id"] == "A")
    assert store_a["total_sales"] == 300.0
    assert store_a["order_count"] == 2
