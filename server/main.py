import os
from pathlib import Path
from telethon import TelegramClient
from telethon.sessions import StringSession
from mcp.server.fastmcp import FastMCP

API_ID = os.getenv("TELEGRAM_API_ID", "").strip()
API_HASH = os.getenv("TELEGRAM_API_HASH", "").strip()
SESSION_TXT = os.getenv("TELEGRAM_SESSION_TXT", "").strip()
SESSION_PATH = os.getenv("TELEGRAM_SESSION_PATH", str(Path.home() / ".telegram-readonly" / "telegram.session"))

if not API_ID.isdigit() or not API_HASH:
    raise SystemExit("Set TELEGRAM_API_ID and TELEGRAM_API_HASH in the local environment.")

if SESSION_TXT:
    p = Path(SESSION_TXT).expanduser()
    if not p.is_file():
        raise SystemExit("TELEGRAM_SESSION_TXT must point to a local text file.")
    value = p.read_text(encoding="utf-8").strip()
    if not value:
        raise SystemExit("The session text file is empty.")
    session = StringSession(value)
else:
    session = SESSION_PATH

client = TelegramClient(session, int(API_ID), API_HASH)
mcp = FastMCP("Telegram Read-Only")

async def ensure_client():
    await client.connect()
    if not await client.is_user_authorized():
        raise RuntimeError("Telegram session is not authorized. Authenticate locally; never upload the session to chat.")

@mcp.tool()
async def list_dialogs(limit: int = 100) -> list[dict]:
    """List dialogs, groups, and channels visible to the authorized account."""
    await ensure_client()
    out = []
    async for d in client.iter_dialogs(limit=max(1, min(int(limit), 200))):
        e = d.entity
        out.append({"name": d.name or "", "id": int(d.id), "username": getattr(e, "username", None),
                    "entity_type": e.__class__.__name__, "unread_count": int(getattr(d, "unread_count", 0))})
    return out

@mcp.tool()
async def recent_messages(chat_id: int, limit: int = 30) -> list[dict]:
    """Read recent messages from a Telegram dialog by ID."""
    await ensure_client()
    out = []
    async for m in client.iter_messages(int(chat_id), limit=max(1, min(int(limit), 100))):
        sender = await m.get_sender()
        out.append({"id": int(m.id), "date": m.date.isoformat() if m.date else None,
                    "sender_id": int(sender.id) if sender and getattr(sender, "id", None) else None,
                    "text": m.message or ""})
    return list(reversed(out))

@mcp.tool()
async def search_messages(query: str, limit: int = 30, chat_id: int | None = None) -> list[dict]:
    """Search accessible message history; optionally restrict to one chat ID."""
    await ensure_client()
    query = query.strip()
    if not query:
        return []
    limit = max(1, min(int(limit), 100))
    out = []
    if chat_id is not None:
        async for m in client.iter_messages(int(chat_id), search=query, limit=limit):
            out.append({"chat_id": int(chat_id), "message_id": int(m.id),
                        "date": m.date.isoformat() if m.date else None, "text": m.message or ""})
        return out
    async for d in client.iter_dialogs(limit=200):
        async for m in client.iter_messages(d.entity, search=query, limit=5):
            out.append({"chat_id": int(d.id), "chat_name": d.name, "message_id": int(m.id),
                        "date": m.date.isoformat() if m.date else None, "text": m.message or ""})
            if len(out) >= limit:
                return out
    return out

if __name__ == "__main__":
    mcp.run()
