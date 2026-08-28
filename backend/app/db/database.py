import logging
import uuid
from datetime import datetime, timezone
from typing import Optional, Dict, Any, List
try:
    from motor.motor_asyncio import AsyncIOMotorClient
except ImportError:
    AsyncIOMotorClient = None

from app.core.config import settings
from app.core.security import get_password_hash

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


async def seed_test_users():
    """Seed 5 pre-configured demo test login accounts into MongoDB or in-memory collection."""
    hashed_pwd = get_password_hash("demo123456")
    now_iso = datetime.now(timezone.utc).isoformat()

    test_accounts = [
        {
            "_id": "usr-test-001",
            "id": "usr-test-001",
            "full_name": "Rahul Sharma",
            "email_or_phone": "arogya_user@example.com",
            "hashed_password": hashed_pwd,
            "primary_role": "PATIENT",
            "app_context": "arogya_sathi",
            "mapped_roles": ["PATIENT"],
            "is_active": True,
            "is_admin": False,
            "created_at": now_iso
        },
        {
            "_id": "usr-test-002",
            "id": "usr-test-002",
            "full_name": "Dr. Ananya Sharma",
            "email_or_phone": "dr_sharma@hospital.org",
            "hashed_password": hashed_pwd,
            "primary_role": "PHYSICIAN",
            "app_context": "medikiosk",
            "mapped_roles": ["PHYSICIAN"],
            "is_active": True,
            "is_admin": False,
            "created_at": now_iso
        },
        {
            "_id": "usr-test-003",
            "id": "usr-test-003",
            "full_name": "Capt. Vikram Verma",
            "email_or_phone": "capt_verma@forces.gov.in",
            "hashed_password": hashed_pwd,
            "primary_role": "SOLDIER",
            "app_context": "rakshak_mitra",
            "mapped_roles": ["SOLDIER", "WELFARE_OFFICER"],
            "is_active": True,
            "is_admin": False,
            "created_at": now_iso
        },
        {
            "_id": "usr-test-004",
            "id": "usr-test-004",
            "full_name": "Rajesh Kumar",
            "email_or_phone": "legal_officer@district.gov.in",
            "hashed_password": hashed_pwd,
            "primary_role": "COUNSELOR",
            "app_context": "nyaya_sahay",
            "mapped_roles": ["COUNSELOR"],
            "is_active": True,
            "is_admin": False,
            "created_at": now_iso
        },
        {
            "_id": "usr-test-005",
            "id": "usr-test-005",
            "full_name": "Admin Director",
            "email_or_phone": "admin@svasthya.gov.in",
            "hashed_password": hashed_pwd,
            "primary_role": "SYSTEM_ADMIN",
            "app_context": "arogya_sathi",
            "mapped_roles": ["SYSTEM_ADMIN", "PHYSICIAN", "WELFARE_OFFICER"],
            "is_active": True,
            "is_admin": True,
            "created_at": now_iso
        }
    ]

    # Seed MongoDB if available
    if db_manager.db is not None:
        try:
            for acc in test_accounts:
                await db_manager.db.users.update_one(
                    {"email_or_phone": acc["email_or_phone"]},
                    {"$set": acc},
                    upsert=True
                )
            logger.info("Successfully seeded test users into MongoDB database.")
        except Exception as e:
            logger.warning(f"Failed to seed MongoDB test users: {e}")

    # Always seed in-memory collection for instant fallback
    for acc in test_accounts:
        existing_idx = next(
            (i for i, u in enumerate(db_manager._in_memory_collections["users"])
             if u["email_or_phone"] == acc["email_or_phone"]),
            None
        )
        if existing_idx is not None:
            db_manager._in_memory_collections["users"][existing_idx] = acc
        else:
            db_manager._in_memory_collections["users"].append(acc)

    logger.info("Seeded 5 pre-configured demo test login accounts into database.")


async def connect_to_mongo():
    """Connect to MongoDB server asynchronously and seed test data."""
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

    # Automatically seed test accounts
    await seed_test_users()


async def close_mongo_connection():
    """Close MongoDB connection."""
    if db_manager.client:
        db_manager.client.close()
        logger.info("MongoDB connection closed.")


def get_database():
    """Get active MongoDB database instance or fallback helper."""
    return db_manager.db
