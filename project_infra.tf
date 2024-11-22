# Metadata store
# https://cloud.google.com/vertex-ai/docs/pipelines/configure-project#create-metadata-store
# NOTE: A metadata store is required, but it is not required to be configured
# using CMEK. For now, ignore CMEK
resource "google_vertex_ai_metadata_store" "default" {
  provider = google-beta
  name     = "default"
}