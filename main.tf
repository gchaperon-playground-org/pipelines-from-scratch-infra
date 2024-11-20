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
  location      = "us-central1"
  repository_id = "components"
  description   = "Repo storing component images"
  format        = "DOCKER"

  docker_config {
    immutable_tags = true
  }

  depends_on = [google_project_service.services]
}