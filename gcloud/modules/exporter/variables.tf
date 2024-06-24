variable "configs" {}
variable "destination_bucket" {}
variable "main_service_account" {}

variable "project_id" {}
variable "project_region" {}
variable "staging_dataset_name" {}
variable "staging_dataset_location" {}
variable "cloud_run_instance_name" {}
variable "cloud_workflow_name" {}
variable "bq_flat_filer_image" {}
variable "env_vars" { type = map }