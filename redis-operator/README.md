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

# Проверить поды Redis оператора
```bash
kubectl get pods -n ot-operators | grep redis
```

