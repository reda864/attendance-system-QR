import secrets
from datetime import datetime, time

from django.db import models
from django.utils import timezone

from users.roles import acting_as_admin, acting_as_teacher


class Session(models.Model):
    """Séance de cours : matière, enseignant, classe, date."""

    subject = models.CharField(max_length=200, verbose_name="Matière")
    teacher = models.ForeignKey(
        "users.User",
        on_delete=models.CASCADE,
        related_name="sessions",
        limit_choices_to=models.Q(role="teacher")
        | models.Q(role="admin", is_also_teacher=True),
    )
    classe = models.ForeignKey(
        "users.Classe",
        on_delete=models.CASCADE,
        related_name="sessions",
    )
    date = models.DateField()
    start_time = models.TimeField(default=time(8, 0), verbose_name="Heure de début")
    end_time = models.TimeField(default=time(18, 0), verbose_name="Heure de fin")
    qr_token = models.CharField(max_length=64, unique=True, blank=True, null=True)
    qr_session_id = models.CharField(max_length=64, blank=True, default="")
    qr_expires_at = models.DateTimeField(null=True, blank=True)
    attendance_radius_meters = models.PositiveIntegerField(default=50)
    location_latitude = models.DecimalField(
        max_digits=10, decimal_places=7, null=True, blank=True
    )
    location_longitude = models.DecimalField(
        max_digits=10, decimal_places=7, null=True, blank=True
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "sessions"
        ordering = ["-date"]

    def __str__(self):
        return f"{self.subject} — {self.classe} ({self.date})"

    def _session_window_bounds(self):
        tz = timezone.get_current_timezone()
        start = timezone.make_aware(datetime.combine(self.date, self.start_time), tz)
        end = timezone.make_aware(datetime.combine(self.date, self.end_time), tz)
        return start, end

    @property
    def is_within_session_window(self):
        now = timezone.now()
        start, end = self._session_window_bounds()
        return start <= now <= end

    @property
    def can_generate_qr(self):
        return self.is_active and self.is_within_session_window

    def generate_qr_token(
        self,
        expiry_minutes=20,
        attendance_radius_meters=50,
        latitude=None,
        longitude=None,
    ):
        from django.conf import settings

        self.qr_token = secrets.token_urlsafe(32)
        self.qr_session_id = secrets.token_urlsafe(16)
        minutes = expiry_minutes or getattr(
            settings, "QR_TOKEN_DEFAULT_EXPIRY_MINUTES", 20
        )
        self.qr_expires_at = timezone.now() + timezone.timedelta(minutes=minutes)
        self.attendance_radius_meters = attendance_radius_meters
        if latitude is not None:
            self.location_latitude = latitude
        if longitude is not None:
            self.location_longitude = longitude
        self.save(
            update_fields=[
                "qr_token",
                "qr_session_id",
                "qr_expires_at",
                "attendance_radius_meters",
                "location_latitude",
                "location_longitude",
            ]
        )

    @property
    def is_qr_valid(self):
        if not self.qr_token or not self.qr_expires_at:
            return False
        now = timezone.now()
        _, window_end = self._session_window_bounds()
        if now > window_end:
            return False
        return now < self.qr_expires_at

    def teacher_can_manage(self, user) -> bool:
        if acting_as_admin(user):
            return True
        if not acting_as_teacher(user):
            return False
        if self.teacher_id == user.id:
            return True
        return self.classe_id in user.get_assigned_class_ids()
