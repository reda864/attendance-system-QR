import django.db.models.deletion
from django.db import migrations, models


def assign_default_classe_to_students(apps, schema_editor):
    Student = apps.get_model("users", "Student")
    Classe = apps.get_model("users", "Classe")

    default_classe, _ = Classe.objects.get_or_create(
        name="Classe par défaut",
        defaults={
            "level": "—",
            "field": "—",
            "academic_year": "2025-2026",
        },
    )
    Student.objects.filter(classe__isnull=True).update(classe=default_classe)


class Migration(migrations.Migration):

    dependencies = [
        ("users", "0002_classe_domain"),
        ("courses", "0003_refactor_sessions"),
    ]

    operations = [
        migrations.RunPython(
            assign_default_classe_to_students,
            migrations.RunPython.noop,
        ),
        migrations.AlterField(
            model_name="student",
            name="classe",
            field=models.ForeignKey(
                on_delete=django.db.models.deletion.PROTECT,
                related_name="students",
                to="users.classe",
            ),
        ),
    ]
