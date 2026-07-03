"""Helpers for the stored role vs. the active (switched) role in JWT."""


def get_active_role(user) -> str:
    return getattr(user, "active_role", None) or user.role


def acting_as_admin(user) -> bool:
    return get_active_role(user) == "admin"


def acting_as_teacher(user) -> bool:
    return get_active_role(user) == "teacher"


def can_switch_to(user, role: str) -> bool:
    return role in user.available_roles
