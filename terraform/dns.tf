resource "yandex_dns_zone" "data_k8s_zone" {
  name             = "data-k8s-zone"
  zone             = "data.k8s.mycompany.corp."
  public           = false
  private_networks = [yandex_vpc_network.k8s-network.id]
}

output "dns_zone_id" {
  value = yandex_dns_zone.data_k8s_zone.id
}
