terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.12.0"
    }
  }
}

provider "google" {
  project = local.project
  region  = "us-central1"
  zone    = "us-central1-c"
  default_labels = {
    product = "pipelines-from-scratch"
    team    = "gchaperon"
  }
}