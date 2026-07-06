from django.db import migrations, models


def ensure_session_type_column(apps, schema_editor):
    table_name = "sessions"
    column_name = "session_type"
    connection = schema_editor.connection

    existing_columns = {
        column.name
        for column in connection.introspection.get_table_description(
            connection.cursor(), table_name
        )
    }

    if column_name not in existing_columns:
        Session = apps.get_model("courses", "Session")
        field = models.CharField(max_length=40, default="course")
        field.set_attributes_from_name(column_name)
        schema_editor.add_field(Session, field)

    if connection.vendor == "postgresql":
        with connection.cursor() as cursor:
            cursor.execute(
                "UPDATE sessions SET session_type = %s WHERE session_type IS NULL",
                ["course"],
            )
            cursor.execute(
                "ALTER TABLE sessions ALTER COLUMN session_type SET DEFAULT %s",
                ["course"],
            )
            cursor.execute(
                "ALTER TABLE sessions ALTER COLUMN session_type SET NOT NULL"
            )
    elif connection.vendor == "sqlite":
        # SQLite cannot alter column defaults/nullability in place. The model default
        # is enough for new rows; this backfills existing rows if the column exists.
        with connection.cursor() as cursor:
            cursor.execute(
                "UPDATE sessions SET session_type = ? WHERE session_type IS NULL",
                ["course"],
            )


def noop_reverse(apps, schema_editor):
    pass


class Migration(migrations.Migration):
    dependencies = [
        ("courses", "0008_alter_session_teacher"),
    ]

    operations = [
        migrations.SeparateDatabaseAndState(
            database_operations=[
                migrations.RunPython(ensure_session_type_column, noop_reverse),
            ],
            state_operations=[
                migrations.AddField(
                    model_name="session",
                    name="session_type",
                    field=models.CharField(default="course", max_length=40),
                ),
            ],
        ),
    ]
