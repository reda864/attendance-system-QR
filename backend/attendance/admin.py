from django.contrib import admin

from .models import Attendance


@admin.register(Attendance)
class AttendanceAdmin(admin.ModelAdmin):
    list_display = ["student", "session", "validation_time"]
    list_filter = ["session__classe", "session__date"]
    search_fields = ["student__code_massar", "student__last_name"]
