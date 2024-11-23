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
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.6"
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

provider "google-beta" {
  project = local.project
  region  = "us-central1"
  zone    = "us-central1-c"
  default_labels = {
    product = local.product
    team    = "gchaperon"
  }
}