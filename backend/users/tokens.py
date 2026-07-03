from rest_framework_simplejwt.tokens import RefreshToken


class AppRefreshToken(RefreshToken):
    @classmethod
    def for_user(cls, user, active_role=None):
        token = super().for_user(user)
        token["role"] = user.role
        token["email"] = user.email
        token["active_role"] = active_role or user.role
        return token
