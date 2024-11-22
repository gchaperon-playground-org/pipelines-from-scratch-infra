terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.12.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.3"
    }
  }
}

provider "google" {
  project = local.project
  region  = "us-central1"
  zone    = "us-central1-c"
  default_labels = {
    product = local.product
    team    = "gchaperon"
  }
}