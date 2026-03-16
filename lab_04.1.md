# Отчет по лабораторной работе №4.1. Создание и развертывание полнофункционального приложения

**Выполнила:** Муханова Анна Игоревна  
**Группа:** АДЭУ-221  
**Вариант:** 9 (Event Manager - Менеджер событий)  

## Цель работы
Применить полученные знания по созданию и развертыванию трехзвенного приложения (Frontend + Backend + Database) в кластере Kubernetes. Научиться организовывать взаимодействие между микросервисами и управлять полным жизненным циклом приложения.  

## Архитектура решения

```mermaid
graph TD
    %% Определение цветов
    classDef config fill:#f9f9f9,stroke:#333,stroke-width:1px;
    classDef db fill:#e1f5fe,stroke:#0277bd,stroke-width:2px;
    classDef backend fill:#fff3e0,stroke:#ef6c00,stroke-width:2px;
    classDef frontend fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px;
    classDef user fill:#ffebee,stroke:#c62828,stroke-width:2px;

    subgraph K8s_Cluster ["K8s Cluster (Docker Desktop)"]
        
        subgraph Configs ["Конфигурация"]
            SEC["Secret<br/>(mongodb-secret)"]
        end

        subgraph Database ["Слой данных"]
            DB_POD["MongoDB Pod<br/>port 27017"]
            DB_SVC["mongodb-service<br/>ClusterIP"]
        end

        subgraph Backend ["Бэкенд (FastAPI)"]
            API_POD["Backend Pod<br/>port 8000"]
            API_SVC["backend-service<br/>ClusterIP"]
        end

        subgraph Frontend ["Фронтенд (Streamlit)"]
            UI_POD["Frontend Pod<br/>port 8501"]
            UI_SVC["frontend-service<br/>LoadBalancer"]
        end

        %% Связи
        SEC -.-> DB_POD
        SEC -.-> API_POD
        DB_POD --- DB_SVC
        API_POD -->|Чтение/Запись| DB_SVC
        API_POD --- API_SVC
        UI_POD -->|HTTP запросы| API_SVC
        UI_POD --- UI_SVC
    end

    User(("Пользователь")) -->|http://localhost:8501| UI_SVC

    class SEC config;
    class DB_POD,DB_SVC db;
    class API_POD,API_SVC backend;
    class UI_POD,UI_SVC frontend;
    class User user;
```

### Описание архитектуры

| Компонент | Назначение | Технологии |
|:----------|:-----------|:-----------|
| **База данных** | Хранение информации о событиях | MongoDB |
| **Бэкенд** | REST API для CRUD операций | FastAPI, Motor |
| **Фронтенд** | Пользовательский интерфейс | Streamlit |
| **Secret** | Безопасное хранение учетных данных | Kubernetes Secret |

