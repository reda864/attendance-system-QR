from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ("users", "0008_fix_legacy_classe_columns"),
    ]

    operations = [
        migrations.RunSQL(
            sql="""
                UPDATE classes SET location_type = '' WHERE location_type IS NULL;
                UPDATE classes SET description = '' WHERE description IS NULL;
                UPDATE classes SET niveau = '' WHERE niveau IS NULL;
                ALTER TABLE classes ALTER COLUMN location_type SET DEFAULT '';
                ALTER TABLE classes ALTER COLUMN description SET DEFAULT '';
                ALTER TABLE classes ALTER COLUMN niveau SET DEFAULT '';
                ALTER TABLE classes ALTER COLUMN location_type DROP NOT NULL;
                ALTER TABLE classes ALTER COLUMN description DROP NOT NULL;
                ALTER TABLE classes ALTER COLUMN niveau DROP NOT NULL;
            """,
            reverse_sql=migrations.RunSQL.noop,
        ),
    ]
