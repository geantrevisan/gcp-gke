resource "helm_release" "app-chart" {
  name      = "app-chart"
  chart     = "./modules/app/helm"
  namespace = "default"

  set {
    name  = "hostname"
    value = var.hostname
  }

 # Devido problema de deploy desativei para entregar.   
#  set {
#    name  = "image"
#    value = var.image
#  }
  timeout = 60
}

variable "image" {
  type = string
}
variable "hostname" {
  type = string
}
