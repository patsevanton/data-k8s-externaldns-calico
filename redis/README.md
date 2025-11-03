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

# Проверить поды Redis
```bash
kubectl get pods -n ot-operators | grep redis
```

# Записываю 10 ключей
```bash
# Создаем скрипт и выполняем все команды за один раз
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


Сколько ключей у лидеров
```bash
kubectl exec -it redis-cluster-leader-0 -n redis-cluster -- redis-cli -c KEYS "*"
kubectl exec -it redis-cluster-leader-1 -n redis-cluster -- redis-cli -c KEYS "*"
kubectl exec -it redis-cluster-leader-2 -n redis-cluster -- redis-cli -c KEYS "*"
```

Сколько ключей у фолловеров
```bash
kubectl exec -it redis-cluster-follower-0 -n redis-cluster -- redis-cli -c KEYS "*"
kubectl exec -it redis-cluster-follower-1 -n redis-cluster -- redis-cli -c KEYS "*"
kubectl exec -it redis-cluster-follower-2 -n redis-cluster -- redis-cli -c KEYS "*"
```

Узнать распределение слотов
# Посмотреть распределение слотов в кластере
```bash
# Однострочная команда с автоматическим удалением pod после выполнения
kubectl run -i --rm --tty redis-client --image=redis --restart=Never --namespace redis-cluster -- redis-cli -h redis-cluster-leader.redis-cluster.svc.cluster.local -p 6379 CLUSTER SLOTS
```

# Или получить информацию о кластере
```bash
kubectl run -i --rm --tty redis-client --image=redis --restart=Never --namespace redis-cluster -- redis-cli -h redis-cluster-leader.redis-cluster.svc.cluster.local -p 6379 CLUSTER NODES
```

# Подсчитать количество ключей на каждом узле
```
kubectl exec -it -n redis-cluster redis-cluster-leader-0 -- redis-cli -c DBSIZE
kubectl exec -it -n redis-cluster redis-cluster-leader-1 -- redis-cli -c DBSIZE
kubectl exec -it -n redis-cluster redis-cluster-leader-2 -- redis-cli -c DBSIZE
```

# Или использовать SCAN для безопасного перебора
```
kubectl exec -it -n redis-cluster redis-cluster-leader-0 -- redis-cli -c SCAN 0 COUNT 1000
kubectl exec -it -n redis-cluster redis-cluster-leader-1 -- redis-cli -c SCAN 0 COUNT 1000
kubectl exec -it -n redis-cluster redis-cluster-leader-2 -- redis-cli -c SCAN 0 COUNT 1000
```