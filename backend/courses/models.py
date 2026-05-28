import secrets

from django.db import models
from django.utils import timezone


class Session(models.Model):
    """Séance de cours : matière, enseignant, classe, date."""

    subject = models.CharField(max_length=200, verbose_name="Matière")
    teacher = models.ForeignKey(
        "users.User",
        on_delete=models.CASCADE,
        related_name="sessions",
        limit_choices_to={"role": "teacher"},
    )
    classe = models.ForeignKey(
        "users.Classe",
        on_delete=models.CASCADE,
        related_name="sessions",
    )
    date = models.DateField()
    qr_token = models.CharField(max_length=64, unique=True, blank=True)
    qr_expires_at = models.DateTimeField(null=True, blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "sessions"
        ordering = ["-date"]

    def __str__(self):
        return f"{self.subject} — {self.classe} ({self.date})"

    def generate_qr_token(self, expiry_minutes=20):
        from django.conf import settings

        self.qr_token = secrets.token_urlsafe(32)
        self.qr_expires_at = timezone.now() + timezone.timedelta(
            minutes=getattr(settings, "QR_TOKEN_DEFAULT_EXPIRY_MINUTES", expiry_minutes)
        )
        self.save(update_fields=["qr_token", "qr_expires_at"])

    @property
    def is_qr_valid(self):
        if not self.qr_token or not self.qr_expires_at:
            return False
        return timezone.now() < self.qr_expires_at

    def teacher_can_manage(self, user) -> bool:
        if user.role == "admin":
            return True
        if user.role != "teacher":
            return False
        if self.teacher_id == user.id:
            return True
        return self.classe_id in user.assigned_classes.values_list("pk", flat=True)
