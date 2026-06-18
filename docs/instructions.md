# MAD – Medior DevOps Engineer Technical Assignment

## Goal

This assignment gives you a realistic, MAD‑style problem where you can show how you design and automate a small data platform slice and how you write clean, production‑oriented code.

> **Managed Azure Databricks (MAD)** is Ahold Delhaize's centrally managed, secure and compliant Databricks environment in Azure, providing standardised workspaces, governance, and platform features for data exploration, ML, and production pipelines.

We are interested in:

- How you reason about Azure, Databricks and access separation for multiple teams
- How you structure infrastructure as code and application code
- How you document assumptions, trade‑offs and next steps

You do **not** need to deliver a perfect or complete solution. Clarity of thinking is more important than covering every edge case.

Target time: around **4 hours**.

***

## Scenario

Ahold Delhaize wants to onboard **two internal teams** onto the MAD platform:

- **Team Analytics** – runs ad‑hoc analysis and scheduled jobs in Databricks
- **Team Ingest** – builds ingestion pipelines and manages storage

Both teams:

- Use the same Azure subscription
- Need to work with Databricks and an underlying storage account
- Must not see or modify each other's jobs, notebooks or data

Over time a third and fourth team will join, so the solution should be easy to extend.

***

## What We Ask You to Do

### 1. Design the Platform Slice

Create a short **design** (max 1 page) that shows:

- Which Azure and Databricks resources you would create for these two teams
- How you would separate access between them (RBAC, ACLs, workspaces, etc.)
- Where configuration lives (per team, per environment, shared)

This can be a simple diagram plus bullet points. Any diagram tool (or a clear photo of a hand‑drawn sketch) is fine.

***

### 2. Small Terraform (or Pseudo‑Terraform) Module

Implement a **small, focused Terraform module** that could provision the basics for **one team**.

It should describe:

- A Databricks workspace or equivalent logical resource
- A storage container or similar data boundary
- One or two key access rules / RBAC assignments expressed as code

We **do not expect you to deploy** resources to a real Azure subscription. A local Terraform install and a valid `terraform plan` are completely fine. If you cannot install Terraform locally, "pseudo‑Terraform" that shows realistic modules, variables and outputs is also acceptable.

We care more about:

- Folder structure and naming
- Use of variables and inputs (e.g. team name, environment)
- How easy it would be to add a third team later by reusing the same module

***

### 3. Small Databricks / Python Example

Create a tiny **Python / Spark job** that represents something a team would run on this platform, for example:

- Read data from a storage location
- Apply a simple transformation
- Write results to another location

You can:

- Use a Databricks notebook, or
- Use a plain Python file that would logically run as a Databricks job

If you do not have access to Databricks, you can still write regular Python/Spark code that would work in such an environment; we focus on structure and approach rather than actual cloud execution.

Show us:

- How you structure the code (folders, modules, configuration)
- What you externalise in configuration (paths, environment, secrets as placeholders)
- How you would test or validate it (even if you only sketch the tests)

***

## What to Deliver

Please send:

- A **README** that explains:
    - Your design and assumptions
    - How to run `terraform plan` locally (or how to read your pseudo‑Terraform)
    - How to run the Python / notebook example
    - What you would do next if you had more time
- The code and configuration (Terraform / pseudo‑Terraform + Python / notebooks) as a **single zip or a link to a repository**
- Your **diagram** as an image or PDF

If you run out of time, use the README to explain which parts you would tackle next and why.

***

## Use of AI Tools

You may use AI‑assisted tools (for example GitHub Copilot or ChatGPT) while working on this assignment. We are fine with that.

However:

- Make sure you understand and can explain all code and configuration you submit
- In the README, briefly note where AI helped (e.g. *"generated initial Terraform skeleton"* or *"helped with Python boilerplate"*)

In the interview we will focus on your **reasoning** and your **ability to adapt or extend the solution**, not on perfectly handwritten code.

