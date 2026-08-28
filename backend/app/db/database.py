import logging
from typing import Optional, Dict, Any, List
from motor.motor_asyncio import AsyncIOMotorClient
from app.core.config import settings

logger = logging.getLogger("uvicorn.error")

class Database:
    client: Optional[AsyncIOMotorClient] = None
    db = None
    _in_memory_collections: Dict[str, List[Dict[str, Any]]] = {
        "users": [],
        "role_mappings": [],
        "consents": []
    }

db_manager = Database()

async def connect_to_mongo():
    """Connect to MongoDB server asynchronously."""
    try:
        db_manager.client = AsyncIOMotorClient(
            settings.MONGODB_URL,
            serverSelectionTimeoutMS=2000
        )
        # Ping server to test connection
        await db_manager.client.admin.command('ping')
        db_manager.db = db_manager.client[settings.MONGODB_DB_NAME]
        logger.info(f"Connected to MongoDB database: '{settings.MONGODB_DB_NAME}' at {settings.MONGODB_URL}")
    except Exception as e:
        logger.warning(f"Could not connect to MongoDB server ({e}). Operating in resilient fallback mode.")
        db_manager.db = None

async def close_mongo_connection():
    """Close MongoDB connection."""
    if db_manager.client:
        db_manager.client.close()
        logger.info("MongoDB connection closed.")

def get_database():
    """Get active MongoDB database instance or fallback helper."""
    return db_manager.db
