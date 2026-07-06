from django.db import migrations

NEW_CONSTRAINT_NAME = "sessions_module_id_class_modules_fk"


def fix_session_module_fk(apps, schema_editor):
    connection = schema_editor.connection
    if connection.vendor != "postgresql":
        return

    with connection.cursor() as cursor:
        cursor.execute(
            """
            SELECT c.conname
            FROM pg_constraint c
            JOIN pg_attribute a
              ON a.attrelid = c.conrelid
             AND a.attnum = ANY(c.conkey)
            WHERE c.conrelid = 'sessions'::regclass
              AND c.contype = 'f'
              AND a.attname = 'module_id'
            """
        )
        for (constraint_name,) in cursor.fetchall():
            cursor.execute(
                f"ALTER TABLE sessions DROP CONSTRAINT IF EXISTS {schema_editor.quote_name(constraint_name)}"
            )

        cursor.execute(
            "SELECT 1 FROM pg_constraint WHERE conname = %s AND conrelid = 'sessions'::regclass",
            [NEW_CONSTRAINT_NAME],
        )
        if not cursor.fetchone():
            cursor.execute(
                f"""
                ALTER TABLE sessions
                ADD CONSTRAINT {schema_editor.quote_name(NEW_CONSTRAINT_NAME)}
                FOREIGN KEY (module_id)
                REFERENCES class_modules(id)
                DEFERRABLE INITIALLY DEFERRED
                NOT VALID
                """
            )


def noop_reverse(apps, schema_editor):
    pass


class Migration(migrations.Migration):
    dependencies = [
        ("courses", "0010_alter_session_module"),
    ]

    operations = [
        migrations.RunPython(fix_session_module_fk, noop_reverse),
    ]
