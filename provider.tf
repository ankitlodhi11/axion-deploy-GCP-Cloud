terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }

  backend "gcs" {
    bucket = "tfstate-axion-a1c51fe0" # Yahan unique bucket name dalein
    prefix = "terraform/state"
  }
}

provider "google" {
  project = "project-a1c51fe0-43ef-44f5-a46"
  region  = "us-central1"
}