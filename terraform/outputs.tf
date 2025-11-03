output "get_credentials_command_calico" {
  description = "Command to get kubeconfig for the Calico cluster"
  value       = "yc managed-kubernetes cluster get-credentials --id ${yandex_kubernetes_cluster.calico.id} --external --force"
}

output "get_credentials_command_cilium" {
  description = "Command to get kubeconfig for the Cilium cluster"
  value       = "yc managed-kubernetes cluster get-credentials --id ${yandex_kubernetes_cluster.cilium.id} --external --force"
}

output "dns_manager_service_account_id" {
  description = "ID of the service account for DNS management"
  value       = yandex_iam_service_account.sa-dns-manager.id
}
