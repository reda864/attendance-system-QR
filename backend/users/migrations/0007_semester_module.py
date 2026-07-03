import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("users", "0006_student_email_phone"),
    ]

    operations = [
        migrations.SeparateDatabaseAndState(
            state_operations=[
                migrations.AddField(
                    model_name="classe",
                    name="code",
                    field=models.CharField(
                        blank=True,
                        default="",
                        help_text="Ex. SDIA",
                        max_length=20,
                        verbose_name="Code",
                    ),
                ),
            ],
            database_operations=[
                migrations.RunSQL(
                    sql="""
                        ALTER TABLE classes
                        ADD COLUMN IF NOT EXISTS code VARCHAR(20) NOT NULL DEFAULT '';
                    """,
                    reverse_sql=migrations.RunSQL.noop,
                ),
            ],
        ),
        migrations.AlterField(
            model_name="classe",
            name="academic_year",
            field=models.CharField(
                blank=True,
                default="",
                max_length=20,
                verbose_name="Année universitaire",
            ),
        ),
        migrations.AlterField(
            model_name="classe",
            name="field",
            field=models.CharField(
                blank=True,
                default="",
                max_length=100,
                verbose_name="Filière",
            ),
        ),
        migrations.AlterField(
            model_name="classe",
            name="level",
            field=models.CharField(
                blank=True,
                default="",
                max_length=50,
                verbose_name="Niveau",
            ),
        ),
        migrations.CreateModel(
            name="Semester",
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
                ("code", models.CharField(max_length=20, verbose_name="Code semestre")),
                (
                    "name",
                    models.CharField(
                        blank=True, default="", max_length=100, verbose_name="Libellé"
                    ),
                ),
                (
                    "order",
                    models.PositiveSmallIntegerField(default=0, verbose_name="Ordre"),
                ),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                (
                    "classe",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="semesters",
                        to="users.classe",
                        verbose_name="Classe",
                    ),
                ),
            ],
            options={
                "verbose_name": "Semestre",
                "verbose_name_plural": "Semestres",
                "db_table": "class_semesters",
                "ordering": ["order", "code"],
            },
        ),
        migrations.CreateModel(
            name="Module",
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
                (
                    "name",
                    models.CharField(max_length=200, verbose_name="Nom du module"),
                ),
                (
                    "code",
                    models.CharField(
                        blank=True, default="", max_length=50, verbose_name="Code"
                    ),
                ),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                (
                    "semester",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="modules",
                        to="users.semester",
                        verbose_name="Semestre",
                    ),
                ),
                (
                    "teacher",
                    models.ForeignKey(
                        limit_choices_to=models.Q(("role", "teacher"))
                        | models.Q(("is_also_teacher", True), ("role", "admin")),
                        on_delete=django.db.models.deletion.PROTECT,
                        related_name="teaching_modules",
                        to=settings.AUTH_USER_MODEL,
                        verbose_name="Enseignant",
                    ),
                ),
            ],
            options={
                "verbose_name": "Module",
                "verbose_name_plural": "Modules",
                "db_table": "class_modules",
                "ordering": ["name"],
            },
        ),
        migrations.AddConstraint(
            model_name="semester",
            constraint=models.UniqueConstraint(
                fields=("classe", "code"), name="uniq_semester_code_per_classe"
            ),
        ),
    ]
