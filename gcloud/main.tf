provider "google" {
    project = var.project_id
    region = var.project_region
}

resource "google_service_account" "main_service_account" {
    account_id = var.service_account_name
}

# Optional
resource "google_project_iam_member" "grant_bigquery_dataviewer" {
    project = var.project_id
    role = "roles/bigquery.dataViewer"
    member = google_service_account.main_service_account.member
}

resource "google_storage_bucket" "destination_bucket" {
    name = var.destination_bucket_name
    location = var.destination_bucket_location
    uniform_bucket_level_access = true
}

resource "google_storage_bucket_iam_member" "grant_destination_bucket" {
    bucket = google_storage_bucket.destination_bucket.name
    role = "roles/storage.objectUser"
    member = google_service_account.main_service_account.member
}

module "feeds" {
    source = "./modules/exporter"
    configs = [
        "demo-bqflat-00",
        "demo-bqflat-01",
        "demo-bqflat-02",
    ]
    destination_bucket = google_storage_bucket.destination_bucket
    main_service_account = google_service_account.main_service_account

    project_id = var.project_id
    project_region = var.project_region
    staging_dataset_name = var.staging_dataset_name
    staging_dataset_location = var.staging_dataset_location
    cloud_run_instance_name = var.cloud_run_instance_name
    cloud_workflow_name = var.cloud_workflow_name
    bq_flat_filer_image = var.bq_flat_filer_image
    env_vars = var.env_vars
}