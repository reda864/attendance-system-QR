from django.contrib import admin

from .models import Session


@admin.register(Session)
class SessionAdmin(admin.ModelAdmin):
    list_display = [
        "subject",
        "classe",
        "teacher",
        "date",
        "start_time",
        "end_time",
        "is_active",
        "is_qr_valid",
    ]
    list_filter = ["is_active", "classe", "teacher"]
    search_fields = ["subject", "classe__name"]
    readonly_fields = ["qr_token", "qr_expires_at", "created_at"]
