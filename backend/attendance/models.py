from django.db import models


class Attendance(models.Model):
    student = models.ForeignKey(
        "users.Student", on_delete=models.CASCADE, related_name="attendances"
    )
    session = models.ForeignKey(
        "courses.Session", on_delete=models.CASCADE, related_name="attendances"
    )
    validation_time = models.DateTimeField(auto_now_add=True)
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    device_id = models.CharField(max_length=255, blank=True, default="")

    class Meta:
        db_table = "attendance"
        unique_together = [("student", "session")]
        ordering = ["-validation_time"]

    def __str__(self):
        return f"{self.student} @ {self.session} - {self.validation_time}"
