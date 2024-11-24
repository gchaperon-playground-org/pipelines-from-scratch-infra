resource "google_project_service" "secrets_api" {
  for_each = toset([
    "secretmanager.googleapis.com"
  ])
  service = each.key
}

# Dataform repository
resource "google_dataform_repository" "default" {
  provider = google-beta

  name = local.product

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

# Dataform release config
resource "null_resource" "release_config_args" {
  # NOTE: Modification of this resource forces recreation of the resources that
  # declare it in their lifecycle.replace_triggered_by property
  triggers = {
    repository    = google_dataform_repository.default.name
    name          = "daily-release"
    git_commitish = "master"
    cron_schedule = "*/2 * * * *"
    time_zone     = "America/Santiago"
  }
}

resource "google_dataform_repository_release_config" "daily" {
  provider = google-beta

  repository = null_resource.release_config_args.triggers.repository

  name          = null_resource.release_config_args.triggers.name
  git_commitish = null_resource.release_config_args.triggers.git_commitish
  cron_schedule = null_resource.release_config_args.triggers.cron_schedule
  time_zone     = null_resource.release_config_args.triggers.time_zone

  lifecycle {
    replace_triggered_by = [null_resource.release_config_args]
  }
}

# Dataform workflow config
resource "google_dataform_repository_workflow_config" "daily" {
  provider = google-beta

  name           = "daily-workflow"
  release_config = google_dataform_repository_release_config.daily.id

  invocation_config {
    service_account = google_service_account.product.email
  }

  cron_schedule = "0 7 * * *"
  time_zone     = "America/Santiago"
  repository    = google_dataform_repository.default.name
}



# Dataform private ssh key to connect to Github
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

# Permissions for the dataform service agent
resource "google_secret_manager_secret_iam_member" "secret_accessor" {
  secret_id = google_secret_manager_secret.ssh_private_key.id
  role      = "roles/secretmanager.secretAccessor"
  member    = google_project_service_identity.dataform_sa.member
}

resource "google_service_account_iam_member" "token_creator" {
  service_account_id = google_service_account.product.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = google_project_service_identity.dataform_sa.member
}

locals {
  # Github host public key. What is tipically stored in .ssh/known_hosts
  github_host_ed25519_public_key = "AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl"
  github_repo_name               = "pipelines-from-scratch-dataform"
  github_repo_owner              = "gchaperon-playground-org"
}

