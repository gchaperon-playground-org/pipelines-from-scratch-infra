resource "google_storage_bucket" "default" {
  name          = "${local.project}-deleteme"
  location      = "US"
  force_destroy = true
}

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