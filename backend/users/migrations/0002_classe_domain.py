import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("users", "0001_initial"),
    ]

    operations = [
        migrations.CreateModel(
            name="Classe",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name="ID",
                    ),
                ),
                ("name", models.CharField(max_length=100, verbose_name="Nom de la classe")),
                ("level", models.CharField(max_length=50, verbose_name="Niveau")),
                ("field", models.CharField(max_length=100, verbose_name="Filière")),
                (
                    "academic_year",
                    models.CharField(max_length=20, verbose_name="Année universitaire"),
                ),
                ("created_at", models.DateTimeField(auto_now_add=True)),
            ],
            options={
                "verbose_name": "Classe",
                "verbose_name_plural": "Classes",
                "db_table": "classes",
                "ordering": ["name", "academic_year"],
            },
        ),
        migrations.AddField(
            model_name="user",
            name="assigned_classes",
            field=models.ManyToManyField(
                blank=True,
                help_text="Classes assignées (enseignants uniquement).",
                related_name="teachers",
                to="users.classe",
            ),
        ),
        migrations.AddField(
            model_name="student",
            name="user",
            field=models.OneToOneField(
                blank=True,
                limit_choices_to={"role": "student"},
                null=True,
                on_delete=django.db.models.deletion.CASCADE,
                related_name="student_profile",
                to=settings.AUTH_USER_MODEL,
            ),
        ),
        migrations.AddField(
            model_name="student",
            name="classe",
            field=models.ForeignKey(
                null=True,
                on_delete=django.db.models.deletion.PROTECT,
                related_name="students",
                to="users.classe",
            ),
        ),
        migrations.RemoveField(
            model_name="student",
            name="field",
        ),
        migrations.AlterField(
            model_name="user",
            name="role",
            field=models.CharField(
                choices=[
                    ("admin", "Admin"),
                    ("teacher", "Enseignant"),
                    ("student", "Étudiant"),
                ],
                default="teacher",
                max_length=20,
            ),
        ),
    ]
