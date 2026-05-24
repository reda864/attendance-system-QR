import base64
import logging
from io import BytesIO

import qrcode
from django.conf import settings
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from users.permissions import IsAdmin, IsAdminOrTeacher

from .models import Course, Session
from .serializers import (
    CourseSerializer,
    GenerateQRSerializer,
    SessionQRResponseSerializer,
    SessionSerializer,
)

logger = logging.getLogger(__name__)


class CourseViewSet(viewsets.ModelViewSet):
    serializer_class = CourseSerializer
    permission_classes = [IsAuthenticated, IsAdminOrTeacher]

    def get_queryset(self):
        user = self.request.user
        if user.role == "admin":
            return Course.objects.select_related("teacher").all()
        return Course.objects.select_related("teacher").filter(teacher=user)

    def perform_create(self, serializer):
        if self.request.user.role == "teacher":
            serializer.save(teacher=self.request.user)
        else:
            serializer.save()


class SessionViewSet(viewsets.ModelViewSet):
    serializer_class = SessionSerializer
    permission_classes = [IsAuthenticated, IsAdminOrTeacher]

    def get_queryset(self):
        user = self.request.user
        if user.role == "admin":
            qs = Session.objects.select_related("course__teacher").all()
        else:
            qs = Session.objects.select_related("course__teacher").filter(
                course__teacher=user
            )

        course_id = self.request.query_params.get("course")
        if course_id:
            qs = qs.filter(course_id=course_id)
        return qs

    @action(detail=True, methods=["post"], url_path="generate-qr")
    def generate_qr(self, request, pk=None):
        session = self.get_object()

        # Check ownership for teachers
        if request.user.role == "teacher" and session.course.teacher != request.user:
            return Response({"error": "Forbidden."}, status=status.HTTP_403_FORBIDDEN)

        ser = GenerateQRSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        expiry = ser.validated_data["expiry_minutes"]

        session.generate_qr_token(expiry_minutes=expiry)

        # Generate QR image
        qr_data = session.qr_token
        qr = qrcode.QRCode(
            version=1,
            error_correction=qrcode.constants.ERROR_CORRECT_M,
            box_size=10,
            border=4,
        )
        qr.add_data(qr_data)
        qr.make(fit=True)
        img = qr.make_image(fill_color="black", back_color="white")
        buffer = BytesIO()
        img.save(buffer, format="PNG")
        buffer.seek(0)
        b64 = base64.b64encode(buffer.read()).decode("utf-8")

        logger.info(
            f"QR generated for session {session.id} by {request.user.email}, "
            f"expires at {session.qr_expires_at}"
        )

        return Response(
            {
                "qr_token": session.qr_token,
                "qr_expires_at": session.qr_expires_at,
                "qr_image_base64": f"data:image/png;base64,{b64}",
            },
            status=status.HTTP_200_OK,
        )
