resource "google_service_account" "github_actions" {
  account_id  = "gha-gchaperon-playground-org"
  description = <<-EOT
    Service account for Github Actions permissions for actions comming from
    gchaperon-playground-org"
  EOT
}

resource "google_project_iam_member" "gha_editor" {
  project = data.google_project.default.name
  role = "roles/editor"
  member = google_service_account.github_actions.member
}

resource "google_service_account_iam_member" "my_token_creator" {
  service_account_id = google_service_account.github_actions.id
  role = "roles/iam.serviceAccountTokenCreator"
  member = "user:gabrielchaperonb@gmail.com"
}

output "github_service_account_name" {
  value = google_service_account.github_actions.email
}

resource "google_storage_bucket_iam_member" "object_viewer" {
  bucket = "terraform-states-b9bc8e6f"
  role   = "roles/storage.objectViewer"
  member = google_service_account.github_actions.member
}

resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = "github"
  display_name              = "GitHub Actions Pool"
}

resource "google_service_account_iam_member" "workload_identity_user" {
  service_account_id = google_service_account.github_actions.id
  role               = "roles/iam.workloadIdentityUser"
  # NOTE: this uses ...identity_pool.*.name instead of *.id
  member = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.respository_owner/gchaperon-playground-org"
}

resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "gha-gchaperon-v2"
  description                        = "Github Actions Provider for gchaperon-playground-org"
  attribute_condition                = <<-EOT
    assertion.repository_owner == "gchaperon-playground-org"
  EOT
  attribute_mapping = {
    "google.subject"             = "assertion.sub"
    "attribute.actor"            = "assertion.actor"
    "attribute.repository"       = "assertion.repository"
    "attribute.repository_owner" = "assertion.repository_owner"
  }

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

output "workload_identity_provider_name" {
  value = google_iam_workload_identity_pool_provider.github_provider.name
}

