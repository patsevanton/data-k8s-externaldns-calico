# Сравнение Redis операторов для Kubernetes

## Основные отличия

**spotahome/redis-operator**
- Только Redis + Sentinel
- Фокус на стабильность и production-готовность
- Проверен в production

**ot-container-kit/redis-operator**
- Поддержка всех режимов Redis (Standalone, Cluster, Sentinel)
- Современные функции: TLS/SSL, ACL, резервное копирование
- Расширенный мониторинг с Grafana

## Ключевые характеристики

| Функция | spotahome | ot-container-kit |
|---------|-----------|------------------|
| Архитектура | Redis + Sentinel | Все режимы Redis |
| TLS/SSL | ❌ | ✅ |
| ACL управление | ❌ | ✅ |
| Резервное копирование | ❌ | ✅ |
| Grafana дашборды | ❌ | ✅ |
