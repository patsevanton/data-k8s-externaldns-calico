# Аннотации ExternalDNS

ExternalDNS использует аннотации Kubernetes для управления созданием и поведением DNS-записей для различных ресурсов, таких как `Service` и `Ingress`. Эти аннотации позволяют пользователям указывать желаемые имена хостов, TTL и другие специфичные для провайдера параметры.

## Основные аннотации ExternalDNS

ExternalDNS использует префикс `external-dns.alpha.kubernetes.io/` для всех своих аннотаций. Ниже приведены некоторые из наиболее часто используемых аннотаций и их назначение:

### `external-dns.alpha.kubernetes.io/hostname`

Эта аннотация используется для указания желаемого имени хоста (или нескольких имен хостов через запятую) для DNS-записей ресурса. Она переопределяет любые автоматически сгенерированные имена хостов.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
  annotations:
    external-dns.alpha.kubernetes.io/hostname: app.example.com
spec:
  type: LoadBalancer
  ...
```

### `external-dns.alpha.kubernetes.io/ttl`

Позволяет настроить значение TTL (Time-To-Live) для DNS-записей. Значение может быть указано как целое число секунд или как строка длительности, например, "60s" или "1m".

```yaml
apiVersion: v1
kind: Service
metadata:
  annotations:
    external-dns.alpha.kubernetes.io/hostname: nginx.external-dns-test.my-org.com.
    external-dns.alpha.kubernetes.io/ttl: "60"
  ...
```

### `external-dns.alpha.kubernetes.io/target`

Переопределяет целевой IP-адрес или имя хоста для DNS-записи. Если цель является IP-адресом, создается запись A или AAAA; в противном случае создается запись CNAME.

### `external-dns.alpha.kubernetes.io/internal-hostname`

Используется для создания DNS-записей, предназначенных для использования во внутренних сетях, например, для `ClusterIP` сервисов.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-svc
  annotations:
    service.beta.kubernetes.io/azure-load-balancer-internal: "true"
    external-dns.alpha.kubernetes.io/hostname: server.example.com
    external-dns.alpha.kubernetes.io/internal-hostname: server-clusterip.example.com
spec:
  ports:
    - port: 80
      protocol: TCP
      targetPort: 80
  selector:
    app: nginx
  type: LoadBalancer
```

### `external-dns.alpha.kubernetes.io/access`

Указывает, какой набор IP-адресов узлов использовать для `Service` типа `NodePort` (например, `public` или `private`).

### `external-dns.alpha.kubernetes.io/endpoints-type`

Определяет, какой тип адресов использовать для безголовых `Service`. Например, `HostIP` или `NodeExternalIP`.

### `external-dns.alpha.kubernetes.io/ingress-hostname-source`

Контролирует, откуда брать имена хостов для ресурса `Ingress` (только из спецификации, только из аннотаций или из обоих).

## Специфичные для провайдера аннотации

Некоторые провайдеры DNS имеют свои собственные аннотации, которые начинаются с префикса, специфичного для облака.

### AWS Route53

- `external-dns.alpha.kubernetes.io/aws-alias`: Если установлено значение `true`, указывает, что записи CNAME должны быть записями ALIAS.
- `external-dns.alpha.kubernetes.io/aws-set-identifier`: Указывает идентификатор набора для DNS-записей, что позволяет различать несколько наборов записей с одинаковым доменом и типом.
- `external-dns.alpha.kubernetes.io/aws-weight`: Используется для взвешенной маршрутизации в Route53.
- `external-dns.alpha.kubernetes.io/aws-region`: Для маршрутизации на основе задержки.
- `external-dns.alpha.kubernetes.io/aws-failover`: Для настройки отказоустойчивости.
- `external-dns.alpha.kubernetes.io/aws-geolocation-country-code`: Для гео-маршрутизации.
- `external-dns.alpha.kubernetes.io/aws-health-check-id`: Связывает DNS-записи с проверками работоспособности Route53.

### Cloudflare

- `external-dns.alpha.kubernetes.io/cloudflare-proxied`: Определяет, будет ли трафик проходить через прокси Cloudflare.

## Аннотации совместимости

ExternalDNS также поддерживает аннотации из других проектов для обеспечения совместимости:

- `zalando.org/dnsname`: Используется Zalando's Mate для указания имени хоста.
- `domainName`: Используется wearemolecule/route53-kubernetes.
- `dns.alpha.kubernetes.io/external` и `dns.alpha.kubernetes.io/internal`: Используются контроллером DNS Kops.

## Дополнительные аннотации

Аннотация `external-dns.alpha.kubernetes.io/controller` и `external-dns.alpha.kubernetes.io/alias` также существуют, но их использование менее распространено или специфично для определенных сценариев. Аннотация `external-dns.alpha.kubernetes.io/set-identifier` используется для продвинутых политик маршрутизации, таких как взвешенная маршрутизация.