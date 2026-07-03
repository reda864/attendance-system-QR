from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin

from .models import Classe, Module, Semester, Student, User


@admin.register(Classe)
class ClasseAdmin(admin.ModelAdmin):
    list_display = ["name", "code", "level", "field", "academic_year", "created_at"]
    search_fields = ["name", "field"]
    list_filter = ["level", "academic_year"]


@admin.register(Semester)
class SemesterAdmin(admin.ModelAdmin):
    list_display = ["code", "name", "classe", "order", "created_at"]
    list_filter = ["classe"]
    search_fields = ["code", "name", "classe__name"]


@admin.register(Module)
class ModuleAdmin(admin.ModelAdmin):
    list_display = ["name", "code", "semester", "teacher", "created_at"]
    list_filter = ["semester__classe", "teacher"]
    search_fields = ["name", "code", "teacher__email"]


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display = ["email", "first_name", "last_name", "role", "is_also_teacher", "is_active"]
    list_filter = ["role", "is_also_teacher", "is_active"]
    filter_horizontal = ["assigned_classes"]
    fieldsets = (
        (None, {"fields": ("email", "password")}),
        ("Personal info", {"fields": ("first_name", "last_name", "role", "is_also_teacher")}),
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
