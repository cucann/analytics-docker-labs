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

### Структура проекта  
<img width="294" height="233" alt="image" src="https://github.com/user-attachments/assets/a4f0d504-9bb5-4b08-8b9d-467ae277bc9e" />  

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


### 4.3 Разработка фронтенда  
Фронтенд реализован на Streamlit с удобным пользовательским интерфейсом.  
Файл src/frontend/requirements.txt:  
```bash
streamlit==1.28.1
requests==2.31.0
pandas==2.1.3
plotly==5.18.0
openpyxl==3.1.2
```

### Основные функции фронтенда

| Функция | Описание | Реализация |
|:--------|:---------|:-----------|
| **Загрузка событий из API** | Получение данных с бэкенда с кэшированием | `@st.cache_data(ttl=10)` |
| **Фильтрация** | Поиск по названию, фильтр по месту, диапазон дат | `st.text_input`, `st.selectbox`, `st.date_input` |
| **Экспорт данных** | Выгрузка в CSV и Excel форматы | `get_csv_download_link()`, `get_excel_download_link()` |
| **Цветовая подсветка** | Визуальное выделение событий по датам (просроченные, сегодняшние, ближайшие) | `highlight_dates()` с CSS стилями |
| **Редактирование событий** | Изменение существующих событий через форму | `update_event()` с предзаполненной формой |
| **Удаление событий** | Удаление выбранных событий с подтверждением | `delete_event()` с кнопкой подтверждения |
| **Статистика и графики** | Отображение метрик, графиков и аналитики | Plotly, `st.metric`, `st.progress` |
| **Календарное отображение** | Визуализация событий по месяцам | `calendar` модуль, сетка календаря |

### 4.4 Контейнеризация  
Dockerfile для бэкенда (src/backend/Dockerfile):  
```bash
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
```

Dockerfile для фронтенда (src/frontend/Dockerfile):
```bash
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 8501
CMD ["streamlit", "run", "app.py", "--server.port=8501", "--server.address=0.0.0.0"]
```

Сборка образов:
```bash
cd src/backend && docker build -t event-backend:v1 . && cd ../..
cd src/frontend && docker build -t event-frontend:v1 . && cd ../..
```

### 4.5 Манифесты Kubernetes
Файл k8s/fullstack.yaml содержит все необходимые ресурсы:

*Secret - для хранения учетных данных MongoDB*  
*Deployment для MongoDB*  
*Service для MongoDB (ClusterIP)*  
*Deployment для бэкенда*  
*Service для бэкенда (ClusterIP)*  
*Deployment для фронтенда*  
*Service для фронтенда (LoadBalancer)*  

Фрагмент манифеста с секретом:  
```bash
apiVersion: v1
kind: Secret
metadata:
  name: mongodb-secret
type: Opaque
data:
  mongodb-root-username: YWRtaW4=  # admin
  mongodb-root-password: bW9uZ29wYXNzMTIz  # mongopass123
```

Фрагмент манифеста с бэкендом:
```bash
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: event-backend:v1
        env:
        - name: MONGO_URI
          value: "mongodb://admin:mongopass123@mongodb-service:27017"
        - name: DB_NAME
          value: "events_db"
        ports:
        - containerPort: 8000
```

### 4.6 Развертывание и тестирование
Развертывание приложения:

```bash
kubectl apply -f k8s/fullstack.yaml
```

Проверка статуса подов:
```bash
kubectl get pods
```
<img width="567" height="168" alt="image" src="https://github.com/user-attachments/assets/57c97a09-a704-4919-a92a-5ffa1ab1b268" />  

Проверка сервисов:
```bash
kubectl get services
```
<img width="572" height="217" alt="image" src="https://github.com/user-attachments/assets/8ffce477-6716-4463-8c20-7ddce358776e" />  

Доступ к приложению:
```bash
kubectl port-forward deployment/frontend-deployment 8501:8501
```

<img width="641" height="61" alt="image" src="https://github.com/user-attachments/assets/9eae4c3f-e74b-4595-86f2-c21bbd10bdbb" />  

### Сводная таблица дополнительных функций

| № | Функция | Место в приложении | Пользовательская ценность |
|:--:|:--------|:-------------------|:--------------------------|
| 1 | Уведомления | Главная страница, сверху | Не даёт пропустить важные события |
| 2 | Таймер обратного отсчёта | Боковая панель | Показывает время до ближайшего события |
| 3 | Рейтинг участников | Раздел "Аналитика" | Мотивирует участников |
| 4 | Редактирование событий | Раздел "Все события" | Удобное исправление ошибок |
| 5 | Расширенная аналитика | Раздел "Аналитика" | Глубокое понимание данных |
| 6 | Календарный вид | Раздел "Календарь" | Наглядное планирование |
| 7 | Экспорт данных | Раздел "Все события" | Работа с данными в других программах |  


### Интерфейс приложения  
<img width="1456" height="775" alt="image" src="https://github.com/user-attachments/assets/9e0330d1-1e64-4ff8-8d45-ca15332ed366" />  

### Добавление события  
<img width="1467" height="776" alt="image" src="https://github.com/user-attachments/assets/34e76577-8853-41a5-b153-32b012e1c108" />  

### Страница с аналитикой по встречам/событиям    
<img width="1465" height="782" alt="image" src="https://github.com/user-attachments/assets/b1ae9eee-dcbd-4d40-bc97-c9a5967e6f33" />  

### Календарь событий на месяц  
<img width="1467" height="781" alt="image" src="https://github.com/user-attachments/assets/b0895c46-c32a-4307-b9a5-6c6a4af4bc48" />  


### Работа с CI/CD в GitHub  
В проекте настроен автоматический пайплайн непрерывной интеграции с использованием **GitHub Actions**. При каждом push в репозиторий автоматически запускаются тесты и проверки.  

### 📁 Структура CI/CD

```yaml
# .github/workflows/ci.yml
name: CI Pipeline

on:
  push:
    branches: [ main ]      # Запуск при push в main
  pull_request:
    branches: [ main ]       # Запуск при создании PR

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.9'
      
      - name: Test backend dependencies
        run: |
          cd src/backend
          pip install -r requirements.txt
          python -c "import fastapi; print(' FastAPI OK')"
          python -c "import motor; print(' Motor OK')"
      
      - name: Test frontend dependencies
        run: |
          cd src/frontend
          pip install -r requirements.txt
          python -c "import streamlit; print(' Streamlit OK')"
      
      - name: Check YAML syntax
        run: |
          pip install yamllint
          yamllint k8s/fullstack.yaml
<img width="1462" height="778" alt="image" src="https://github.com/user-attachments/assets/1c2196ce-9567-4f38-9a16-09b5c9e35de4" />
```

### Что проверяется в CI

| Этап | Проверка | Назначение |
|:-----:|:---------|:-----------|
| 1 | Checkout code | Получение кода из репозитория |
| 2 | Setup Python | Настройка окружения Python |
| 3 | Backend dependencies | Проверка зависимостей бэкенда |
| 4 | Frontend dependencies | Проверка зависимостей фронтенда |
| 5 | YAML syntax | Валидация Kubernetes манифестов |

### Процесс разработки с CI/CD
```bash
# 1. Внесение изменений в код
git add .
git commit -m "feat: add new feature"

# 2. Автоматический запуск CI при push
git push origin main

```
<img width="603" height="257" alt="image" src="https://github.com/user-attachments/assets/4c0b68e0-a060-42dc-97a0-aa567a0e55a3" />

### Версионирование  
В проекте используется семантическое версионирование (SemVer):  
```bash
# Создание версий
git tag v1.0.0  # базовая версия
git tag v1.1.0  # добавлен календарь с напоминанием
git tag v2.0.0  # финальная версия с CI/CD

# Отправка тегов на GitHub
git push --tags
```
<img width="586" height="104" alt="image" src="https://github.com/user-attachments/assets/90966a7a-c787-4b6b-9bd9-3ce5c47ef1a6" />  

*Статус пайплайна: Все проверки проходят успешно*   
<img width="1453" height="335" alt="image" src="https://github.com/user-attachments/assets/15404f2b-79e5-444d-a985-2026fd3d54ec" />  
<img width="1465" height="766" alt="image" src="https://github.com/user-attachments/assets/685dc729-9cbd-436d-846c-a2f7293c4582" />  

### Ссылки

- **Репозиторий на GitHub:** [https://github.com/cucann/event-manager](https://github.com/cucann/event-manager)
- **GitHub Actions (CI/CD):** [https://github.com/cucann/event-manager/actions](https://github.com/cucann/event-manager/actions)
- **Releases (версии):** [https://github.com/cucann/event-manager/releases](https://github.com/cucann/event-manager/releases)

## Вывод

В результате выполнения лабораторной работы было разработано и развернуто в Kubernetes полнофункциональное приложение для управления корпоративными событиями (Event Manager). Приложение полностью соответствует требованиям и успешно решает бизнес-задачу по управлению корпоративными событиями, предоставляя пользователям удобный инструмент для планирования и анализа.

