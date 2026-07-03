import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("users", "0007_semester_module"),
        ("courses", "0006_session_start_end_time"),
    ]

    operations = [
        migrations.AddField(
            model_name="session",
            name="module",
            field=models.ForeignKey(
                blank=True,
                db_column="class_module_id",
                null=True,
                on_delete=django.db.models.deletion.PROTECT,
                related_name="sessions",
                to="users.module",
                verbose_name="Module",
            ),
        ),
    ]
