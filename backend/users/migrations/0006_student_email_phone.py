from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("users", "0005_repair_classes_columns"),
    ]

    operations = [
        migrations.SeparateDatabaseAndState(
            state_operations=[
                migrations.AddField(
                    model_name="student",
                    name="email",
                    field=models.CharField(blank=True, default="", max_length=254),
                ),
                migrations.AddField(
                    model_name="student",
                    name="phone",
                    field=models.CharField(blank=True, default="", max_length=30),
                ),
            ],
            database_operations=[],
        ),
    ]
