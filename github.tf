resource "google_service_account" "github_actions" {
  account_id  = "gha-gchaperon-playground-org"
  description = <<-EOT
    Service account for Github Actions permissions for actions comming from
    gchaperon-playground-org"
  EOT
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

resource "google_iam_workload_identity_pool_provider" "example" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "gha-gchaperon"
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

output "workload_identity_provider_id" {
  value = google_iam_workload_identity_pool_provider.example.id
}

