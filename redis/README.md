# Установка Redis оператора и standalone Redis

## 1. Установка Redis оператора через Helm (рекомендуемый способ)

### Добавление репозитория Helm
```bash
helm repo add ot-helm https://ot-container-kit.github.io/helm-charts/
```

### Установка Redis оператора
```bash
helm upgrade redis-operator ot-helm/redis-operator \
  --install --create-namespace --namespace ot-operators --wait --version 0.22.2
```

### Проверка установки оператора
```bash
# Проверить установленные CRDs
kubectl get crds | grep redis.opstreelabs.in
```

## 2. Установка standalone Redis через YAML манифест

### Использование готового манифеста
В текущей директории доступен готовый файл [`redis-standalone.yaml`](redis-standalone.yaml:1):

### Применение манифеста
```bash
kubectl apply -f redis-cluster.yaml
```

### Проверка работы Redis
```bash
# Проверить статус Redis
kubectl get redis -n ot-operators

# Проверить поды Redis
kubectl get pods -n ot-operators | grep redis

# Проверить сервисы
kubectl get svc -n ot-operators | grep redis

# Записываю 10 ключей
kubectl exec -it redis-client -- redis-cli -h redis-cluster-leader -p 6379 SET key1 "value1"
kubectl exec -it redis-client -- redis-cli -h redis-cluster-leader -p 6379 SET key2 "value2"
kubectl exec -it redis-client -- redis-cli -h redis-cluster-leader -p 6379 SET key3 "value3"
kubectl exec -it redis-client -- redis-cli -h redis-cluster-leader -p 6379 SET key4 "value4"
kubectl exec -it redis-client -- redis-cli -h redis-cluster-leader -p 6379 SET key5 "value5"
kubectl exec -it redis-client -- redis-cli -h redis-cluster-leader -p 6379 SET key6 "value6"
kubectl exec -it redis-client -- redis-cli -h redis-cluster-leader -p 6379 SET key7 "value7"
kubectl exec -it redis-client -- redis-cli -h redis-cluster-leader -p 6379 SET key8 "value8"
kubectl exec -it redis-client -- redis-cli -h redis-cluster-leader -p 6379 SET key9 "value9"
kubectl exec -it redis-client -- redis-cli -h redis-cluster-leader -p 6379 SET key10 "value10"
```

