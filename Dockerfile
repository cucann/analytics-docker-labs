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
