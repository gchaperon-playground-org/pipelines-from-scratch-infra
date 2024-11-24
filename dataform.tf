resource "google_project_service" "secrets_api" {
  for_each = toset([
    "secretmanager.googleapis.com"
  ])
  service = each.key
}

resource "google_dataform_repository" "default" {
  provider = google-beta
  name     = local.product

  git_remote_settings {
    url = "git@github.com:gchaperon-playground-org/pipelines-from-scratch-dataform.git"
    # NOTE: when using mutiple workspaces, default_branch could be set as
    # {"dev": "develop", "prod": "master"}[workspace]
    default_branch = "master"

    ssh_authentication_config {
      user_private_key_secret_version = google_secret_manager_secret_version.ssh_private_key.id
      host_public_key                 = "ssh-ed25519 ${local.github_host_ed25519_public_key}"
    }
  }

  workspace_compilation_overrides {
    schema_suffix = "feature"
    # NOTE: ref for $$
    # https://developer.hashicorp.com/terraform/language/expressions/strings#escape-sequences
    table_prefix = "$${workspaceName}"
  }

  service_account = google_service_account.product.email
}

resource "google_secret_manager_secret" "ssh_private_key" {
  secret_id = "dataform-ssh-private-key"

  replication {
    auto {}
  }

  depends_on = [google_project_service.secrets_api]
}

resource "google_project_service_identity" "dataform_sa" {
  provider = google-beta

  service = "dataform.googleapis.com"
}

resource "google_secret_manager_secret_iam_member" "secret_accessor" {
  secret_id = google_secret_manager_secret.ssh_private_key.id
  role      = "roles/secretmanager.secretAccessor"
  member    = google_project_service_identity.dataform_sa.member
}

resource "google_secret_manager_secret_version" "ssh_private_key" {
  secret      = google_secret_manager_secret.ssh_private_key.id
  secret_data = tls_private_key.ssh_key_pair.private_key_openssh
}

resource "tls_private_key" "ssh_key_pair" {
  algorithm = "ED25519"

  provisioner "local-exec" {
    command = templatefile("provision_deploy_key.tftpl", {
      repo_owner = local.github_repo_owner
      repo_name  = local.github_repo_name
      public_key = self.public_key_openssh
    })
  }
}

locals {
  github_host_ed25519_public_key = "AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl"
  github_repo_name               = "pipelines-from-scratch-dataform"
  github_repo_owner              = "gchaperon-playground-org"
}