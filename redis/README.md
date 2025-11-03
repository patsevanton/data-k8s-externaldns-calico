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

# Тестирование подключения
kubectl run -it --rm redis-cli --image=redis --restart=Never -- \
  redis-cli -h redis-standalone -p 6379 ping
```

