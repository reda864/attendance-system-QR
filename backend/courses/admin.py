from django.contrib import admin

from .models import Course, Session


@admin.register(Course)
class CourseAdmin(admin.ModelAdmin):
    list_display = ["code", "title", "teacher", "created_at"]
    search_fields = ["code", "title", "teacher__email"]
    list_filter = ["teacher"]


@admin.register(Session)
class SessionAdmin(admin.ModelAdmin):
    list_display = ["course", "date", "is_active", "qr_expires_at", "is_qr_valid"]
    list_filter = ["is_active", "course__teacher"]
    search_fields = ["course__code"]
    readonly_fields = ["qr_token", "qr_expires_at", "created_at"]
