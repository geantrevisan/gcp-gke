terraform {
  required_providers {
    google = ">= 4.73.1"
    kubernetes = ">= 2.22.0"
  }
  backend "gcs" {
    bucket  = var.bucket_gcp
    prefix  = "master"
  }
  
}

##### Local da credencial para autenticar. #####
# Source: https://registry.terraform.io/providers/hashicorp/google/latest/docs
provider "google" {
  project = var.project
  region  = var.region
#  Rodar na mao.
#  credentials = file("cred.json")
}

# Provedor helm.
# Source: https://registry.terraform.io/providers/Twingate/twingate/latest/docs/guides/gke-helm-provider-deployment-guide
provider "helm" {
  kubernetes {
    token                  = data.google_client_config.current.access_token
    host                   = "https://${google_container_cluster.primary.endpoint}"
    cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
  }
}

# Provedor kubernetes.
# Source: https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/guides/using_gke_with_terraform
provider "kubernetes" {
  host                   = "https://${google_container_cluster.primary.endpoint}"
  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
  token                  = data.google_client_config.current.access_token
}
