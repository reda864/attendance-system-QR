from django.db import migrations


class Migration(migrations.Migration):
    """Add level/field columns expected by the Classe model on legacy DB tables."""

    dependencies = [
        ("users", "0004_user_is_also_teacher"),
    ]

    operations = [
        migrations.RunSQL(
            sql="""
                ALTER TABLE classes
                ADD COLUMN IF NOT EXISTS level VARCHAR(50) NOT NULL DEFAULT '';
                ALTER TABLE classes
                ADD COLUMN IF NOT EXISTS field VARCHAR(100) NOT NULL DEFAULT '';
                UPDATE classes
                SET level = COALESCE(NULLIF(niveau, ''), level, '')
                WHERE level = '' OR level IS NULL;
            """,
            reverse_sql=migrations.RunSQL.noop,
        ),
    ]
