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
cat("📄 Содержимое аналитического отчета:\n")
cat("========================================\n\n")
file.show("results/analytics_report.txt")

cat("\n========================================\n")
cat(" Анализ завершен успешно!\n")
cat("========================================\n\n")
