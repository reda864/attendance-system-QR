import base64
import logging
from io import BytesIO

import qrcode
from django.conf import settings
from django.utils import timezone
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from config.site_url import build_attend_url
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
            session = serializer.save(teacher=user)
        else:
            session = serializer.save()
        teacher = session.teacher
        if teacher.role == "teacher":
            teacher.assigned_classes.add(session.classe)

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

        if not session.can_generate_qr:
            current = timezone.now()
            start, end = session._session_window_bounds()
            if current < start:
                msg = (
                    f"La séance commence à {session.start_time.strftime('%H:%M')}. "
                    "Le QR sera disponible pendant le créneau horaire."
                )
            else:
                msg = (
                    f"Le créneau horaire est terminé "
                    f"({session.start_time.strftime('%H:%M')}–"
                    f"{session.end_time.strftime('%H:%M')}). "
                    "Consultez les statistiques ou exportez les présences."
                )
            return Response({"error": msg}, status=status.HTTP_400_BAD_REQUEST)

        ser = GenerateQRSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        expiry = ser.validated_data["expiry_minutes"]
        radius = ser.validated_data["attendance_radius_meters"]
        latitude = ser.validated_data.get("latitude")
        longitude = ser.validated_data.get("longitude")

        session.generate_qr_token(
            expiry_minutes=expiry,
            attendance_radius_meters=radius,
            latitude=latitude,
            longitude=longitude,
        )

        qr_url = build_attend_url(request, session.qr_token)

        qr = qrcode.QRCode(
            version=1,
            error_correction=qrcode.constants.ERROR_CORRECT_M,
            box_size=10,
            border=4,
        )
        qr.add_data(qr_url)
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
                "qr_session_id": session.qr_session_id,
                "qr_expires_at": session.qr_expires_at,
                "qr_url": qr_url,
                "attendance_radius_meters": session.attendance_radius_meters,
                "location_latitude": session.location_latitude,
                "location_longitude": session.location_longitude,
                "qr_image_base64": f"data:image/png;base64,{b64}",
            },
            status=status.HTTP_200_OK,
        )
