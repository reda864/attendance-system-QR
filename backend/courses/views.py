import base64
import logging
from io import BytesIO

import qrcode
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from users.permissions import IsAdmin, IsAdminOrTeacher

from .models import Session
from .serializers import GenerateQRSerializer, SessionSerializer

logger = logging.getLogger(__name__)


class SessionViewSet(viewsets.ModelViewSet):
    serializer_class = SessionSerializer
    permission_classes = [IsAuthenticated, IsAdminOrTeacher]

    def get_queryset(self):
        user = self.request.user
        qs = Session.objects.select_related("teacher", "classe").all()

        if user.role == "teacher":
            qs = qs.filter(teacher=user) | qs.filter(classe__teachers=user)
            qs = qs.distinct()

        classe_id = self.request.query_params.get("classe")
        if classe_id:
            qs = qs.filter(classe_id=classe_id)
        teacher_id = self.request.query_params.get("teacher")
        if teacher_id:
            qs = qs.filter(teacher_id=teacher_id)
        return qs

    def perform_create(self, serializer):
        user = self.request.user
        if user.role == "teacher":
            serializer.save(teacher=user)
        else:
            serializer.save()

    def _check_session_access(self, request, session):
        if not session.teacher_can_manage(request.user):
            return False
        return True

    @action(detail=True, methods=["post"], url_path="generate-qr")
    def generate_qr(self, request, pk=None):
        session = self.get_object()

        if not self._check_session_access(request, session):
            return Response({"error": "Forbidden."}, status=status.HTTP_403_FORBIDDEN)

        if request.user.role == "teacher":
            if session.teacher_id != request.user.id:
                if not session.classe.teachers.filter(pk=request.user.pk).exists():
                    return Response(
                        {"error": "Vous ne pouvez générer un QR que pour vos classes."},
                        status=status.HTTP_403_FORBIDDEN,
                    )

        ser = GenerateQRSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        expiry = ser.validated_data["expiry_minutes"]

        session.generate_qr_token(expiry_minutes=expiry)

        qr = qrcode.QRCode(
            version=1,
            error_correction=qrcode.constants.ERROR_CORRECT_M,
            box_size=10,
            border=4,
        )
        qr.add_data(session.qr_token)
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
