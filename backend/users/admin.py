from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin

from .models import Classe, Student, User


@admin.register(Classe)
class ClasseAdmin(admin.ModelAdmin):
    list_display = ["name", "level", "field", "academic_year", "created_at"]
    search_fields = ["name", "field"]
    list_filter = ["level", "academic_year"]


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display = ["email", "first_name", "last_name", "role", "is_active"]
    list_filter = ["role", "is_active"]
    filter_horizontal = ["assigned_classes"]
    fieldsets = (
        (None, {"fields": ("email", "password")}),
        ("Personal info", {"fields": ("first_name", "last_name", "role")}),
        ("Classes", {"fields": ("assigned_classes",)}),
        (
            "Permissions",
            {
                "fields": (
                    "is_active",
                    "is_staff",
                    "is_superuser",
                    "groups",
                    "user_permissions",
                )
            },
        ),
    )
    add_fieldsets = (
        (
            None,
            {
                "classes": ("wide",),
                "fields": (
                    "email",
                    "first_name",
                    "last_name",
                    "role",
                    "password1",
                    "password2",
                ),
            },
        ),
    )
    search_fields = ["email", "first_name", "last_name"]
    ordering = ["email"]


@admin.register(Student)
class StudentAdmin(admin.ModelAdmin):
    list_display = ["first_name", "last_name", "code_massar", "classe"]
    list_filter = ["classe"]
    search_fields = ["first_name", "last_name", "code_massar"]
