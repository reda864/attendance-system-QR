import datetime

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("courses", "0005_session_attendance_radius_meters_and_more"),
    ]

    operations = [
        migrations.AddField(
            model_name="session",
            name="start_time",
            field=models.TimeField(
                default=datetime.time(8, 0),
                verbose_name="Heure de début",
            ),
        ),
        migrations.AddField(
            model_name="session",
            name="end_time",
            field=models.TimeField(
                default=datetime.time(18, 0),
                verbose_name="Heure de fin",
            ),
        ),
    ]
