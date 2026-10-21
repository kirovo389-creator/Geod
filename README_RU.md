# Telegram Read-Only

Read-only MCP connector: список диалогов, чтение последних сообщений и поиск.

## Локальная настройка
Установите зависимости из requirements.txt и задайте переменные окружения:
- TELEGRAM_API_ID
- TELEGRAM_API_HASH
- TELEGRAM_SESSION_TXT — полный путь к локальному .txt, содержащему именно Telethon StringSession

Альтернатива: TELEGRAM_SESSION_PATH указывает на обычную SQLite-сессию Telethon.

**Не добавляйте файл сессии в репозиторий, GitHub Actions artifacts или ChatGPT.** Сессия даёт доступ к аккаунту. Если вы отзовёте её в Telegram, доступ исчезнет.

GitHub Actions здесь только обновляет исходники и проверяет проект; это не постоянный сервер. Конфигурация MCP использует stdio и требует хоста, который может запускать локальный Python-процесс. Одного репозитория недостаточно, чтобы подключить Telegram к ChatGPT Android.
