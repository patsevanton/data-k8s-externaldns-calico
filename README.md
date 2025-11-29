# Маршрутизация трафика к нескольким Redis в другом k8s через один LB используя TLSRoute

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
kubectl apply -f redis-standalone/redis-standalone.yaml
```

### Проверка подов Redis

```bash
kubectl get pods -n redis-standalone-ns
```

**Ожидаемый результат:**

```
NAME                 READY   STATUS    RESTARTS   AGE
redis-standalone-0   1/1     Running   0          4m23s
```

### Проверка сервисов Redis

```bash
kubectl get svc -n redis-standalone-ns
```

**Ожидаемый результат:**

```
NAME                          TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
redis-standalone              ClusterIP   10.96.155.226   <none>        6379/TCP   4m27s
redis-standalone-additional   ClusterIP   10.96.153.7     <none>        6379/TCP   4m27s
redis-standalone-headless     ClusterIP   None            <none>        6379/TCP   4m27s
```

## 3. Тестирование внешнего Redis standalone из cilium k8s кластера

### Подключение к Redis и запись 10 ключей

```bash
kubectl run redis-client --rm -it --restart=Never --image=redis:alpine -- /bin/sh -c "
redis-cli -h redis-standalone.data.k8s.mycompany.corp -p 6379 SET key1 'value1' &&
redis-cli -h redis-standalone.data.k8s.mycompany.corp -p 6379 SET key2 'value2' &&
redis-cli -h redis-standalone.data.k8s.mycompany.corp -p 6379 SET key3 'value3' &&
redis-cli -h redis-standalone.data.k8s.mycompany.corp -p 6379 SET key4 'value4' &&
redis-cli -h redis-standalone.data.k8s.mycompany.corp -p 6379 SET key5 'value5' &&
redis-cli -h redis-standalone.data.k8s.mycompany.corp -p 6379 SET key6 'value6' &&
redis-cli -h redis-standalone.data.k8s.mycompany.corp -p 6379 SET key7 'value7' &&
redis-cli -h redis-standalone.data.k8s.mycompany.corp -p 6379 SET key8 'value8' &&
redis-cli -h redis-standalone.data.k8s.mycompany.corp -p 6379 SET key9 'value9' &&
redis-cli -h redis-standalone.data.k8s.mycompany.corp -p 6379 SET key10 'value10'
"
```

### Проверка наличия ключей

```bash
kubectl run redis-client --rm -it --restart=Never --image=redis:alpine -- /bin/sh -c "
redis-cli -h redis-standalone.data.k8s.mycompany.corp -p 6379 KEYS '*'
"
```

### Проверка количества ключей

```bash
kubectl run redis-client --rm -it --restart=Never --image=redis:alpine -- /bin/sh -c "
redis-cli -h redis-standalone.data.k8s.mycompany.corp -p 6379 DBSIZE
"
```

### Безопасный перебор ключей

```bash
kubectl run redis-client --rm -it --restart=Never --image=redis:alpine -- /bin/sh -c "
redis-cli -h redis-standalone.data.k8s.mycompany.corp -p 6379 SCAN 0 COUNT 1000
"
```

## 4. (Необязательно) Проверка доступности Redis

```bash
kubectl run redis-client --rm -it --restart=Never --image=redis:alpine -- /bin/sh -c "
redis-cli -h redis-standalone.data.k8s.mycompany.corp -p 6379 PING
"
```

**Ожидаемый ответ:**

```
PONG
```
