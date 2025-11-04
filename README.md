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
helm upgrade redis-operator ot-helm/redis-operator \
  --install --create-namespace --namespace ot-operators --wait --version 0.22.2
```

#### Проверка установки оператора
```bash
# Проверить установленные CRDs
kubectl get crds | grep redis.opstreelabs.in

# Проверить поды Redis оператора
kubectl get pods -n ot-operators | grep redis
```

### 2. Установка standalone Redis через YAML манифест

#### Применение манифеста
```bash
kubectl apply -f redis-standalone/redis-standalone.yaml
```

#### Проверка подов Redis
```bash
kubectl get pods -n redis-cluster
```

### 3. Тестирование Redis кластера

#### Запись 10 ключей
```bash
kubectl run redis-client --rm -it --restart=Never --image=redis:alpine -- /bin/sh -c "
redis-cli -c -h redis-cluster-leader.redis-cluster -p 6379 SET key1 'value1' &&
redis-cli -c -h redis-cluster-leader.redis-cluster -p 6379 SET key2 'value2' &&
redis-cli -c -h redis-cluster-leader.redis-cluster -p 6379 SET key3 'value3' &&
redis-cli -c -h redis-cluster-leader.redis-cluster -p 6379 SET key4 'value4' &&
redis-cli -c -h redis-cluster-leader.redis-cluster -p 6379 SET key5 'value5' &&
redis-cli -c -h redis-cluster-leader.redis-cluster -p 6379 SET key6 'value6' &&
redis-cli -c -h redis-cluster-leader.redis-cluster -p 6379 SET key7 'value7' &&
redis-cli -c -h redis-cluster-leader.redis-cluster -p 6379 SET key8 'value8' &&
redis-cli -c -h redis-cluster-leader.redis-cluster -p 6379 SET key9 'value9' &&
redis-cli -c -h redis-cluster-leader.redis-cluster -p 6379 SET key10 'value10'
"
```

#### Проверка распределения ключей

##### Сколько ключей у лидеров
```bash
kubectl exec -it redis-cluster-leader-0 -n redis-cluster -- redis-cli -c KEYS "*"
kubectl exec -it redis-cluster-leader-1 -n redis-cluster -- redis-cli -c KEYS "*"
kubectl exec -it redis-cluster-leader-2 -n redis-cluster -- redis-cli -c KEYS "*"
```

##### Сколько ключей у фолловеров
```bash
kubectl exec -it redis-cluster-follower-0 -n redis-cluster -- redis-cli -c KEYS "*"
kubectl exec -it redis-cluster-follower-1 -n redis-cluster -- redis-cli -c KEYS "*"
kubectl exec -it redis-cluster-follower-2 -n redis-cluster -- redis-cli -c KEYS "*"
```

#### Анализ распределения данных в кластере

##### Посмотреть распределение слотов в кластере
```bash
kubectl run -i --rm --tty redis-client --image=redis --restart=Never --namespace redis-cluster -- redis-cli -h redis-cluster-leader.redis-cluster.svc.cluster.local -p 6379 CLUSTER SLOTS
```

##### Получить информацию о кластере
```bash
kubectl run -i --rm --tty redis-client --image=redis --restart=Never --namespace redis-cluster -- redis-cli -h redis-cluster-leader.redis-cluster.svc.cluster.local -p 6379 CLUSTER NODES
```

##### Подсчитать количество ключей на каждом узле
```bash
kubectl exec -it -n redis-cluster redis-cluster-leader-0 -- redis-cli -c DBSIZE
kubectl exec -it -n redis-cluster redis-cluster-leader-1 -- redis-cli -c DBSIZE
kubectl exec -it -n redis-cluster redis-cluster-leader-2 -- redis-cli -c DBSIZE
```

##### Использование SCAN для безопасного перебора ключей
```bash
kubectl exec -it -n redis-cluster redis-cluster-leader-0 -- redis-cli -c SCAN 0 COUNT 1000
kubectl exec -it -n redis-cluster redis-cluster-leader-1 -- redis-cli -c SCAN 0 COUNT 1000
kubectl exec -it -n redis-cluster redis-cluster-leader-2 -- redis-cli -c SCAN 0 COUNT 1000
```

---

Эта объединенная инструкция содержит все необходимые шаги для установки и настройки как ExternalDNS для работы с Yandex Cloud, так и Redis оператора с тестированием Redis кластера в Kubernetes.
