variable "project" {
# Usado apenas para rodar na mão
#  description = "ID do Projeto"
#  type        = string
#  default     = "project-monks"
}

variable "name" {
  description = "Cluster GKE Private para monks"
  type        = string
  default     = "gke-monks"
}

variable "region" {
#  Usado apenas para rodar na mão
#  description = "Regiao que ira criar"
#  type        = string
#  default     = "us-central1"
}

variable "location" {
  description = "Zona Cluster"
  type        = string
  default     = "us-central1-a"
}

variable "vpc" {
  description = "Nome VPC"
  type        = string
  default     = "main-monks"
}

variable "subnet" {
  description = "Nome Subnet"
  type        = string
  default     = "subnet1"
}

variable "nodecount" {
  description = "Quantidade de nodes"
  type        = number
  default     = 2
}

variable "nodetype" {
  description = "Shape do nodes"
  type        = string
  default     = "e2-medium"
}

variable "iap-desktop" {
  description = "Nome da maquina."
  type        = string
  default     = "maquina-interna"
}

variable "iap-desktop-shape" {
  description = "Shape"
  type        = string
  default     = "e2-small"
}

variable "iap-desktop-so" {
  description = "SO maquina."
  type        = string
  default     = "debian-cloud/debian-11"
}

variable "whitelist-ips" {
  description = "Whistelist ips"
  type        = list(string)
  default     = ["35.235.240.0/20"]
  # OBS o range de ip acima é da google para utilizar IPA conexão.
}

variable "container_image" {
#  Usado apenas para rodar na mão
#  description = "Imagem docker"
#  type        = string
#  default     = "gean22/appimage:latest" # Teste
}

variable "bucket_gcp" {
#  Usado apenas para rodar na mão
#  description = "Bucket"
#  type        = string
#  default     = "monks-gk"
}