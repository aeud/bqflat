locals {
    json_data = jsondecode(file("${path.module}/../../configs/${var.config}.json"))
}

resource "google_cloud_scheduler_job" "job" {
    name = var.config
    schedule = local.json_data.schedule
    time_zone = local.json_data.time_zone
    attempt_deadline = "320s"

    retry_config {
        retry_count = 1
    }

    http_target {
        http_method = "POST"
        uri = "https://workflowexecutions.googleapis.com/v1/${var.cloud_workflow_id}/executions"
        body = base64encode(jsonencode({
            "argument"=jsonencode({
                "sql"=base64encode(templatefile("${path.module}/../../sql/${lookup(local.json_data, "sql_file", join("", [var.config, ".sql"]))}", var.env_vars)),
                "destination_uri"="gs://${var.destination_bucket_name}/${var.config}/${local.json_data.file_key}",
                "vars"=lookup(local.json_data, "vars", "{}"),
            })
        }))
        headers = {
            "Content-Type" = "application/json"
        }
        oauth_token {
            service_account_email = var.service_account_email
        }
    }
}