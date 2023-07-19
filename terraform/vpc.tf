# Cria a VPC #
# Source: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network
resource "google_compute_network" "vpc" {
  name                    = var.vpc
  ### Deixamos como false para nao criar nada mais que apenas a vpc main-monks.
  auto_create_subnetworks = false
}

# Criar Subnet #
# Source: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork
resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet
  region        = var.region ## Regiao onde sera subnet.
  network       = google_compute_network.vpc.name
  ip_cidr_range = "10.10.0.0/16"
}

# Cria Cluster GKE quantidades de nodes e VPC/Subnet
# Source: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster
resource "google_container_cluster" "primary" {
  name                     = var.name # Nome Cluster com variavel.
  location                 = var.location # Local onde sera o cluster.
  network                  = google_compute_network.vpc.name
  subnetwork               = google_compute_subnetwork.subnet.name

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true # create the smallest possible default node pool and immediately delete it.
  initial_node_count       = 1
  # networking_mode          = "VPC_NATIVE" 
  
  private_cluster_config {
    enable_private_endpoint = true
    enable_private_nodes   = true 
    master_ipv4_cidr_block = "10.13.0.0/28"
  }
  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "10.11.0.0/21"
    services_ipv4_cidr_block = "10.12.0.0/21"
  }
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "10.10.0.7/32" ## Acessar via uma ponte que iremos criar na GCP.
      display_name = "net1"
    }

  }
}

## Subir maquina com ip estatico.
# Source: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_address.html
resource "google_compute_address" "ip_addr_internal" {
  project      = var.project
  address_type = "INTERNAL"
  region       = var.region
  subnetwork   = google_compute_subnetwork.subnet.name
  name         = var.iap-desktop
  address      = "10.10.0.7"
  description  = "IP Definido ponte." # Ip para atrelar a maquina de ponte, olhar na main.tf linha 52
}

# Criar nat/vpc/subnet/firewall.
# Source: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_nat

## Regra de firewall para acessar maquina via ssh.
resource "google_compute_firewall" "rules" {
  project = var.project
  name    = "ssh-maquina"
  network = google_compute_network.vpc.name 

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = var.whitelist-ips
}

# Criar rota para nat gateway
# Source: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_nat
resource "google_compute_router" "router" {
  project = var.project
  name    = "nat-router"
  network = google_compute_network.vpc.name
  region  = var.region
}

## Cria Nat Gateway
# Source: https://registry.terraform.io/modules/terraform-google-modules/cloud-nat/google/1.4.0?utm_content=documentLink&utm_medium=Visual+Studio+Code&utm_source=terraform-ls
module "cloud-nat" {
  source     = "terraform-google-modules/cloud-nat/google"
  version    = "~> 1.2"
  project_id = var.project
  region     = var.region
  router     = google_compute_router.router.name
  name       = "nat-config"

}