# 1. Custom VPC Network
resource "google_compute_network" "vpc" {
  name                    = "vpc-gke-axion-03"
  auto_create_subnetworks = false
}

# 2. Subnet with Secondary IP Ranges
resource "google_compute_subnetwork" "subnet" {
  name          = "snet-gke-axion-03"
  ip_cidr_range = "10.10.1.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id

  secondary_ip_range {
    range_name    = "k8s-pod-range"
    ip_cidr_range = "10.20.0.0/16"
  }

  secondary_ip_range {
    range_name    = "k8s-service-range"
    ip_cidr_range = "10.30.0.0/20"
  }
}

# 3. Artifact Registry Docker Repository
resource "google_artifact_registry_repository" "acr" {
  location      = var.region
  repository_id = "axionsystemar99"
  description   = "Docker container repository for Axion project"
  format        = "DOCKER"
}

# 4. Service Account for GKE Nodes
resource "google_service_account" "gke_nodes_sa" {
  account_id   = "gke-axion-nodes-sa"
  display_name = "GKE Nodes Service Account"
}

# 5. IAM Permissions
resource "google_artifact_registry_repository_iam_member" "aks_acr_pull" {
  project    = var.project_id
  location   = google_artifact_registry_repository.acr.location
  repository = google_artifact_registry_repository.acr.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.gke_nodes_sa.email}"
}

resource "google_project_iam_member" "gke_node_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes_sa.email}"
}

resource "google_project_iam_member" "gke_node_monitoring" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes_sa.email}"
}

# 6. GKE Cluster
resource "google_container_cluster" "aks" {
  name     = "gke-axion-03"
  location = var.zone

  network    = google_compute_network.vpc.self_link
  subnetwork = google_compute_subnetwork.subnet.self_link

  remove_default_node_pool = true
  initial_node_count       = 1

  ip_allocation_policy {
    cluster_secondary_range_name  = "k8s-pod-range"
    services_secondary_range_name = "k8s-service-range"
  }

  resource_labels = {
    environment = "dev"
    project     = "gke-axion"
  }
}

# 7. System Node Pool
resource "google_container_node_pool" "system_pool" {
  name       = "system"
  cluster    = google_container_cluster.aks.id
  node_count = 1

  node_config {
    machine_type = "e2-medium"
    image_type   = "COS_CONTAINERD"
    disk_size_gb = 30
    disk_type    = "pd-standard"

    service_account = google_service_account.gke_nodes_sa.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]

    labels = {
      "node-role"   = "system"
      "environment" = "dev"
      "project"     = "gke-axion"
    }
  }
}

# 8. User Node Pool (ARM64 Node Pool)
resource "google_container_node_pool" "userpool" {
  name       = "user"
  cluster    = google_container_cluster.aks.id
  node_count = 1

  node_config {
    machine_type = "t2a-standard-1"
    image_type   = "COS_CONTAINERD"
    disk_size_gb = 30
    disk_type    = "pd-standard"

    service_account = google_service_account.gke_nodes_sa.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]

    labels = {
      "node-role"   = "user"
      "arch"        = "arm64"
      "environment" = "dev"
      "project"     = "gke-axion"
    }
  }
}