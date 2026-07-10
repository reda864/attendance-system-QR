from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("users", "0009_fix_legacy_classe_columns_sql"),
    ]

    operations = [
        migrations.SeparateDatabaseAndState(
            database_operations=[
                migrations.RunSQL(
                    sql="""
                        ALTER TABLE users ADD COLUMN IF NOT EXISTS grade VARCHAR(100) NOT NULL DEFAULT '';
                        ALTER TABLE users ADD COLUMN IF NOT EXISTS phone VARCHAR(30) NOT NULL DEFAULT '';
                        ALTER TABLE users ADD COLUMN IF NOT EXISTS speciality VARCHAR(100) NOT NULL DEFAULT '';
                        UPDATE users SET grade = '' WHERE grade IS NULL;
                        UPDATE users SET phone = '' WHERE phone IS NULL;
                        UPDATE users SET speciality = '' WHERE speciality IS NULL;
                        ALTER TABLE users ALTER COLUMN grade SET DEFAULT '';
                        ALTER TABLE users ALTER COLUMN phone SET DEFAULT '';
                        ALTER TABLE users ALTER COLUMN speciality SET DEFAULT '';
                        ALTER TABLE users ALTER COLUMN grade SET NOT NULL;
                        ALTER TABLE users ALTER COLUMN phone SET NOT NULL;
                        ALTER TABLE users ALTER COLUMN speciality SET NOT NULL;
                    """,
                    reverse_sql=migrations.RunSQL.noop,
                ),
            ],
            state_operations=[
                migrations.AddField(
                    model_name="user",
                    name="grade",
                    field=models.CharField(blank=True, default="", max_length=100),
                ),
                migrations.AddField(
                    model_name="user",
                    name="phone",
                    field=models.CharField(blank=True, default="", max_length=30),
                ),
                migrations.AddField(
                    model_name="user",
                    name="speciality",
                    field=models.CharField(blank=True, default="", max_length=100),
                ),
            ],
        ),
    ]
