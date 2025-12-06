# Создание внешнего IP-адреса в Yandex Cloud
resource "yandex_vpc_address" "addr_redis" {
  name = "redis"  # Имя ресурса внешнего IP-адреса

  external_ipv4_address {
    zone_id = yandex_vpc_subnet.k8s-subnet.zone  # Зона доступности, где будет выделен IP-адрес
  }
}

resource "yandex_dns_zone" "apatsev_corp_zone" {
  name   = "apatsev-corp"
  zone   = "apatsev.corp."
  public = false
  private_networks = [yandex_vpc_network.k8s-network.id]
}

resource "yandex_dns_recordset" "redis_apatsev_corp" {
  zone_id = yandex_dns_zone.apatsev_corp_zone.id
  name    = "redis.apatsev.corp."
  type    = "A"
  ttl     = 200
  data    = [yandex_vpc_address.addr_redis.external_ipv4_address[0].address]
}

output "dns_zone_id" {
  value = yandex_dns_zone.apatsev_corp_zone.id
}
