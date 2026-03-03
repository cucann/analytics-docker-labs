# Отчет по лабораторной работе №2.1
## Создание Dockerfile и сборка образа

| | |
|---|---|
| **ФИО** | Муханова Анна Игоревна|
| **Группа** | АДЭУ-221 |
| **Вариант** | 9 |
| **Тема данных** | Customer Support (Служба поддержки) |
| **Стек технологий** | R Script |


---

## Цель работы
Научиться разрабатывать воспроизводимые аналитические инструменты: от написания скрипта для обработки бизнес-данных до его упаковки в Docker-образ и запуска в изолированной среде.

---

## Описание задачи

### Предметная область: "Служба поддержки" (Customer Support)

**Бизнес-задача:** проанализировать эффективность работы службы поддержки на основе данных о тикетах.

**Генерируемые данные:**
- `ticket_id` — уникальный идентификатор тикета (TICKET-1001, TICKET-1002, ...)
- `category` — категория проблемы (Technical, Billing, General, Feature Request)
- `response_time` — время реакции на тикет (часы)
- `resolution_time` — время решения проблемы (часы)
- `satisfaction` — оценка пользователя (1-5)

**Рассчитываемые метрики:**
1. Общая статистика по всем тикетам
2. Статистика по категориям проблем:
   - Количество тикетов
   - Среднее время реакции
   - Среднее время решения
   - Средняя оценка
   - Процент удовлетворенных (оценка 4-5)
3. Корреляция между временем реакции и удовлетворенностью
4. Распределение оценок

**Результаты работы:**
- Вывод аналитики в консоль
- CSV-файл с полными данными (`support_tickets.csv`)
- Текстовый файл с аналитическим отчетом (`analytics_report.txt`)

---

## Структура проекта  

<img width="358" height="172" alt="image" src="https://github.com/user-attachments/assets/a68682fd-8485-4d1b-8e63-48c20e9c4c23" />

## Листинг кода

### 1. Аналитический скрипт (`app/analyze_support.R`)

<details>
  <summary> <u> ___Код analyze_support.R___ </u> </summary>
  
  ```r
#!/usr/bin/env Rscript

# Аналитический скрипт для данных службы поддержки
# Вариант 9: R Script + Customer Support

# Установка и загрузка библиотек
if (!require("dplyr")) install.packages("dplyr", repos = "https://cloud.r-project.org")
if (!require("tidyr")) install.packages("tidyr", repos = "https://cloud.r-project.org")

library(dplyr)
library(tidyr)

cat("\n========================================\n")
cat("   Анализ данных службы поддержки\n")
cat("========================================\n\n")

# Функция генерации синтетических данных
generate_support_data <- function(n = 50) {
  set.seed(42) # Для воспроизводимости
  
  categories <- c("Technical", "Billing", "General", "Feature Request")
  
  data.frame(
    ticket_id = paste0("TICKET-", 1001:(1000 + n)),
    category = sample(categories, n, replace = TRUE, prob = c(0.4, 0.3, 0.2, 0.1)),
    response_time = round(abs(rnorm(n, mean = 2, sd = 1.5)), 2), # часы
    resolution_time = round(abs(rnorm(n, mean = 24, sd = 12)), 2), # часы
    satisfaction = sample(1:5, n, replace = TRUE, prob = c(0.05, 0.1, 0.15, 0.3, 0.4))
  )
}

# Генерация данных
cat("Генерация данных о тикетах поддержки...\n")
support_data <- generate_support_data(60)

# Просмотр первых строк
cat("\nПервые 5 тикетов:\n")
print(head(support_data, 5))

# --- Аналитика ---
cat("\n========================================\n")
cat("Аналитические метрики\n")
cat("========================================\n\n")

# 1. Базовые статистики по всем данным
cat("Общая статистика:\n")
cat(sprintf("  Всего тикетов: %d\n", nrow(support_data)))
cat(sprintf("  Среднее время реакции: %.2f часов\n", mean(support_data$response_time)))
cat(sprintf("  Среднее время решения: %.2f часов\n", mean(support_data$resolution_time)))
cat(sprintf("  Средняя оценка: %.2f / 5\n", mean(support_data$satisfaction)))

# 2. Анализ по категориям
cat("\n Статистика по категориям проблем:\n")

category_stats <- support_data %>%
  group_by(category) %>%
  summarise(
    tickets = n(),
    avg_response = round(mean(response_time), 2),
    avg_resolution = round(mean(resolution_time), 2),
    avg_satisfaction = round(mean(satisfaction), 2),
    satisfaction_rate = round(sum(satisfaction >= 4) / n() * 100, 1)
  ) %>%
  arrange(desc(tickets))

print(category_stats)

# 3. Топ проблемных категорий (низкая удовлетворенность)
cat("\nКатегории с низкой удовлетворенностью (< 70%):\n")
low_satisfaction <- category_stats %>% filter(satisfaction_rate < 70)
if (nrow(low_satisfaction) > 0) {
  print(low_satisfaction)
} else {
  cat("  Все категории имеют высокий уровень удовлетворенности!\n")
}

# 4. Корреляция между временем реакции и удовлетворенностью
correlation <- cor(support_data$response_time, support_data$satisfaction)
cat(sprintf("\n📉 Корреляция время реакции -> удовлетворенность: %.3f\n", correlation))
if (correlation < -0.3) {
  cat("   Наблюдается обратная зависимость: чем дольше реакция, тем ниже оценка\n")
} else {
  cat("   Сильной зависимости не наблюдается\n")
}

# 5. Распределение оценок
cat("\n📊 Распределение оценок:\n")
satisfaction_dist <- support_data %>%
  group_by(satisfaction) %>%
  summarise(count = n()) %>%
  mutate(percentage = round(count / sum(count) * 100, 1))

print(satisfaction_dist)

# Сохранение результатов в файл
cat("\n========================================\n")
cat(" Сохранение результатов...\n")

# Создаем директорию для результатов, если её нет
if (!dir.exists("results")) {
  dir.create("results")
}

# Сохраняем полные данные
write.csv(support_data, "results/support_tickets.csv", row.names = FALSE)
cat("   Данные сохранены в results/support_tickets.csv\n")

# Сохраняем аналитический отчет
sink("results/analytics_report.txt")
cat("========================================\n")
cat("   ОТЧЕТ ПО АНАЛИЗУ СЛУЖБЫ ПОДДЕРЖКИ\n")
cat("========================================\n\n")
cat("Дата анализа:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n\n")

cat("1. ОБЩАЯ СТАТИСТИКА\n")
cat("------------------\n")
cat(sprintf("Всего тикетов: %d\n", nrow(support_data)))
cat(sprintf("Среднее время реакции: %.2f часов\n", mean(support_data$response_time)))
cat(sprintf("Среднее время решения: %.2f часов\n", mean(support_data$resolution_time)))
cat(sprintf("Средняя оценка: %.2f / 5\n\n", mean(support_data$satisfaction)))

cat("2. СТАТИСТИКА ПО КАТЕГОРИЯМ\n")
cat("--------------------------\n")
print(category_stats)

cat("\n3. РАСПРЕДЕЛЕНИЕ ОЦЕНОК\n")
cat("----------------------\n")
print(satisfaction_dist)

cat("\n4. КОРРЕЛЯЦИОННЫЙ АНАЛИЗ\n")
cat("-----------------------\n")
cat(sprintf("Корреляция время реакции - удовлетворенность: %.3f\n", correlation))

sink()
cat("   Аналитический отчет сохранен в results/analytics_report.txt\n")

# Вывод содержимого отчета в консоль
cat("\n========================================\n")
cat(" Содержимое аналитического отчета:\n")
cat("========================================\n\n")
file.show("results/analytics_report.txt")

cat("\n========================================\n")
cat(" Анализ завершен успешно!\n")
cat("========================================\n\n")

  ```
  
</details>

### 2.Dockerfile  

<details>
  <summary> ___Показать файл Dockerfile___ </summary>
  
  ```r
# Базовый образ с R
FROM rocker/r-ver:4.3.1

# Установка системных зависимостей для R packages
RUN apt-get update && apt-get install -y \
    libssl-dev \
    libcurl4-openssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# Создание рабочей директории
WORKDIR /app

# Копирование скрипта
COPY app/analyze_support.R .
COPY .dockerignore .

# Установка R-пакетов (выполняется при сборке)
RUN Rscript -e "install.packages(c('dplyr', 'tidyr'), repos='https://cloud.r-project.org')"

# Создание директории для результатов
RUN mkdir -p /app/results

# Команда для запуска
CMD ["Rscript", "analyze_support.R"]
  ```
  
</details>  


### 3.Dockerignore  
<details>
  <summary> ___Показать файл Dockerignore___ </summary>
  
  ```py
.git
.gitignore
README.md
REPORT.md
.DS_Store
results/
*.Rproj
.Rhistory
.RData
.Ruserdata
  ```
  
</details>  


---

### Ход выполнения работы

## 1. Создание структуры проекта

```bash
cd ~/Desktop
mkdir -p lab_02.1/app
cd lab_02.1
touch Dockerfile .dockerignore
  ```
  
</details> 
<img width="567" height="165" alt="image" src="https://github.com/user-attachments/assets/6aee0863-128b-47ca-b040-df69697305f8" />  

## 2. Написание аналитического скрипта
Скрипт app/analyze_support.R создан и содержит все необходимые функции для генерации данных и расчета метрик.

## 3. Создание Dockerfile
Оптимизированный Dockerfile включает:

*Минимальный базовый образ rocker/r-ver (экономия места)*

*Установку системных зависимостей*

*Кэширование слоя с установкой R-пакетов*

*Создание директории для результатов*

<img width="640" height="377" alt="image" src="https://github.com/user-attachments/assets/8a16a5dd-aed8-476b-b6dc-eae111856c05" />  

## 4. Сборка Docker-образа
```bash
docker build -t support-analytics:v1 .
  ```
  
</details> 

<img width="599" height="277" alt="image" src="https://github.com/user-attachments/assets/e3c5e606-cd9b-457c-b156-467d95fe59ea" />

## 5. Запуск контейнера
```bash
docker run --name support-analysis support-analytics:v1
  ```
  
</details> 

<img width="700" height="354" alt="image" src="https://github.com/user-attachments/assets/b636861d-5fd7-4cd6-af24-f536d1129704" />

## Просмотр результатов из папки results  
**analytics_report.txt**    
<img width="530" height="562" alt="image" src="https://github.com/user-attachments/assets/c9e191af-2a82-426a-86dc-fc742832c79d" />

**support_tickets.csv**    
<img width="522" height="114" alt="image" src="https://github.com/user-attachments/assets/d7c1c518-f52a-4729-8e2e-a476f17f186e" />

## Результаты работы
## Вывод в консоль при запуске:
<img width="559" height="641" alt="image" src="https://github.com/user-attachments/assets/ca33c58b-0592-4a28-aa1a-a58c186f9527" />  
<img width="464" height="214" alt="image" src="https://github.com/user-attachments/assets/43a7e9d1-8ec4-48c8-b14b-eef65faca10d" />

## Созданные файлы:  
support_tickets.csv — полные данные о тикетах (60 записей, 5 полей)  
analytics_report.txt — структурированный аналитический отчет:  
<img width="527" height="537" alt="image" src="https://github.com/user-attachments/assets/baabb87c-3d51-4709-8f77-18e77af2ad62" />  

## Визуализация результатов    
Была выполнена визуализация результатов выгруженного csv файла с помощью plotly.js, графики интерактивны    
# Распределение тикетов по категориям
<img width="743" height="410" alt="image" src="https://github.com/user-attachments/assets/152582bf-d832-40a4-bc0c-3fc0e2101755" />  

# Распределение времени реакции и решений по категориям  
<img width="1186" height="546" alt="image" src="https://github.com/user-attachments/assets/ae6a171c-d245-447a-83ea-913b705f5479" />  

# 3д визуализация времени реакции, времени решения и оценки решения проблемы  
<img width="689" height="481" alt="image" src="https://github.com/user-attachments/assets/666e5afc-96a6-4179-a25c-afd26771f0d1" />  


## Выводы  
Большинство тикетов приходится на категории Technical (31.7%) и General (28.3%), при этом пользователи чаще всего ставят оценки 4 (хорошо) и 5 (отлично) — это 42 из 60 тикетов (70%), что говорит в целом о высоком уровне удовлетворенности службой поддержки.
В ходе выполнения работы был разработан аналитический скрипт на языке R для генерации и анализа данных службы поддержки, а также создан Dockerfile для контейнеризации приложения. Собранный Docker-образ успешно запускается, выполняет расчет метрик (среднее время реакции и решения, корреляцию, распределение оценок) и сохраняет результаты в CSV и текстовый файл, что подтверждает корректность настройки всех компонентов и достижение цели работы.    


## Приложение  

* [Файл analyze_support.R](/app/analyze_support.R) аналитический скрипт на R  
* [Файл Dockerfile](/Dockerfile) инструкции для сборки образа  
* [Файл .dockerignore](/.dockerignore) исключаемые файлы  
* [analytics_report.txt](analytics_report.txt) аналитический отчет  
* [support_tickets.csv](support_tickets.csv) сгенерированные данные


