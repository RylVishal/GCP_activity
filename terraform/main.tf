resource "google_project_service" "container" {
  project = var.project_id
  service = "container.googleapis.com"
}

resource "google_project_service" "artifact_registry" {
  project = var.project_id
  service = "artifactregistry.googleapis.com"
}

resource "google_project_service" "cloudbuild" {
  project = var.project_id
  service = "cloudbuild.googleapis.com"
}

resource "google_project_service" "clouddeploy" {
  project = var.project_id
  service = "clouddeploy.googleapis.com"
}

resource "google_project_service" "compute" {
  project = var.project_id
  service = "compute.googleapis.com"
}

resource "google_compute_network" "pinger_vpc" {
  name                    = "pinger-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "pinger_subnet" {
  name          = "pinger-subnet"
  ip_cidr_range = "10.10.0.0/24"
  region        = var.region
  network       = google_compute_network.pinger_vpc.id

  secondary_ip_range {
    range_name    = "pinger-pods"
    ip_cidr_range = "10.20.0.0/16"
  }

  secondary_ip_range {
    range_name    = "pinger-services"
    ip_cidr_range = "10.30.0.0/20"
  }
}

resource "google_container_cluster" "pinger_cluster" {
  name     = "pinger-cluster"
  location = var.region

  network                  = google_compute_network.pinger_vpc.id
  subnetwork               = google_compute_subnetwork.pinger_subnet.id
  deletion_protection      = false
  remove_default_node_pool = true
  initial_node_count       = 1


  networking_mode = "VPC_NATIVE"

  ip_allocation_policy {
    cluster_secondary_range_name  = "pinger-pods"
    services_secondary_range_name = "pinger-services"
  }
}

resource "google_container_node_pool" "pinger_nodes" {
  name       = "pinger-node-pool"
  location   = var.region
  cluster    = google_container_cluster.pinger_cluster.name
  node_count = 1
  node_locations = [
    "asia-south1-a",
    "asia-south1-b"
  ]
  node_config {
    machine_type = "e2-standard-2"
    disk_type    = "pd-balanced"
    disk_size_gb = 30

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}