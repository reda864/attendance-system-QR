from django.db import migrations


def fix_legacy_classe_columns(apps, schema_editor):
    connection = schema_editor.connection
    if connection.vendor != "postgresql":
        return

    with connection.cursor() as cursor:
        for column in ("location_type", "description", "niveau"):
            cursor.execute(
                "SELECT 1 FROM information_schema.columns WHERE table_name='classes' AND column_name=%s",
                [column],
            )
            if cursor.fetchone():
                cursor.execute(
                    f"UPDATE classes SET {column} = '' WHERE {column} IS NULL"
                )
                cursor.execute(
                    f"ALTER TABLE classes ALTER COLUMN {column} SET DEFAULT ''"
                )
                cursor.execute(
                    f"ALTER TABLE classes ALTER COLUMN {column} DROP NOT NULL"
                )


def noop_reverse(apps, schema_editor):
    return


class Migration(migrations.Migration):

    dependencies = [
        ("users", "0007_semester_module"),
    ]

    operations = [
        migrations.RunPython(fix_legacy_classe_columns, noop_reverse),
    ]
