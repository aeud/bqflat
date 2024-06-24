

resource "google_project_iam_member" "grant_bigquery_user" {
    project = var.project_id
    role = "roles/bigquery.user"
    member = var.main_service_account.member
}

resource "google_bigquery_dataset" "bigquery_staging" {
    dataset_id = var.staging_dataset_name
    location = var.staging_dataset_location
    default_table_expiration_ms = 3600000
}

resource "google_bigquery_dataset_iam_member" "grant_stg_dataset_admin" {
    dataset_id = google_bigquery_dataset.bigquery_staging.dataset_id
    role = "roles/bigquery.admin"
    member = var.main_service_account.member
}

resource "google_cloud_run_v2_job" "bq_flatfiler" {
    name = var.cloud_run_instance_name
    location = var.project_region

    template {
        template {
            containers {
                image = var.bq_flat_filer_image
                env {
                    name = "BIGQUERY_JOB_EXECUTING_PROJECT"
                    value = var.project_id
                }
                env {
                    name = "BIGQUERY_STAGING_DATASET"
                    value = google_bigquery_dataset.bigquery_staging.dataset_id
                }
            }
            service_account = var.main_service_account.email
            timeout = "7200s"
            max_retries = 1
        }
    }

    lifecycle {
        ignore_changes = [
            launch_stage,
        ]
    }
    depends_on = [
        google_bigquery_dataset_iam_member.grant_stg_dataset_admin,
    ]
}

resource "google_cloud_run_v2_job_iam_member" "cloud_run_member" {
    name = google_cloud_run_v2_job.bq_flatfiler.name
    role = "roles/run.admin"
    member = var.main_service_account.member
}

resource "google_workflows_workflow" "bq_flatfiler" {
    name = var.cloud_workflow_name
    region = var.project_region
    source_contents = <<-EOF
main:
    params: [args]
    steps:
        - run:
            call: googleapis.run.v1.namespaces.jobs.run
            args:
                name: "namespaces/${var.project_id}/jobs/${google_cloud_run_v2_job.bq_flatfiler.name}"
                location: ${google_cloud_run_v2_job.bq_flatfiler.location}
                body:
                    overrides:
                        containerOverrides:
                            args:
                                - --destination-uri
                                - '$${text.replace_all(args.destination_uri, "%time%", time.format(sys.now()))}'
                                - --sql
                                - '$${args.sql}'
                                - --json-vars
                                - '$${default(map.get(args, "vars"), "{}")}'
            result: job_execution
            next: finish
        - finish:
            return: $${job_execution}
EOF
    service_account = var.main_service_account.id
}

resource "google_project_iam_member" "grant_workflow_invoker" {
    project = var.project_id
    role = "roles/workflows.invoker"
    member = var.main_service_account.member
}

module "scheduled_feeds" {
    for_each = toset(var.configs)
    config = each.key
    source = "../scheduled_export"
    cloud_workflow_id = google_workflows_workflow.bq_flatfiler.id
    destination_bucket_name = var.destination_bucket.name
    service_account_email = var.main_service_account.email
    env_vars = var.env_vars
}