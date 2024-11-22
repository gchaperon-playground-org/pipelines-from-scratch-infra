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

resource "google_storage_bucket_iam_member" "object_user" {
  bucket = google_storage_bucket.pipeline_artifacts.name
  role = "roles/storage.objectUser"
  member = "serviceAccount:${google_service_account.product.email}"
}

resource "random_id" "pipeline_artifacts_bucket_id" {
  byte_length = 4
}