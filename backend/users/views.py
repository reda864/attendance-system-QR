import logging
from typing import Type, cast

from django.db.models import Q
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.serializers import BaseSerializer
from rest_framework.views import APIView
from rest_framework_simplejwt.views import TokenRefreshView

from .models import Classe, Student, User
from .permissions import IsAdmin, IsAdminOrTeacher
from .roles import acting_as_teacher, get_active_role
from .serializers import (
    ClasseSerializer,
    LoginSerializer,
    StudentSerializer,
    SwitchRoleSerializer,
    UserCreateSerializer,
    UserSerializer,
    UserUpdateSerializer,
)
from .tokens import AppRefreshToken

logger = logging.getLogger(__name__)


def _auth_response(user: User, active_role: str | None = None) -> dict:
    refresh = AppRefreshToken.for_user(user, active_role=active_role)
    user.active_role = refresh["active_role"]
    return {
        "refresh": str(refresh),
        "access": str(refresh.access_token),
        "user": UserSerializer(user).data,
    }


class LoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user: User = serializer.validated_data["user"]
        logger.info(f"User {user.email} logged in successfully.")
        return Response(_auth_response(user))


class SwitchRoleView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = SwitchRoleSerializer(
            data=request.data, context={"request": request}
        )
        serializer.is_valid(raise_exception=True)
        user = cast(User, request.user)
        new_role = serializer.validated_data["role"]
        logger.info(f"User {user.email} switched active role to {new_role}.")
        return Response(_auth_response(user, active_role=new_role))


class TokenRefreshView(TokenRefreshView):
    """Preserves custom JWT claims (active_role) when refreshing tokens."""

    def post(self, request, *args, **kwargs):
        response = super().post(request, *args, **kwargs)
        if response.status_code != 200:
            return response

        refresh_token = request.data.get("refresh")
        if not refresh_token:
            return response

        try:
            token = AppRefreshToken(refresh_token)
            active_role = token.payload.get("active_role")
        except Exception:
            return response

        if not active_role:
            return response

        access = AppRefreshToken(refresh_token).access_token
        data = response.data
        if isinstance(data, dict) and "access" in data:
            data["access"] = str(access)
            if "refresh" in data:
                new_refresh = AppRefreshToken(data["refresh"])
                new_refresh["active_role"] = active_role
                data["refresh"] = str(new_refresh)
            response.data = data
        return response


class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.prefetch_related("assigned_classes").order_by("-created_at")
    permission_classes = [IsAuthenticated, IsAdmin]

    def get_serializer_class(self) -> Type[BaseSerializer]:
        if self.action == "create":
            return UserCreateSerializer
        if self.action in ("update", "partial_update"):
            return UserUpdateSerializer
        return UserSerializer

    @action(detail=True, methods=["post"], url_path="toggle-active")
    def toggle_active(self, request, pk=None):
        user = self.get_object()
        if user == request.user:
            return Response(
                {"error": "Vous ne pouvez pas désactiver votre propre compte."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        user.is_active = not user.is_active
        user.save(update_fields=["is_active"])
        return Response(UserSerializer(user).data)


class ClasseViewSet(viewsets.ModelViewSet):
    queryset = Classe.objects.all().order_by("name", "academic_year")
    serializer_class = ClasseSerializer
    permission_classes = [IsAuthenticated, IsAdmin]

    def get_permissions(self):
        if self.action in ("list", "retrieve"):
            return [IsAuthenticated(), IsAdminOrTeacher()]
        return super().get_permissions()

    def get_queryset(self):
        qs = super().get_queryset()
        user = self.request.user
        if acting_as_teacher(user):
            return qs.filter(
                Q(teachers=user) | Q(sessions__teacher=user)
            ).distinct()
        return qs


class StudentViewSet(viewsets.ModelViewSet):
    queryset = Student.objects.select_related("classe", "user").order_by("last_name")
    serializer_class = StudentSerializer
    permission_classes = [IsAuthenticated, IsAdminOrTeacher]

    def get_permissions(self):
        if self.action in ("create", "update", "partial_update", "destroy"):
            return [IsAuthenticated(), IsAdmin()]
        return [IsAuthenticated(), IsAdminOrTeacher()]


class MeView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = cast(User, request.user)
        user = User.objects.prefetch_related("assigned_classes").select_related(
            "student_profile__classe"
        ).get(pk=user.pk)
        user.active_role = get_active_role(request.user)
        return Response(UserSerializer(user).data)
