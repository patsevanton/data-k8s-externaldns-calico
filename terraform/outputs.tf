output "get_credentials_command_cilium_app" {
  description = "Command to get kubeconfig for the Cilium App cluster"
  value       = "yc managed-kubernetes cluster get-credentials --id ${yandex_kubernetes_cluster.cilium-app.id} --external --force"
}

output "get_credentials_command_cilium_redis" {
  description = "Command to get kubeconfig for the Cilium Redis cluster"
  value       = "yc managed-kubernetes cluster get-credentials --id ${yandex_kubernetes_cluster.cilium-redis.id} --external --force"
}

output "dns_manager_service_account_id" {
  description = "ID of the service account for DNS management"
  value       = yandex_iam_service_account.sa-dns-manager.id
}

output "dns_manager_service_account_key" {
  description = "Key of the service account for DNS management"
  value       = jsonencode(yandex_iam_service_account_key.sa-dns-manager-key)
  sensitive   = true
}

output "folder_id" {
  description = "ID of the folder where the resources will be created"
  value       = coalesce(var.folder_id, data.yandex_client_config.client.folder_id)
}
