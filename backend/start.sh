#!/bin/bash
# Запуск бэкенда Finery
# --host 0.0.0.0 обязателен для доступа из iOS Simulator и других устройств

cd "$(dirname "$0")"
source .venv/bin/activate

exec uvicorn app.main:app \
  --host 0.0.0.0 \
  --port 8000 \
  --reload \
  --log-level info
