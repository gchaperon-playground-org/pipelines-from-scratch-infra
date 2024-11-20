resource "google_storage_bucket" "default" {
  name          = "${local.project}-deleteme"
  location      = "US"
  force_destroy = true
}

resource "google_project_service" "services" {
  for_each = toset(["aiplatform.googleapis.com"])
  service  = each.key
}