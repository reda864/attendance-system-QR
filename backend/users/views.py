import logging
from typing import TYPE_CHECKING, Type, cast

from rest_framework import viewsets
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.serializers import BaseSerializer
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken

from .models import Student, User
from .permissions import IsAdmin, IsAdminOrTeacher
from .serializers import (
    LoginSerializer,
    StudentSerializer,
    UserCreateSerializer,
    UserSerializer,
)

if TYPE_CHECKING:
    pass

logger = logging.getLogger(__name__)


class LoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user: User = serializer.validated_data["user"]
        refresh = RefreshToken.for_user(user)
        # Embed custom claims into the refresh token payload
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
    queryset = User.objects.all().order_by("-created_at")
    permission_classes = [IsAuthenticated, IsAdmin]

    def get_serializer_class(self) -> Type[BaseSerializer]:
        if self.action == "create":
            return UserCreateSerializer
        return UserSerializer


class StudentViewSet(viewsets.ModelViewSet):
    queryset = Student.objects.all().order_by("last_name")
    serializer_class = StudentSerializer
    permission_classes = [IsAuthenticated, IsAdminOrTeacher]


class MeView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = cast(User, request.user)
        return Response(UserSerializer(user).data)
