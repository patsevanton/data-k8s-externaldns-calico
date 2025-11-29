**ExternalDNS** — это специализированное приложение (часто работающее в виде пода в Kubernetes), которое автоматически управляет записями DNS в облачных провайдерах (таких как AWS Route53, Google Cloud DNS, Azure DNS и других) на основе наблюдаемых ресурсов в кластере Kubernetes (например, Services или Ingress), синхронизируя внешние DNS-имена с динамически изменяющимися IP-адресами сервисов, чтобы обеспечить стабильную и удобную маршрутизацию трафика к вашим приложениям извне кластера.

## Часть 1: Установка ExternalDNS для Yandex Cloud

### Добавление Helm репозитория ExternalDNS
```bash
helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/
```

### Создание service account key
В директории terraform выполняем:
```bash
terraform output -raw dns_manager_service_account_key | python3 -m json.tool | grep -v description | grep -v encrypted_private_key | grep -v format | grep -v key_fingerprint | grep -v pgp_key > key.json
```

### Создание Kubernetes secret
```bash
kubectl create secret generic yandexconfig --from-file=key.json
```

### Получение folder_id
```bash
folder_id=$(terraform output -raw folder_id)
```

### Установка ExternalDNS
В корне репозитория выполняем:
```bash
helm upgrade --install external-dns external-dns/external-dns -f externaldns/values.yaml --wait --version 1.19.0 --set provider.webhook.args="{--folder-id=$folder_id,--auth-key-file=/etc/kubernetes/key.json}"
```

## 2. Установка standalone Redis через YAML-манифест

```bash
cat <<EOF > redis-standalone/redis-standalone.yaml
---
apiVersion: v1
kind: Namespace
metadata:
  name: redis-standalone-ns
---
apiVersion: redis.redis.opstreelabs.in/v1beta2
kind: Redis
metadata:
  name: redis-standalone
  namespace: redis-standalone-ns
  annotations:
    external-dns.alpha.kubernetes.io/internal-hostname: redis-standalone.data.k8s.mycompany.corp
    external-dns.alpha.kubernetes.io/ttl: "60"
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
