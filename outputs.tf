output "get_credentials_command" {
  description = "Command to get kubeconfig for the cluster"
  value       = "yc managed-kubernetes cluster get-credentials --id ${yandex_kubernetes_cluster.zonal_k8s_cluster.id} --external"
}
