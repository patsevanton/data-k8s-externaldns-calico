resource "yandex_iam_service_account" "sa-k8s-admin" {
  folder_id = local.folder_id
  name      = "sa-k8s-admin"
}

resource "yandex_resourcemanager_folder_iam_member" "sa-k8s-admin-permissions" {
  folder_id = local.folder_id
  role      = "admin"
  member    = "serviceAccount:${yandex_iam_service_account.sa-k8s-admin.id}"
}

resource "yandex_iam_service_account" "sa-dns-manager" {
  folder_id = local.folder_id
  name      = "sa-dns-manager"
}

resource "yandex_resourcemanager_folder_iam_member" "sa-dns-manager-permissions" {
  folder_id = local.folder_id
  role      = "dns.editor"
  member    = "serviceAccount:${yandex_iam_service_account.sa-dns-manager.id}"
}

resource "yandex_iam_service_account_key" "sa-dns-manager-key" {
  service_account_id = yandex_iam_service_account.sa-dns-manager.id
}
