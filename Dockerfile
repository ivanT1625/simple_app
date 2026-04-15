FROM python:3.12-slim

## Установка зависимостей
#RUN apt-get update && apt-get install -y \
#    curl \
#    && rm -rf /var/lib/apt/lists/*

# Устанавливаем переменные окружения
ENV PYTHONDUNBUFFERED=1
ENV PYTHONPATH=/app

# Создание рабочего каталога
WORKDIR /app

# Копирование файлов приложения
#COPY app/main.py .
COPY requirements.txt .

# Установка Python‑зависимостей
RUN pip install --no-cache-dir -r requirements.txt

# Копируем приложение
COPY app/ ./

# Копирование скрипта диагностики
#COPY scripts/server-info.sh /usr/local/bin/server-info.sh
#RUN chmod +x /usr/local/bin/server-info.sh

# Создание лог‑директории
# RUN mkdir -p /var/log && touch /var/log/server-diagnostics.log

# Экспозиция порта
EXPOSE 5000


# Добавляем HEALTHCHECK
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD curl -f http://localhost:5000/health || exit 1


## Запуск приложения
#CMD ["python", "main.py"]

# Запускаем приложение через gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "main:app"]

