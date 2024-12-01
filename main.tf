resource "google_project_service" "services" {
  for_each = toset([
    "aiplatform.googleapis.com",
    "artifactregistry.googleapis.com"
  ])
  service = each.key
}

resource "google_artifact_registry_repository" "components" {
  repository_id = "components"
  format        = "DOCKER"

  docker_config {
    immutable_tags = true
  }

  depends_on = [google_project_service.services]
}

resource "google_artifact_registry_repository" "pipelines" {
  repository_id = "pipelines"
  format        = "KFP"

  depends_on = [google_project_service.services]
}

resource "google_artifact_registry_repository_iam_member" "reader" {
  repository = google_artifact_registry_repository.pipelines.id
  role       = "roles/artifactregistry.reader"
  member     = google_service_account.product.member
}

# Service account with granular permissions
# https://cloud.google.com/vertex-ai/docs/pipelines/configure-project#service-account
resource "google_service_account" "product" {
  account_id = "${local.product}-product"
}

resource "google_project_iam_member" "aiplatform_user" {
  project = local.project
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.product.email}"
}

# Cloud Storage bucket for pipeline artifacts
# https://cloud.google.com/vertex-ai/docs/pipelines/configure-project#storage
resource "google_storage_bucket" "pipeline_artifacts" {
  name          = "${local.product}-kfp-artifacts-${random_id.pipeline_artifacts_bucket_id.hex}"
  location      = "US"
  force_destroy = true
}

resource "google_storage_bucket" "component_metadata" {
  name          = "${local.product}-kfp-component-metadata-${random_id.pipeline_artifacts_bucket_id.hex}"
  location      = "US"
  force_destroy = true
}

resource "google_storage_bucket_iam_member" "object_user" {
  bucket = google_storage_bucket.pipeline_artifacts.name
  role   = "roles/storage.objectUser"
  member = google_service_account.product.member
}

resource "random_id" "pipeline_artifacts_bucket_id" {
  byte_length = 4
}

# Product Bigquery Dataset
locals {
  dataset_id = replace(local.product, "-", "_")
}

resource "google_bigquery_dataset" "datasets" {
  for_each                   = toset([local.dataset_id, "${local.dataset_id}_feature"])
  dataset_id                 = each.key
  delete_contents_on_destroy = true
}

resource "google_bigquery_dataset_iam_member" "admin" {
  for_each   = toset([for dataset in google_bigquery_dataset.datasets : dataset.dataset_id])
  dataset_id = each.key
  role       = "roles/bigquery.admin"
  member     = google_service_account.product.member
}

resource "google_project_iam_member" "bigquery_job_user" {
  project = data.google_project.default.id
  role    = "roles/bigquery.jobUser"
  member  = google_service_account.product.member
}