import secrets

from django.db import models
from django.utils import timezone


class Course(models.Model):
    title = models.CharField(max_length=200)
    code = models.CharField(max_length=50, unique=True)
    teacher = models.ForeignKey(
        "users.User",
        on_delete=models.CASCADE,
        related_name="courses",
        limit_choices_to={"role": "teacher"},
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "courses"
        ordering = ["title"]

    def __str__(self):
        return f"{self.code} — {self.title}"


class Session(models.Model):
    course = models.ForeignKey(
        Course, on_delete=models.CASCADE, related_name="sessions"
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
        return f"{self.course.code} — {self.date}"

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
