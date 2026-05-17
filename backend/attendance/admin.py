from django.contrib import admin

from .models import Attendance


@admin.register(Attendance)
class AttendanceAdmin(admin.ModelAdmin):
    list_display = ["student", "session", "validation_time", "ip_address", "device_id"]
    list_filter = ["session__course", "session__date"]
    search_fields = [
        "student__code_massar",
        "student__first_name",
        "student__last_name",
    ]
    readonly_fields = ["validation_time", "ip_address"]
