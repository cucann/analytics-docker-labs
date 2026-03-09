# Отчет по лабораторной работе №3.1. Развертывание приложения в Kubernetes


**Выполнила:** Муханова Анна Игоревна  
**Группа:** АДЭУ-221  
**Вариант:** 9 (MongoDB + Mongo Express)  

## Цель работы
Освоить процесс оркестрации контейнеров в Kubernetes, научиться разворачивать связку NoSQL базы данных с веб-интерфейсом.  

## Ход выполнения

## 1. Подготовка окружения
Проверка работы Kubernetes в Docker Desktop:
```bash
kubectl get nodes
kubectl get pods -A
```
<img width="423" height="46" alt="image" src="https://github.com/user-attachments/assets/a81774bc-5030-4a0a-8639-51379cec22f2" />  

<img width="569" height="311" alt="image" src="https://github.com/user-attachments/assets/10958f77-5fc0-4382-997a-91b2bd70a043" />  


## 2. Создание манифестов 
### 2.1 Secret для MongoDB (mongodb-secret.yaml)
*Секрет используем для безопасного хранения учетных данных*
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
<img width="471" height="142" alt="image" src="https://github.com/user-attachments/assets/ec4531a9-f9f8-4643-9e84-367d147ec52a" />

### 2.2 Deployment для MongoDB (mongodb-deployment.yaml)
<details>
  <summary> <u> ___mongodb-deployment.yaml___ </u> </summary>
  
  ```py
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongodb-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mongodb
  template:
    metadata:
      labels:
        app: mongodb
    spec:
      containers:
      - name: mongodb
        image: mongo:6.0
        ports:
        - containerPort: 27017
        env:
        - name: MONGO_INITDB_ROOT_USERNAME
          valueFrom:
            secretKeyRef:
              name: mongodb-secret
              key: mongodb-root-username
        - name: MONGO_INITDB_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mongodb-secret
              key: mongodb-root-password
        - name: MONGO_INITDB_DATABASE
          value: "analytics_db"
  ```
  
</details>


### 2.3 Deployment для Mongo Express (mongo-express-deployment.yaml)
<details>
  <summary> <u> ___mongo-express-deployment.yaml___ </u> </summary>
  
  ```py
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongo-express-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mongo-express
  template:
    metadata:
      labels:
        app: mongo-express
    spec:
      containers:
      - name: mongo-express
        image: mongo-express:latest
        ports:
        - containerPort: 8081
        env:
        - name: ME_CONFIG_MONGODB_SERVER
          value: "mongodb-service"
        - name: ME_CONFIG_BASICAUTH_USERNAME
          value: "admin"
        - name: ME_CONFIG_BASICAUTH_PASSWORD
          value: "admin123"
  ```
  
</details>

### 2.4 Сервисы (services.yaml)
<details>
  <summary> <u> ___services.yaml___ </u> </summary>
  
  ```py
apiVersion: v1
kind: Service
metadata:
  name: mongodb-service
spec:
  selector:
    app: mongodb
  ports:
    - port: 27017
      targetPort: 27017
  type: ClusterIP
---
apiVersion: v1
kind: Service
metadata:
  name: mongo-express-service
spec:
  selector:
    app: mongo-express
  ports:
    - port: 80
      targetPort: 8081
  type: LoadBalancer
  ```
  
</details>

## 3. Развертывание

```bash
kubectl apply -f mongodb-secret.yaml
kubectl apply -f mongodb-deployment.yaml
kubectl apply -f mongo-express-deployment.yaml
kubectl apply -f services.yaml
```

<img width="607" height="187" alt="image" src="https://github.com/user-attachments/assets/2c227a00-c381-4f4b-87dd-928c0526686e" />

## 4. Результаты

### Состояние подов
<img width="629" height="140" alt="image" src="https://github.com/user-attachments/assets/d05e75c6-7850-4785-8388-3cedf7e77bcd" />  
*Все поды в статусе Running*  
### Состояние сервисов
<img width="582" height="145" alt="image" src="https://github.com/user-attachments/assets/c94b3c26-3c1e-4f76-b9c2-14bff3696c3a" />
*Сервисы успешно созданы*  
### Работающий Mongo Express  
*Вход в систему*
<img width="1306" height="794" alt="image" src="https://github.com/user-attachments/assets/79092d46-3cf7-487c-b2b7-f388ced70cc5" />  

<img width="1470" height="779" alt="Снимок экрана 2026-03-09 в 19 10 39" src="https://github.com/user-attachments/assets/437fc37e-4a8c-425f-936a-abab9f9d71ca" />  
*Веб-интерфейс Mongo Express*  

## 5. Создание и проверка тестовых данных
Для проверки работоспособности развернутой связки MongoDB + Mongo Express были созданы тестовые данные двумя способами: через командную строку и через веб-интерфейс

### 5.1 Создание данных через MongoDB Shell
Было выполнено подключение к контейнеру MongoDB и создана тестовая коллекция metrics в базе данных analytics_db

```bash
kubectl exec -it $(kubectl get pod -l app=mongodb -o jsonpath='{.items[0].metadata.name}') -- mongosh -u admin -p mongopass123
```

В открывшемся MongoDB shell были выполнены следующие команды:
```bash
use analytics_db

db.createCollection("metrics")

db.metrics.insertMany([
    {metric: "cpu_usage", value: 45, host: "macbook-pro"},      // Загрузка CPU: 45%
    {metric: "memory_usage", value: 8192, host: "macbook-pro"}, // Использование RAM: 8192 MB
    {metric: "disk_usage", value: 256000, host: "macbook-pro"}  // Использование диска: 256 GB
])

db.metrics.find().pretty()
```

**Результат выполнения команд:**
<img width="506" height="312" alt="image" src="https://github.com/user-attachments/assets/ecd9f3d5-7b3b-4557-9fcf-dc7e91af2b3f" />
<img width="450" height="310" alt="image" src="https://github.com/user-attachments/assets/f5aef68a-0f98-4719-a10b-4e98206aaa27" />  

### 5.2 Просмотр данных через веб-интерфейс Mongo Express
После создания данных через командную строку, они были проверены в веб-интерфейсе Mongo Express

<img width="1177" height="357" alt="image" src="https://github.com/user-attachments/assets/205e21be-e48a-48be-b55b-bd611cab2d66" />
**В главном окне выбрана база данных analytics_db, выбрана коллекция metrics, отобразились три ранее созданных документа**
<img width="1261" height="766" alt="image" src="https://github.com/user-attachments/assets/864322fb-9c1d-4e80-bea7-faa1c41b09e6" />

**Добавление тестового документа: выбрана коллекция test_collection и вставлен JSON-документ**  
<img width="1119" height="454" alt="image" src="https://github.com/user-attachments/assets/ad689c39-9c5a-42dd-83cf-771a4ad37d47" />

## Выводы
В ходе выполнения лабораторной работы были получены практические навыки создания манифестов Kubernetes для развертывания приложений, использования Secrets для хранения конфиденциальной информации и настройки сетевого взаимодействия между сервисами через ClusterIP и LoadBalancer. Также освоена работа с NoSQL базой данных MongoDB в Kubernetes и организация внешнего доступа к веб-интерфейсу Mongo Express.
