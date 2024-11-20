resource "google_storage_bucket" "default" {
  name          = "${local.project}-deleteme"
  location      = "US"
  force_destroy = true
}