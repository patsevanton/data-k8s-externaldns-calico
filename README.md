# Подключение к сервисам в другом k8s кластере Yandex Cloud используя ExternalDNS

**ExternalDNS** — это специализированное приложение (часто работающее в виде пода в Kubernetes), которое автоматически управляет записями DNS в облачных провайдерах (таких как AWS Route53, Google Cloud DNS, Azure DNS и других) на основе наблюдаемых ресурсов в кластере Kubernetes (например, Services или Ingress), синхронизируя внешние DNS-имена с динамически изменяющимися IP-адресами сервисов, чтобы обеспечить стабильную и удобную маршрутизацию трафика к вашим приложениям извне кластера.

Какие проблемы решаем:
 - managed сервисы дорогие, использование statefull сервисов позволяет снизить затраты
 - использование statefull сервисов в том же kubernetes кластере привязывает к версиям операторов что снижает менёрв для обновлений statefull сервисов и операторов

В этом после будем рассматривать подключение к statefull сервисам в другом kubernetes как замена managed сервисов.

Обычно используют statefull сервисы как указал на схеме:
![обращение приложений в stateful сервисы](обращение_приложений_в_stateful_сервисы.png)

## Установка kubernetes
В директории terraform
```bash
terraform apply -auto-approve
yc managed-kubernetes cluster get-credentials --id id-кластера-k8s --external --force
```

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

---

## Часть 2: Установка Redis оператора и standalone Redis

Был выбран **ot-container-kit/redis-operator**, потому что он предоставляет более широкие возможности по сравнению с **spotahome/redis-operator**: поддерживает все режимы Redis (Standalone, Cluster и Sentinel), а также современные функции, необходимые для безопасной и управляемой эксплуатации — TLS/SSL, ACL, резервное копирование и интеграцию с Grafana для мониторинга. Это делает его более гибким и удобным решением для production-сред, требующих масштабируемости, безопасности и наблюдаемости.


### 1. Установка Redis оператора через Helm (рекомендуемый способ)

#### Добавление репозитория Helm
```bash
helm repo add ot-helm https://ot-container-kit.github.io/helm-charts/
```

#### Установка Redis оператора
```bash
helm upgrade redis-operator ot-helm/redis-operator --install --create-namespace --namespace ot-operators --wait --version 0.22.2
```

#### Проверка установки оператора
```bash
# Проверить установленные CRDs
kubectl get crds | grep redis.opstreelabs.in

# Проверить поды Redis оператора
kubectl get pods -n ot-operators | grep redis
```

---

### 2. Установка standalone Redis через YAML-манифест

#### Применение манифеста

```bash
kubectl apply -f redis-standalone/redis-standalone.yaml
```

#### Проверка подов Redis

```bash
kubectl get pods -n default
```

Ожидаемый результат:

```
NAME                READY   STATUS    RESTARTS   AGE
redis-standalone-0  1/1     Running   0          <время>
```

#### Проверка сервисов Redis

```bash
kubectl get svc -n default
```

Ожидаемый результат:

```
NAME                          TYPE        CLUSTER-IP      PORT(S)
redis-standalone              ClusterIP   10.96.x.x       6379/TCP
redis-standalone-additional   ClusterIP   10.96.x.x       6379/TCP
redis-standalone-headless     ClusterIP   None            6379/TCP
```

---

### 3. Тестирование Redis standalone

#### Подключение к Redis и запись 10 ключей

```bash
kubectl run redis-client --rm -it --restart=Never --image=redis:alpine -- /bin/sh -c "
redis-cli -h redis-standalone -p 6379 SET key1 'value1' &&
redis-cli -h redis-standalone -p 6379 SET key2 'value2' &&
redis-cli -h redis-standalone -p 6379 SET key3 'value3' &&
redis-cli -h redis-standalone -p 6379 SET key4 'value4' &&
redis-cli -h redis-standalone -p 6379 SET key5 'value5' &&
redis-cli -h redis-standalone -p 6379 SET key6 'value6' &&
redis-cli -h redis-standalone -p 6379 SET key7 'value7' &&
redis-cli -h redis-standalone -p 6379 SET key8 'value8' &&
redis-cli -h redis-standalone -p 6379 SET key9 'value9' &&
redis-cli -h redis-standalone -p 6379 SET key10 'value10'
"
```

#### Проверка наличия ключей

```bash
kubectl exec -it redis-standalone-0 -- redis-cli KEYS "*"
```

#### Проверка количества ключей

```bash
kubectl exec -it redis-standalone-0 -- redis-cli DBSIZE
```

#### Безопасный перебор ключей

```bash
kubectl exec -it redis-standalone-0 -- redis-cli SCAN 0 COUNT 1000
```

---

### 4. (Необязательно) Проверка через `redis-standalone-additional` сервис

Если нужно протестировать доступ через дополнительный сервис:

```bash
kubectl run redis-client --rm -it --restart=Never --image=redis:alpine -- /bin/sh -c "
redis-cli -h redis-standalone-additional -p 6379 PING
"
```

Ожидаемый ответ:

```
PONG
```

