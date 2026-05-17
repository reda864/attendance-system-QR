from rest_framework.permissions import BasePermission


class IsAdmin(BasePermission):
    """Allows access only to users with role='admin'."""

    def has_permission(self, request, view):
        return bool(
            request.user
            and request.user.is_authenticated
            and request.user.role == "admin"
        )


class IsAdminOrTeacher(BasePermission):
    """Allows access to admin and teacher roles."""

    def has_permission(self, request, view):
        return bool(
            request.user
            and request.user.is_authenticated
            and request.user.role in ("admin", "teacher")
        )


class IsStudent(BasePermission):
    """Allows access only to users with role='student'."""

    def has_permission(self, request, view):
        return bool(
            request.user
            and request.user.is_authenticated
            and request.user.role == "student"
        )
