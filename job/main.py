from google.cloud import bigquery
import logging
import uuid
import os
import click
import base64
import json
from jinja2 import Environment
from datetime import date, timedelta

# Setup logging configuration
logger = logging.getLogger(__name__)
logging.basicConfig(format="%(name)s - %(levelname)s - %(message)s", level=logging.INFO)

BIGQUERY_JOB_EXECUTING_PROJECT = os.environ.get("BIGQUERY_JOB_EXECUTING_PROJECT")
BIGQUERY_STAGING_DATASET = os.environ.get("BIGQUERY_STAGING_DATASET")

def set_global_variables(jinja_env):
    today = date.today()
    yesterday = today - timedelta(days=1)
    jinja_env.globals["input_date"] = date
    jinja_env.globals["today"] = today
    jinja_env.globals["today_dash"] = today.strftime("%Y-%m-%d")
    jinja_env.globals["today_slash"] = today.strftime("%Y/%m/%d")
    jinja_env.globals["yesterday"] = yesterday
    jinja_env.globals["yesterday_dash"] = yesterday.strftime("%Y-%m-%d")
    jinja_env.globals["yesterday_slash"] = yesterday.strftime("%Y/%m/%d")

@click.command()
@click.option(
    "--destination-uri",
    required=True,
)
@click.option(
    "--sql",
    required=True,
)
@click.option(
    "--date",
    type=click.DateTime(formats=["%Y-%m-%d"]),
    default=str(date.today()),
)
@click.option(
    "--json-vars",
    default="{}",
)
def main(sql, destination_uri, date, json_vars):
    uid = uuid.uuid4()
    env = Environment()
    set_global_variables(env)
    try:
        sql = base64.b64decode(sql).decode("utf-8")
    except:
        logger.info("skipping base64 decoding of the SQL query")
        pass
    try:
        vars = json.loads(json_vars)
    except:
        logger.info("could not parse the variables \"%s\". forced to empty." % json_vars)
        vars = {}
    rendered_sql = env.from_string(sql).render(vars)
    rendered_destination_uri = env.from_string(destination_uri).render(vars)
    # Execute the SQL query and store it to a new tmp table
    bigquery_client = bigquery.Client(project=BIGQUERY_JOB_EXECUTING_PROJECT)
    table_reference = "%s.%s.%s" % (
        BIGQUERY_JOB_EXECUTING_PROJECT,
        BIGQUERY_STAGING_DATASET,
        uid,
    )
    logger.info("staging the query result in %s (temporary table)" % table_reference)
    store_query_result_to_table(bigquery_client, rendered_sql, table_reference)
    
    # Extract the table to a blob on Google Cloud Storage
    extract_table_to_blob(bigquery_client, table_reference, rendered_destination_uri)

def store_query_result_to_table(bigquery_client, sql, table_reference):
    bigquery_client.query_and_wait(
        query=sql,
        job_config=bigquery.QueryJobConfig(
            destination=table_reference,
            write_disposition="WRITE_TRUNCATE",
        ),
    )

def extract_table_to_blob(bigquery_client, table_reference, destination_uri):
    bigquery_client.extract_table(
        source=table_reference,
        destination_uris=destination_uri,
        job_config=bigquery.ExtractJobConfig(
            compression="GZIP",
            destination_format="CSV",
            field_delimiter=",",    
        ),
    )

if __name__ == "__main__":
    main()