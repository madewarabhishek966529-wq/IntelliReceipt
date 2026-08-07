"""initial schema

Revision ID: 0001_initial
Revises:
Create Date: 2026-08-06

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = "0001_initial"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    payment_method_enum = postgresql.ENUM(
        "cash", "card", "upi", "wallet", "other", name="payment_method_enum"
    )
    receipt_status_enum = postgresql.ENUM(
        "pending", "processing", "needs_review", "completed", "failed",
        name="receipt_status_enum",
    )
    budget_period_enum = postgresql.ENUM("weekly", "monthly", name="budget_period_enum")
    notification_type_enum = postgresql.ENUM(
        "price_increase", "budget_80", "budget_90", "budget_100", "budget_exceeded",
        "weekly_report", "monthly_report", "cheaper_alternative",
        name="notification_type_enum",
    )
    insight_period_enum = postgresql.ENUM("weekly", "monthly", name="insight_period_enum")

    bind = op.get_bind()
    payment_method_enum.create(bind, checkfirst=True)
    receipt_status_enum.create(bind, checkfirst=True)
    budget_period_enum.create(bind, checkfirst=True)
    notification_type_enum.create(bind, checkfirst=True)
    insight_period_enum.create(bind, checkfirst=True)

    op.create_table(
        "categories",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("name", sa.String(100), nullable=False, unique=True),
        sa.Column("icon", sa.String(50), nullable=True),
        sa.Column("color_hex", sa.String(9), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )

    op.create_table(
        "stores",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("name", sa.String(255), nullable=False),
        sa.Column("normalized_name", sa.String(255), nullable=False),
        sa.Column("address", sa.String(512), nullable=True),
        sa.Column("latitude", sa.Float, nullable=True),
        sa.Column("longitude", sa.Float, nullable=True),
        sa.Column("logo_url", sa.String(512), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_stores_name", "stores", ["name"])
    op.create_index("ix_stores_normalized_name", "stores", ["normalized_name"])

    op.create_table(
        "users",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("email", sa.String(255), nullable=False, unique=True),
        sa.Column("name", sa.String(255), nullable=False),
        sa.Column("hashed_password", sa.String(255), nullable=True),
        sa.Column("google_id", sa.String(255), nullable=True, unique=True),
        sa.Column("photo_url", sa.String(512), nullable=True),
        sa.Column("email_verified", sa.Boolean, nullable=False, server_default=sa.false()),
        sa.Column("is_active", sa.Boolean, nullable=False, server_default=sa.true()),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_users_email", "users", ["email"])

    op.create_table(
        "products",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("name", sa.String(255), nullable=False),
        sa.Column("normalized_name", sa.String(255), nullable=False),
        sa.Column("brand", sa.String(255), nullable=True),
        sa.Column("category_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("categories.id"), nullable=True),
        sa.Column("default_unit", sa.String(20), nullable=True),
        sa.Column("barcode", sa.String(64), nullable=True, unique=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_products_name", "products", ["name"])
    op.create_index("ix_products_normalized_name", "products", ["normalized_name"])

    op.create_table(
        "receipts",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("store_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("stores.id"), nullable=True),
        sa.Column("image_url", sa.String(512), nullable=True),
        sa.Column("raw_ocr_text", sa.String, nullable=True),
        sa.Column("invoice_number", sa.String(100), nullable=True),
        sa.Column("purchase_date", sa.Date, nullable=True),
        sa.Column("purchase_time", sa.Time, nullable=True),
        sa.Column("subtotal", sa.Float, nullable=True),
        sa.Column("tax_amount", sa.Float, nullable=True),
        sa.Column("discount_amount", sa.Float, nullable=True),
        sa.Column("total_amount", sa.Float, nullable=True),
        sa.Column("payment_method", payment_method_enum, nullable=True),
        sa.Column("status", receipt_status_enum, nullable=False, server_default="pending"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_receipts_user_id", "receipts", ["user_id"])

    op.create_table(
        "receipt_items",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("receipt_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("receipts.id"), nullable=False),
        sa.Column("product_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("products.id"), nullable=True),
        sa.Column("raw_text", sa.String(500), nullable=False),
        sa.Column("display_name", sa.String(255), nullable=False),
        sa.Column("quantity", sa.Float, nullable=False, server_default="1.0"),
        sa.Column("unit", sa.String(20), nullable=True),
        sa.Column("mrp", sa.Float, nullable=True),
        sa.Column("discount", sa.Float, nullable=True),
        sa.Column("tax", sa.Float, nullable=True),
        sa.Column("final_price", sa.Float, nullable=False),
        sa.Column("ai_confidence", sa.Float, nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_receipt_items_receipt_id", "receipt_items", ["receipt_id"])
    op.create_index("ix_receipt_items_product_id", "receipt_items", ["product_id"])

    op.create_table(
        "price_history",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("product_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("products.id"), nullable=False),
        sa.Column("store_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("stores.id"), nullable=True),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("price", sa.Float, nullable=False),
        sa.Column("observed_date", sa.Date, nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_price_history_product_id", "price_history", ["product_id"])
    op.create_index("ix_price_history_store_id", "price_history", ["store_id"])
    op.create_index("ix_price_history_user_id", "price_history", ["user_id"])
    op.create_index("ix_price_history_observed_date", "price_history", ["observed_date"])

    op.create_table(
        "budgets",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("category_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("categories.id"), nullable=True),
        sa.Column("label", sa.String(100), nullable=False),
        sa.Column("limit_amount", sa.Float, nullable=False),
        sa.Column("period", budget_period_enum, nullable=False, server_default="monthly"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_budgets_user_id", "budgets", ["user_id"])

    op.create_table(
        "notifications",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("type", notification_type_enum, nullable=False),
        sa.Column("title", sa.String(255), nullable=False),
        sa.Column("body", sa.String(1000), nullable=False),
        sa.Column("is_read", sa.Boolean, nullable=False, server_default=sa.false()),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_notifications_user_id", "notifications", ["user_id"])

    op.create_table(
        "insights",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("period", insight_period_enum, nullable=False),
        sa.Column("period_start", sa.Date, nullable=False),
        sa.Column("period_end", sa.Date, nullable=False),
        sa.Column("summary", sa.String(2000), nullable=False),
        sa.Column("highlights", sa.JSON, nullable=False, server_default="[]"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_insights_user_id", "insights", ["user_id"])


def downgrade() -> None:
    op.drop_table("insights")
    op.drop_table("notifications")
    op.drop_table("budgets")
    op.drop_table("price_history")
    op.drop_table("receipt_items")
    op.drop_table("receipts")
    op.drop_table("products")
    op.drop_table("users")
    op.drop_table("stores")
    op.drop_table("categories")

    bind = op.get_bind()
    postgresql.ENUM(name="insight_period_enum").drop(bind, checkfirst=True)
    postgresql.ENUM(name="notification_type_enum").drop(bind, checkfirst=True)
    postgresql.ENUM(name="budget_period_enum").drop(bind, checkfirst=True)
    postgresql.ENUM(name="receipt_status_enum").drop(bind, checkfirst=True)
    postgresql.ENUM(name="payment_method_enum").drop(bind, checkfirst=True)
