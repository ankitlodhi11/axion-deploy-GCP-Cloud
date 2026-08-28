variable "project_id" {
  description = "Google Cloud Project ID"
  type        = string
  default     = "project-a1c51fe0-43ef-44f5-a46"
}

variable "region" {
  description = "GCP Region for Axion C4A instances"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "us-central1-a"
}