from rest_framework_simplejwt.authentication import JWTAuthentication


class JWTAuthenticationWithActiveRole(JWTAuthentication):
    def get_user(self, validated_token):
        user = super().get_user(validated_token)
        user.active_role = validated_token.get("active_role", user.role)
        return user
