# Сравнительная таблица Redis операторов Kubernetes

## Обзор

| Характеристика | spotahome/redis-operator | ot-container-kit/redis-operator |
|----------------|---------------------------|---------------------------------|
| **Основная архитектура** | Redis + Sentinel (автоматический failover) | Redis Standalone, Cluster, Sentinel |
| **Поддержка Kubernetes** | 1.21+ (рекомендуется 1.25+) | 1.16+ |
| **Поддержка Redis** | 6.0+ | 5.0+, 6.0+, 7.0+ |
| **Лицензия** | Apache 2.0 | Apache 2.0 |
| **Язык реализации** | Go | Go |
| **Последняя версия** | v1.3.0 | v0.15.0 |

## Функциональные возможности

### Основные функции

| Функция | spotahome/redis-operator | ot-container-kit/redis-operator |
|---------|---------------------------|---------------------------------|
| Redis Standalone | ❌ | ✅ |
| Redis Cluster | ❌ | ✅ |
| Redis Sentinel | ✅ | ✅ |
| Автоматический failover | ✅ | ✅ |
| Мониторинг здоровья | ✅ | ✅ |
| Автоматическое восстановление | ✅ | ✅ |
| Persistence (PVC) | ✅ | ✅ |
| Конфигурация через ConfigMap | ✅ | ✅ |
| TLS/SSL шифрование | ❌ | ✅ |
| ACL управление | ❌ | ✅ |
| Резервное копирование/восстановление | ❌ | ✅ |

### Мониторинг и метрики

| Мониторинг | spotahome/redis-operator | ot-container-kit/redis-operator |
|------------|---------------------------|---------------------------------|
| Prometheus метрики | ✅ (порт 9710) | ✅ |
| Grafana дашборды | ❌ | ✅ |
| Встроенный экспортер | ✅ (redis_exporter) | ✅ (redis_exporter) |
| ServiceMonitor | ✅ | ✅ |
| PodMonitor | ✅ | ✅ |

### Безопасность

| Безопасность | spotahome/redis-operator | ot-container-kit/redis-operator |
|--------------|---------------------------|---------------------------------|
| Аутентификация | ✅ (Redis AUTH) | ✅ |
| TLS шифрование | ❌ | ✅ |
| Network Policies | ✅ | ✅ |
| Pod Security Context | ✅ | ✅ |
| Security Context | ✅ | ✅ |
| RBAC интеграция | ✅ | ✅ |

### Управление ресурсами

| Ресурсы | spotahome/redis-operator | ot-container-kit/redis-operator |
|---------|---------------------------|---------------------------------|
| Resource limits | ✅ | ✅ |
| Resource requests | ✅ | ✅ |
| Affinity/Anti-affinity | ✅ | ✅ |
| Tolerations | ✅ | ✅ |
| Node selection | ✅ | ✅ |
| Priority classes | ✅ | ✅ |
| Pod Disruption Budget | ✅ | ✅ |

### Развертывание и управление

| Развертывание | spotahome/redis-operator | ot-container-kit/redis-operator |
|---------------|---------------------------|---------------------------------|
| Helm chart | ✅ | ✅ |
| Kustomize | ✅ | ✅ |
| Raw manifests | ✅ | ✅ |
| Namespace поддержка | ✅ | ✅ |
| Multi-tenant | ✅ | ✅ |
| Миграция данных | ✅ (bootstrap) | ✅ |
| Масштабирование | ✅ (ручное) | ✅ (авто/ручное) |

## Технические характеристики

### Конфигурация Redis

| Параметр | spotahome/redis-operator | ot-container-kit/redis-operator |
|----------|---------------------------|---------------------------------|
| Custom config | ✅ | ✅ |
| Command renaming | ✅ | ❌ |
| Экспортер конфигурации | ✅ | ✅ |
| Переменные окружения | ✅ | ✅ |
| Пользовательские команды | ✅ | ✅ |

### Конфигурация Sentinel

| Параметр | spotahome/redis-operator | ot-container-kit/redis-operator |
|----------|---------------------------|---------------------------------|
| Quorum настройка | ✅ | ✅ |
| Таймауты failover | ✅ | ✅ |
| Кастомная конфигурация | ✅ | ✅ |
| Мониторинг нескольких мастеров | ❌ | ✅ |

### Хранилище

| Хранилище | spotahome/redis-operator | ot-container-kit/redis-operator |
|-----------|---------------------------|---------------------------------|
| PersistentVolumeClaim | ✅ | ✅ |
| EmptyDir | ✅ | ✅ |
| Storage классы | ✅ | ✅ |
| Размер хранилища | Настраиваемый | Настраиваемый |
| Сохранение при удалении | ✅ (опция) | ✅ |

## Экосистема и интеграции

| Интеграция | spotahome/redis-operator | ot-container-kit/redis-operator |
|------------|---------------------------|---------------------------------|
| Prometheus | ✅ | ✅ |
| Grafana | ❌ | ✅ |
| Alertmanager | ❌ | ✅ |
| Custom Resources | ✅ | ✅ |
| Operator SDK | ❌ | ✅ |
| Kubebuilder | ✅ | ❌ |

## Статистика проекта

| Метрика | spotahome/redis-operator | ot-container-kit/redis-operator |
|---------|---------------------------|---------------------------------|
| GitHub Stars | ~1.2k | ~0.5k |
| Форков | ~250 | ~100 |
| Последний коммит | 2023 | 2023 |
| Активность | Средняя | Средняя |
| Документация | Хорошая | Хорошая |

## Выводы

**spotahome/redis-operator**:
- Специализируется на Redis Sentinel с автоматическим failover
- Отличная поддержка production-готовых функций
- Хорошая интеграция с Kubernetes экосистемой
- Более зрелый и проверенный в production

**ot-container-kit/redis-operator**:
- Поддерживает все режимы Redis (Standalone, Cluster, Sentinel)
- Более современные функции (TLS, ACL, backup)
- Лучшая поддержка мониторинга с Grafana
- Более гибкая архитектура

## Рекомендации

**Выберите spotahome/redis-operator если:**
- Нужен проверенный Redis Sentinel с автоматическим failover
- Требуется production-готовое решение
- Важна стабильность и надежность

**Выберите ot-container-kit/redis-operator если:**
- Нужна поддержка всех режимов Redis
- Требуются современные функции безопасности (TLS, ACL)
- Важен комплексный мониторинг с Grafana
- Нужны функции резервного копирования

Оба оператора являются отличными решениями, но ot-container-kit/redis-operator предлагает больше возможностей благодаря поддержке всех режимов Redis и современных функций безопасности.