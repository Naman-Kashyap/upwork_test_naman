dbt Project Template
Overview
This dbt project template is designed for dbt projects, focusing on data modeling. It provides a structured approach to on how to organise your dbt projects.

Project Structure
This document describes the directory structure of the dbt project template.

Files and Folders

.github/: This directory contains GitHub-specific files and workflows.
workflows/: This subdirectory contains GitHub Actions workflow files.
ci.yml: This file contains the continuous integration workflow configuration.
cd.yml: This file contains the continuous deployment workflow configuration.
dbt_docs.yml: This file contains the configuration for generating dbt documentation.
PULL_REQUEST_TEMPLATE.md: This file contains the template for pull request descriptions.
README.md: This file contains an overview of the project.
analyses/: This directory contains SQL files for various data analyses.
dbt_packages/: This directory contains custom dbt packages.
macros/: This directory contains custom SQL macros.
models/: This directory contains SQL files to define data models.
core/: This subdirectory contains models for core business entities.
mart/: This subdirectory contains models for the data mart.
staging/: This subdirectory contains models for staging data.
seeds/: This directory contains SQL files to seed data for testing.
snapshots/: This directory contains snapshots of model outputs for testing.
tests/: This directory contains unit tests for the dbt project.
dbt_project.yml: This file configures the dbt project.
packages.yml: This file specifies the dbt packages used in the project.
profiles.yml: This file configures dbt profiles for connecting to databases.
requirements.txt: This file lists the Python dependencies required for the project.
sqlfluff: A SQL linter and formatter for maintaining SQL style consistency and quality.
dbt-bigquery: The dbt adapter for Google BigQuery, enabling dbt to run on BigQuery.
shandy-sqlfmt: A SQL formatter to automatically format SQL files for readability.