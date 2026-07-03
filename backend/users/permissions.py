from rest_framework.permissions import BasePermission

from .roles import acting_as_admin, get_active_role


class IsAdmin(BasePermission):
    """Allows access only when acting as admin."""

    def has_permission(self, request, view):
        return bool(
            request.user
            and request.user.is_authenticated
            and acting_as_admin(request.user)
        )


class IsAdminOrTeacher(BasePermission):
    """Allows access when acting as admin or teacher."""

    def has_permission(self, request, view):
        return bool(
            request.user
            and request.user.is_authenticated
            and get_active_role(request.user) in ("admin", "teacher")
        )


class IsStudent(BasePermission):
    """Allows access only to users with role='student'."""

    def has_permission(self, request, view):
        return bool(
            request.user
            and request.user.is_authenticated
            and request.user.role == "student"
        )
