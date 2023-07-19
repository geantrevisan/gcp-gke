# Criar node pool.
# Source: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_node_pool.html
resource "google_container_node_pool" "primary_nodes" {
  name       = google_container_cluster.primary.name
  location   = var.location ## Local onde sera o node.
  cluster    = google_container_cluster.primary.name
  node_count = var.nodecount

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels = {
      env = "dev"
    }

    machine_type = var.nodetype
    preemptible  = true

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}

# Run script para fazer configurações no cluster caso necessario, pois utilizaremos o IPA para acessar um terminal.
# Source: https://fabianlee.org/2021/05/28/terraform-invoking-a-startup-script-for-a-gce-google_compute_instance/
data "template_file" "run_script" {
  metadata_startup_script = file("${path.module}/startup.sh")
  template = <<-EOF
  sudo apt-get update -y;
  sudo curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl";
  sudo mv kubectl /usr/bin/; sudo chmod 755 /usr/bin/kubectl; sudo chmod +x /usr/bin/kubectl;
  sudo apt-get install google-cloud-sdk-gke-gcloud-auth-plugin -y;
  sudo apt-get install git-all -y;
  EOF
}

# Criando instancia para acesso via IAP.
# Source: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance
resource "google_compute_instance" "default" {
  project      = var.project
  zone         = var.location
  name         = var.iap-desktop ## Variavel para setar nome da instancia 
  machine_type = var.iap-desktop-shape ## Variavel para definir o shape da maquina.

  // Inicia script ao iniciar a maquina.
  metadata_run_script = data.template_file.run_script.rendered

  boot_disk {
    initialize_params {
      image = var.iap-desktop-so
    }
  }
  network_interface {
    network    = google_compute_network.vpc.name
    subnetwork = google_compute_subnetwork.subnet.name
    network_ip = google_compute_address.ip_addr_internal.address # Endereço interno statico que irá atachar na instancia.
  }

}