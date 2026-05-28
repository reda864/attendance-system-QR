import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


def migrate_sessions_from_courses(apps, schema_editor):
    Session = apps.get_model("courses", "Session")
    Course = apps.get_model("courses", "Course")
    Classe = apps.get_model("users", "Classe")

    default_classe, _ = Classe.objects.get_or_create(
        name="Classe par défaut",
        defaults={
            "level": "—",
            "field": "—",
            "academic_year": "2025-2026",
        },
    )

    for session in Session.objects.select_related("course").all():
        course = session.course
        session.subject = course.title
        session.teacher_id = course.teacher_id
        session.classe = default_classe
        session.save(update_fields=["subject", "teacher_id", "classe_id"])


class Migration(migrations.Migration):

    dependencies = [
        ("courses", "0002_initial"),
        ("users", "0002_classe_domain"),
    ]

    operations = [
        migrations.AddField(
            model_name="session",
            name="subject",
            field=models.CharField(max_length=200, null=True, verbose_name="Matière"),
        ),
        migrations.AddField(
            model_name="session",
            name="teacher",
            field=models.ForeignKey(
                limit_choices_to={"role": "teacher"},
                null=True,
                on_delete=django.db.models.deletion.CASCADE,
                related_name="sessions",
                to=settings.AUTH_USER_MODEL,
            ),
        ),
        migrations.AddField(
            model_name="session",
            name="classe",
            field=models.ForeignKey(
                null=True,
                on_delete=django.db.models.deletion.CASCADE,
                related_name="sessions",
                to="users.classe",
            ),
        ),
        migrations.RunPython(
            migrate_sessions_from_courses,
            migrations.RunPython.noop,
        ),
        migrations.RemoveField(
            model_name="session",
            name="course",
        ),
        migrations.DeleteModel(
            name="Course",
        ),
        migrations.AlterField(
            model_name="session",
            name="subject",
            field=models.CharField(max_length=200, verbose_name="Matière"),
        ),
        migrations.AlterField(
            model_name="session",
            name="teacher",
            field=models.ForeignKey(
                limit_choices_to={"role": "teacher"},
                on_delete=django.db.models.deletion.CASCADE,
                related_name="sessions",
                to=settings.AUTH_USER_MODEL,
            ),
        ),
        migrations.AlterField(
            model_name="session",
            name="classe",
            field=models.ForeignKey(
                on_delete=django.db.models.deletion.CASCADE,
                related_name="sessions",
                to="users.classe",
            ),
        ),
    ]
