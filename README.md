# Маршрутизация трафика к нескольким Redis в другом k8s через один LB используя TLSRoute

## Цель статьи
Показать, как осуществить маршрутизацию трафика к нескольким кластерам Redis, расположенным в другом Kubernetes-кластере, через один LoadBalancer. Решение предполагает терминацию TLS-соединений в `envoy-gateway` и проксирование незашифрованного TCP-трафика к Redis без TLS.

### Какие задачи решаем
- Managed-сервисы требуют существенных затрат, тогда как stateful-сервисы позволяют использовать собственные кластеры с контролем затрат.
- Размещение stateful-сервисов в том же кластере ограничивает возможности обновления операторов и самих сервисов, поэтому стоит вынести их в отдельный кластер.

Обычно stateful-сервисы коммуницируют с приложениями через внутренний балансировщик, как показано ниже:
![обращение приложений в stateful сервисы](обращение_приложений_в_stateful_сервисы.png)

## 1. Установка кластера Kubernetes
Переходим в директорию `terraform`, чтобы развернуть инфраструктуру и получить доступ к кластеру:

```bash
terraform apply -auto-approve
yc managed-kubernetes cluster get-credentials --id id-кластера-k8s --external --force
```

## 2. Развертывание Redis-оператора (рекомендуемый способ)
### Добавление репозитория Helm
```bash
helm repo add ot-helm https://ot-container-kit.github.io/helm-charts/
```

### Установка Redis-оператора
```bash
helm upgrade --install redis-operator ot-helm/redis-operator \
  --create-namespace --namespace ot-operators --wait --version 0.22.2
```

### Проверка установки
```bash
kubectl get pods -n ot-operators | grep redis
```

## 3. Развёртывание standalone-Redis через YAML-манифест
Создаём манифест с двумя экземплярами Redis:

```bash
cat <<EOF > redis-standalone.yaml
---
apiVersion: v1
kind: Namespace
metadata:
  name: redis-standalone
---
apiVersion: redis.redis.opstreelabs.in/v1beta2
kind: Redis
metadata:
  name: redis-standalone1
  namespace: redis-standalone
spec:
  podSecurityContext:
    runAsUser: 1000
    fsGroup: 1000
  kubernetesConfig:
    image: quay.io/opstree/redis:v7.0.12
  storage:
    volumeClaimTemplate:
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 1Gi
---
apiVersion: redis.redis.opstreelabs.in/v1beta2
kind: Redis
metadata:
  name: redis-standalone2
  namespace: redis-standalone
spec:
  podSecurityContext:
    runAsUser: 1000
    fsGroup: 1000
  kubernetesConfig:
    image: quay.io/opstree/redis:v7.0.12
  storage:
    volumeClaimTemplate:
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 1Gi
EOF
```

### Применение манифеста
```bash
kubectl apply -f redis-standalone.yaml
kubectl get pods -n redis-standalone
```

## 4. Установка envoy-gateway
Развёртывание проходит через Terraform, в котором задаётся IP для LoadBalancer. Фрагмент модуля:

```hcl
resource "helm_release" "envoy_gateway" {
  name             = "envoy-gateway"
  repository       = "oci://docker.io/envoyproxy"
  chart            = "gateway-helm"
  version          = "v1.6.0"
  namespace        = "envoy-gateway"
  create_namespace = true
  depends_on       = [yandex_kubernetes_node_group.k8s_node_group_cilium_redis]

  set = [
    {
      name  = "service.type"
      value = "LoadBalancer"
    },
    {
      name  = "service.loadBalancerIP"
      value = yandex_vpc_address.addr.external_ipv4_address[0].address
    }
  ]
}
```

### Получение стандартных значений чарта
```bash
helm show values oci://docker.io/envoyproxy/gateway-helm --version v1.6.0 > default-values.yaml
yq -i 'del(.. | select( length == 0))' default-values.yaml
sed -i '/{}/d' default-values.yaml
```

## 5. Установка Certificate Authority на базе HashiCorp Vault
Следуем инструкции https://habr.com/ru/articles/971494/. При установке cert-manager необходимо включить флаги GatewayAPI.

## 6. Установка cert-manager
```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade --install --wait cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.18.2 \
  --set crds.enabled=true \
  --set config.apiVersion="controller.config.cert-manager.io/v1alpha1" \
  --set config.kind="ControllerConfiguration" \
  --set config.enableGatewayAPI=true
```

## 7. Создание TLS-сертификатов для Redis
### redis1
```bash
cat <<EOF > redis1-certificate.yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: redis1-certificate
  namespace: redis-standalone
spec:
  secretName: redis1-tls-cert
  issuerRef:
    name: vault-cluster-issuer
    kind: ClusterIssuer
  duration: 720h
  renewBefore: 360h
  commonName: redis1.apatsev.corp
  dnsNames:
  - redis1.apatsev.corp
EOF

kubectl apply -f redis1-certificate.yaml
```

### redis2
```bash
cat <<EOF > redis2-certificate.yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: redis2-certificate
  namespace: redis-standalone
spec:
  secretName: redis2-tls-cert
  issuerRef:
    name: vault-cluster-issuer
    kind: ClusterIssuer
  duration: 720h
  renewBefore: 360h
  commonName: redis2.apatsev.corp
  dnsNames:
  - redis2.apatsev.corp
EOF

kubectl apply -f redis2-certificate.yaml
```

## 8. Настройка TLSRoute и Gateway
### GatewayClass
```bash
cat <<EOF > gatewayclass.yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: envoy
spec:
  controllerName: gateway.envoyproxy.io/gatewayclass-controller
EOF

kubectl apply -f gatewayclass.yaml
```

### Gateway
```bash
cat <<EOF > gateway.yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: redis-gateway
  namespace: envoy-gateway
spec:
  gatewayClassName: envoy
  listeners:
    - name: redis-cluster-1
      protocol: TLS
      port: 443
      hostname: "redis1.apatsev.corp"
      tls:
        mode: Terminate
        certificateRefs:
          - name: redis1-tls-cert
      allowedRoutes:
        namespaces:
          from: All
    - name: redis-cluster-2
      protocol: TLS
      port: 443
      hostname: "redis2.apatsev.corp"
      tls:
        mode: Terminate
        certificateRefs:
          - name: redis2-tls-cert
      allowedRoutes:
        namespaces:
          from: All
EOF

kubectl apply -f gateway.yaml
```

### TLSRoute
Каждому хосту соответствует собственный TLSRoute с секцией `sectionName` и `backendRef` на соответствующий Redis.

```yaml
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: TLSRoute
metadata:
  name: redis-cluster-1-route
  namespace: redis
  annotations:
    cert-manager.io/cluster-issuer: vault-cluster-issuer
spec:
  parentRefs:
    - name: redis-gateway
      namespace: envoy-gateway
      sectionName: redis-cluster-1
  hostnames:
    - "redis1.apatsev.corp"
  rules:
    - backendRefs:
        - name: redis-cluster-1
          port: 6379
---
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: TLSRoute
metadata:
  name: redis-cluster-2-route
  namespace: redis
  annotations:
    cert-manager.io/cluster-issuer: vault-cluster-issuer
spec:
  parentRefs:
    - name: redis-gateway
      namespace: envoy-gateway
      sectionName: redis-cluster-2
  hostnames:
    - "redis2.apatsev.corp"
  rules:
    - backendRefs:
        - name: redis-cluster-2
          port: 6379
```

## 9. Проверка доступности
Запускаем временный под и проверяем соединение с TLS-сервером:

```bash
kubectl run redis-client --rm -it --restart=Never --image=redis:alpine -- /bin/sh -c "
redis-cli -h redis1.apatsev.corp -p 6379 PING
"
```

