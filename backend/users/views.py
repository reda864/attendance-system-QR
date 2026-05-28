import logging
from typing import Type, cast

from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.serializers import BaseSerializer
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken

from .models import Classe, Student, User
from .permissions import IsAdmin, IsAdminOrTeacher
from .serializers import (
    ClasseSerializer,
    LoginSerializer,
    StudentSerializer,
    UserCreateSerializer,
    UserSerializer,
    UserUpdateSerializer,
)

logger = logging.getLogger(__name__)


class LoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user: User = serializer.validated_data["user"]
        refresh = RefreshToken.for_user(user)
        refresh.payload["role"] = user.role
        refresh.payload["email"] = user.email
        logger.info(f"User {user.email} logged in successfully.")
        return Response(
            {
                "refresh": str(refresh),
                "access": str(refresh.access_token),
                "user": UserSerializer(user).data,
            }
        )


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
        if user.role == "teacher":
            return qs.filter(teachers=user).distinct()
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
        return Response(UserSerializer(user).data)
