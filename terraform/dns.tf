# Создание внешнего IP-адреса в Yandex Cloud
resource "yandex_vpc_address" "addr" {
  name = "cilium-redis"  # Имя ресурса внешнего IP-адреса

  external_ipv4_address {
    zone_id = yandex_vpc_subnet.k8s-subnet.zone  # Зона доступности, где будет выделен IP-адрес
  }
}

resource "yandex_dns_zone" "data_k8s_zone" {
  name             = "data-k8s-zone"
  zone             = "data.k8s.mycompany.corp."
  public           = false
  private_networks = [yandex_vpc_network.k8s-network.id]
}

output "dns_zone_id" {
  value = yandex_dns_zone.data_k8s_zone.id
}
