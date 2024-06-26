# BigQuery Job Executor

This script is designed to execute a SQL query on Google BigQuery and export the results to Google Cloud Storage (GCS). It leverages Jinja2 for templating SQL queries and destination URIs and includes options for dynamic variables and date handling.

## Features

- Execute SQL queries on Google BigQuery.
- Export query results to Google Cloud Storage in CSV format.
- Use Jinja2 templating for dynamic SQL and URI generation.
- Support for date-based templating variables.
- Logging for monitoring execution flow and debugging.

## Requirements

- Python 3.x
- Google Cloud SDK
- Required Python libraries:
  - `google-cloud-bigquery`
  - `click`
  - `jinja2`

## Environment Variables

- `BIGQUERY_JOB_EXECUTING_PROJECT`: Google Cloud project ID for executing BigQuery jobs.
- `BIGQUERY_STAGING_DATASET`: BigQuery dataset for storing temporary tables.

## Installation

1. Install Python 3.x.
2. Install the required Python libraries:

   ```bash
   pip install google-cloud-bigquery click jinja2
   ```

3. Set up Google Cloud SDK and authenticate with your Google Cloud account:

   ```bash
   gcloud auth application-default login
   ```

4. Set the necessary environment variables:

   ```bash
   export BIGQUERY_JOB_EXECUTING_PROJECT=<your-project-id>
   export BIGQUERY_STAGING_DATASET=<your-staging-dataset>
   ```

## Usage

```bash
python script.py --destination-uri <destination-uri> --sql <base64-encoded-sql> [--date <date>] [--json-vars <json-variables>]
```

### Options

- `--destination-uri`: Required. The URI of the destination in GCS where the results will be stored. Supports Jinja2 templating.
- `--sql`: Required. The SQL query to execute, encoded in base64.
- `--date`: Optional. The date to use for templating, in `YYYY-MM-DD` format. Defaults to the current date.
- `--json-vars`: Optional. JSON string of variables for templating.

### Example

```bash
python script.py --destination-uri gs://my-bucket/{{ today_dash }}-output.csv --sql U0VMRUNUICogRlJPTSBteV90YWJsZQ== --json-vars '{"param1": "value1"}'
```

## Logging

Logging is set up to output to the console with the format:

```
<module> - <log level> - <message>
```

This helps in tracking the execution flow and debugging.

## Functions

### `set_global_variables(jinja_env)`

Sets global date-related variables for Jinja2 templating.

### `main(sql, destination_uri, date, json_vars)`

Main function to handle the command-line interface and orchestrate the execution.

### `store_query_result_to_table(bigquery_client, sql, table_reference)`

Executes the SQL query and stores the result in a temporary BigQuery table.

### `extract_table_to_blob(bigquery_client, table_reference, destination_uri)`

Extracts the result from the temporary table to a GCS blob in CSV format.

## Notes

- Ensure that the Google Cloud project and BigQuery dataset specified in the environment variables exist and are accessible.
- The SQL query should be base64 encoded to ensure safe transmission through the command line.
- The destination URI and SQL query support Jinja2 templating for dynamic variable substitution.

## License

This project is licensed under the MIT License. See the LICENSE file for details.