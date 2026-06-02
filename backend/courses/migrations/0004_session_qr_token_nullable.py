from django.db import migrations, models


def empty_qr_tokens_to_null(apps, schema_editor):
    Session = apps.get_model("courses", "Session")
    Session.objects.filter(qr_token="").update(qr_token=None)


class Migration(migrations.Migration):

    dependencies = [
        ("courses", "0003_refactor_sessions"),
    ]

    operations = [
        migrations.AlterField(
            model_name="session",
            name="qr_token",
            field=models.CharField(
                blank=True, max_length=64, null=True, unique=True
            ),
        ),
        migrations.RunPython(empty_qr_tokens_to_null, migrations.RunPython.noop),
    ]
