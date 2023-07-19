data "google_client_config" "current" {
}

# Ativa
resource "google_project_service" "compute" {
  service = "compute.googleapis.com"
}

# Ativa
resource "google_project_service" "container" {
  service = "container.googleapis.com"
}
