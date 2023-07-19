# Exemplos de usar modulos no terraform.
# Source: https://developer.hashicorp.com/terraform/language/modules/develop/structure

# Nginx ingress controller
# Modulo para ingress
module "ingress-nginx" {
  source = "./modules/ingress-nginx/"

  depends_on = [ 
    google_container_node_pool.primary_nodes
   ]
}

# App com hostname (Dominio)
# Aqui teremos um Dns publico 'ingress-loadbalancer-ip' para um gke cluster.
module "test_app" {
  source   = "./modules/app/"
  hostname = "monks.tigkf.tech"
  image = var.container_image
  
  depends_on = [
    module.ingress-nginx
  ]
}
