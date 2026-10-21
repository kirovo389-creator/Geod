---
name: telegram-readonly
description: List Telegram dialogs and read or search message history through a configured local connector.
---
# Telegram Read-Only
This connector only lists dialogs and reads/searches messages. It cannot send, edit, or delete messages. Configure TELEGRAM_API_ID, TELEGRAM_API_HASH, and TELEGRAM_SESSION_TXT locally. The text file must contain a Telethon StringSession. Never commit or upload the session file or its contents.
