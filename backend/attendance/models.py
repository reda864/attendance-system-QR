from django.db import models


class Attendance(models.Model):
    STATUS_CONFIRMED = "confirmed"
    STATUS_REJECTED = "rejected"
    STATUS_CHOICES = [
        (STATUS_CONFIRMED, "Confirmed"),
        (STATUS_REJECTED, "Rejected"),
    ]

    student = models.ForeignKey(
        "users.Student", on_delete=models.CASCADE, related_name="attendances"
    )
    session = models.ForeignKey(
        "courses.Session", on_delete=models.CASCADE, related_name="attendances"
    )
    validation_time = models.DateTimeField(auto_now_add=True)
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    device_id = models.CharField(max_length=255, blank=True, default="")
    device_fingerprint = models.CharField(max_length=64, blank=True, default="")
    device_info = models.TextField(blank=True, default="")
    latitude = models.DecimalField(
        max_digits=10, decimal_places=7, null=True, blank=True
    )
    longitude = models.DecimalField(
        max_digits=10, decimal_places=7, null=True, blank=True
    )
    qr_session_id = models.CharField(max_length=64, blank=True, default="")
    attendance_status = models.CharField(
        max_length=20, choices=STATUS_CHOICES, default=STATUS_CONFIRMED
    )

    class Meta:
        db_table = "attendance"
        unique_together = [("student", "session")]
        ordering = ["-validation_time"]

    def __str__(self):
        return f"{self.student} @ {self.session} - {self.validation_time}"


class SuspiciousAttempt(models.Model):
    ATTEMPT_DUPLICATE_STUDENT = "duplicate_student"
    ATTEMPT_DUPLICATE_DEVICE = "duplicate_device"
    ATTEMPT_GEOFENCE = "geofence_violation"
    ATTEMPT_EXPIRED_QR = "expired_qr"
    ATTEMPT_INVALID_TOKEN = "invalid_token"
    ATTEMPT_INACTIVE_SESSION = "inactive_session"
    ATTEMPT_IDENTITY_MISMATCH = "identity_mismatch"
    ATTEMPT_CLASS_MISMATCH = "class_mismatch"
    ATTEMPT_UNKNOWN_STUDENT = "unknown_student"
    ATTEMPT_OTHER = "other"

    ATTEMPT_TYPE_CHOICES = [
        (ATTEMPT_DUPLICATE_STUDENT, "Duplicate student"),
        (ATTEMPT_DUPLICATE_DEVICE, "Duplicate device"),
        (ATTEMPT_GEOFENCE, "Geofence violation"),
        (ATTEMPT_EXPIRED_QR, "Expired QR"),
        (ATTEMPT_INVALID_TOKEN, "Invalid token"),
        (ATTEMPT_INACTIVE_SESSION, "Inactive session"),
        (ATTEMPT_IDENTITY_MISMATCH, "Identity mismatch"),
        (ATTEMPT_CLASS_MISMATCH, "Class mismatch"),
        (ATTEMPT_UNKNOWN_STUDENT, "Unknown student"),
        (ATTEMPT_OTHER, "Other"),
    ]

    session = models.ForeignKey(
        "courses.Session",
        on_delete=models.CASCADE,
        related_name="suspicious_attempts",
        null=True,
        blank=True,
    )
    attempt_type = models.CharField(max_length=40, choices=ATTEMPT_TYPE_CHOICES)
    qr_token = models.CharField(max_length=100, blank=True, default="")
    qr_session_id = models.CharField(max_length=64, blank=True, default="")
    code_massar = models.CharField(max_length=50, blank=True, default="")
    first_name = models.CharField(max_length=100, blank=True, default="")
    last_name = models.CharField(max_length=100, blank=True, default="")
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    device_id = models.CharField(max_length=255, blank=True, default="")
    device_fingerprint = models.CharField(max_length=64, blank=True, default="")
    device_info = models.TextField(blank=True, default="")
    latitude = models.DecimalField(
        max_digits=10, decimal_places=7, null=True, blank=True
    )
    longitude = models.DecimalField(
        max_digits=10, decimal_places=7, null=True, blank=True
    )
    error_message = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "suspicious_attempts"
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.attempt_type} @ {self.created_at}"
