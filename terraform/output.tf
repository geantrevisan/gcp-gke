#Output ao finalizar com ips.

output "kubernetes_cluster_host" {
  value       = google_container_cluster.primary.endpoint
  description = "Cluster Host GKE"
}

output "kubernetes_cluster_name" {
  value       = google_container_cluster.primary.name
  description = "Cluster GKE"
}