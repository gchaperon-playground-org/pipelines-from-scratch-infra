# Metadata store
# https://cloud.google.com/vertex-ai/docs/pipelines/configure-project#create-metadata-store
# NOTE: A metadata store is required, but it is not required to be configured
# using CMEK. For now, ignore CMEK
resource "google_vertex_ai_metadata_store" "default" {
  provider = google-beta
  name     = "default"
}

# AI Platform Custom Code Service Agent must be able to read artifacts from the
# kfp components docket registry. This is poorly documented. Some references
# about Service Agents can be found here
# https://cloud.google.com/iam/docs/service-agents
resource "google_project_iam_member" "artifact_reader" {
  project = local.project
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:service-${data.google_project.default.number}@gcp-sa-aiplatform-cc.iam.gserviceaccount.com"
}

data "google_project" "default" {
}