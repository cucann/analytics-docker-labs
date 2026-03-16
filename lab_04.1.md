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

## Технологический стек
Контейнеризация: Docker  
Оркестрация: Kubernetes (Docker Desktop)  
База данных: MongoDB 6.0  
Бэкенд: FastAPI, Motor (асинхронный драйвер MongoDB)  
Фронтенд: Streamlit, Pandas, Plotly, Requests  
Язык программирования: Python 3.9  

## Ход выполнения  
### 4.1 Подготовка окружения  
```bash
# Создание структуры проекта
mkdir -p lab_04.1/src/{backend,frontend}
mkdir -p lab_04.1/k8s
cd lab_04.1

# Проверка работы Kubernetes
kubectl get nodes  
kubectl get pods -A  
```

<img width="539" height="72" alt="image" src="https://github.com/user-attachments/assets/f24af981-8a2f-4bf0-b5fa-a463f7e1c506" />  
<img width="564" height="199" alt="image" src="https://github.com/user-attachments/assets/0f598669-7e09-4ea5-9167-3b31ec90e872" />  

### 4.2 Разработка бэкенда
Бэкенд реализован на FastAPI и предоставляет REST API для работы с событиями.
Файл src/backend/requirements.txt:  
```bash
fastapi==0.104.1
uvicorn==0.24.0
motor==3.1.1
pymongo==4.5.0
pydantic==2.5.0
python-multipart==0.0.6
```

<img width="179" height="98" alt="image" src="https://github.com/user-attachments/assets/32e84add-643b-4e8a-b869-0e503f8f789d" />  

Фрагмент src/backend/main.py:  
<details>
  <summary> <u> ___src/backend/main.py___ </u> </summary>
  
  ```py
from fastapi import FastAPI
from motor.motor_asyncio import AsyncIOMotorClient
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
import os

app = FastAPI(title="Event Manager API")

MONGO_URI = os.getenv("MONGO_URI", "mongodb://admin:mongopass123@mongodb-service:27017")
DB_NAME = os.getenv("DB_NAME", "events_db")

class EventModel(BaseModel):
    title: str
    date: str
    time: str
    location: str
    participants: List[str] = []
    description: Optional[str] = None

@app.on_event("startup")
async def startup_db_client():
    app.mongodb_client = AsyncIOMotorClient(MONGO_URI)
    app.mongodb = app.mongodb_client[DB_NAME]
    print("✅ Connected to MongoDB")

@app.get("/events")
async def get_events():
    events = []
    cursor = app.mongodb["events"].find()
    async for document in cursor:
        document["id"] = str(document.pop("_id"))
        events.append(document)
    return events

@app.post("/events")
async def create_event(event: EventModel):
    result = await app.mongodb["events"].insert_one(event.dict())
    created = await app.mongodb["events"].find_one({"_id": result.inserted_id})
    created["id"] = str(created.pop("_id"))
    return created
  ```
  
</details>  

