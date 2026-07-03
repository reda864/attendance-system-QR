import logging
from io import BytesIO

import openpyxl
from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer
from django.http import HttpResponse
from django.utils import timezone
from rest_framework import status
from rest_framework.generics import ListAPIView
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.views import APIView

from courses.models import Session
from users.permissions import IsAdminOrTeacher, IsStudent
from users.roles import acting_as_teacher

from .models import Attendance, SuspiciousAttempt
from .serializers import (
    AttendanceSerializer,
    SuspiciousAttemptSerializer,
    ValidateAppAttendanceSerializer,
    ValidateAttendanceSerializer,
)
from .services import AttendanceService

logger = logging.getLogger(__name__)


def get_client_ip(request):
    x_forwarded_for = request.META.get("HTTP_X_FORWARDED_FOR")
    if x_forwarded_for:
        return x_forwarded_for.split(",")[0].strip()
    return request.META.get("REMOTE_ADDR")


def get_user_agent(request):
    return request.META.get("HTTP_USER_AGENT", "")


def broadcast_attendance(attendance, session):
    try:
        channel_layer = get_channel_layer()
        payload = {
            "type": "attendance_update",
            "data": AttendanceSerializer(attendance).data,
        }
        async_to_sync(channel_layer.group_send)(f"attendance_{session.id}", payload)
        async_to_sync(channel_layer.group_send)("attendance_admin", payload)
        teacher_id = session.teacher_id
        if teacher_id:
            async_to_sync(channel_layer.group_send)(
                f"attendance_teacher_{teacher_id}", payload
            )
    except Exception as e:
        logger.warning(f"WebSocket broadcast failed: {e}")


class ValidateAttendanceThrottle(ScopedRateThrottle):
    scope = "validate_attendance"


class ValidateAttendanceView(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [ValidateAttendanceThrottle]

    def post(self, request):
        serializer = ValidateAttendanceSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        ip_address = get_client_ip(request)
        user_agent = get_user_agent(request)

        try:
            attendance, session = AttendanceService.validate_attendance(
                qr_token=data["qr_token"],
                first_name=data["first_name"],
                last_name=data["last_name"],
                code_massar=data["code_massar"],
                ip_address=ip_address,
                device_id=data.get("device_id", ""),
                device_fingerprint=data.get("device_fingerprint", ""),
                device_info=data.get("device_info", ""),
                latitude=data.get("latitude"),
                longitude=data.get("longitude"),
                user_agent=user_agent,
            )
        except ValueError as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)

        broadcast_attendance(attendance, session)

        return Response(
            AttendanceSerializer(attendance).data, status=status.HTTP_201_CREATED
        )


class ValidateAppAttendanceView(APIView):
    """Authenticated mobile app validation — uses linked student profile."""

    permission_classes = [IsAuthenticated, IsStudent]
    throttle_classes = [ValidateAttendanceThrottle]

    def post(self, request):
        serializer = ValidateAppAttendanceSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        ip_address = get_client_ip(request)
        user_agent = get_user_agent(request)

        try:
            attendance, session = AttendanceService.validate_attendance_for_user(
                qr_token=data["qr_token"],
                user=request.user,
                ip_address=ip_address,
                device_id=data.get("device_id", ""),
                device_fingerprint=data.get("device_fingerprint", ""),
                device_info=data.get("device_info", ""),
                latitude=data.get("latitude"),
                longitude=data.get("longitude"),
                user_agent=user_agent,
            )
        except ValueError as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)

        broadcast_attendance(attendance, session)

        return Response(
            AttendanceSerializer(attendance).data, status=status.HTTP_201_CREATED
        )


class QrSessionInfoView(APIView):
    """Public endpoint to verify QR token validity before showing the web form."""

    permission_classes = [AllowAny]

    def get(self, request):
        token = request.query_params.get("token", "").strip()
        if not token:
            return Response(
                {"error": "Token requis."}, status=status.HTTP_400_BAD_REQUEST
            )

        try:
            session = Session.objects.select_related("teacher", "classe").get(
                qr_token=token
            )
        except Session.DoesNotExist:
            return Response(
                {"valid": False, "error": "Code QR invalide."},
                status=status.HTTP_404_NOT_FOUND,
            )

        return Response(
            {
                "valid": session.is_qr_valid and session.is_active,
                "expired": not session.is_qr_valid,
                "session_id": session.id,
                "subject": session.subject,
                "classe": session.classe.name,
                "teacher": session.teacher.full_name,
                "date": session.date,
                "qr_expires_at": session.qr_expires_at,
                "qr_session_id": session.qr_session_id,
                "attendance_radius_meters": session.attendance_radius_meters,
                "requires_location": session.location_latitude is not None,
            }
        )


class MyAttendanceListView(ListAPIView):
    serializer_class = AttendanceSerializer
    permission_classes = [IsAuthenticated, IsStudent]

    def get_queryset(self):
        user = self.request.user
        return Attendance.objects.select_related(
            "student__classe",
            "session__teacher",
            "session__classe",
        ).filter(student__user=user).order_by("-validation_time")


class AllAttendanceListView(ListAPIView):
    serializer_class = AttendanceSerializer
    permission_classes = [IsAuthenticated, IsAdminOrTeacher]

    def get_queryset(self):
        qs = Attendance.objects.select_related(
            "student__classe",
            "session__teacher",
            "session__classe",
        ).order_by("-validation_time")

        user = self.request.user
        if acting_as_teacher(user):
            qs = qs.filter(session__teacher=user)

        session_id = self.request.query_params.get("session")
        classe_id = self.request.query_params.get("classe")
        if session_id:
            qs = qs.filter(session_id=session_id)
        if classe_id:
            qs = qs.filter(session__classe_id=classe_id)

        return qs


class SessionAttendanceListView(ListAPIView):
    serializer_class = AttendanceSerializer
    permission_classes = [IsAuthenticated, IsAdminOrTeacher]

    def get_queryset(self):
        session_id = self.kwargs["session_id"]
        user = self.request.user

        if acting_as_teacher(user):
            try:
                session = Session.objects.select_related("teacher", "classe").get(
                    pk=session_id
                )
            except Session.DoesNotExist:
                return Attendance.objects.none()
            if not session.teacher_can_manage(user):
                return Attendance.objects.none()

        return Attendance.objects.select_related(
            "student__classe", "session__teacher", "session__classe"
        ).filter(session_id=session_id).order_by("-validation_time")


class SessionSuspiciousAttemptsView(ListAPIView):
    serializer_class = SuspiciousAttemptSerializer
    permission_classes = [IsAuthenticated, IsAdminOrTeacher]

    def get_queryset(self):
        session_id = self.kwargs["session_id"]
        user = self.request.user

        try:
            session = Session.objects.get(pk=session_id)
        except Session.DoesNotExist:
            return SuspiciousAttempt.objects.none()

        if acting_as_teacher(user) and not session.teacher_can_manage(user):
            return SuspiciousAttempt.objects.none()

        return SuspiciousAttempt.objects.filter(session_id=session_id).order_by(
            "-created_at"
        )


class SessionStatsView(APIView):
    permission_classes = [IsAuthenticated, IsAdminOrTeacher]

    def get(self, request, session_id):
        try:
            session = Session.objects.select_related("classe").get(pk=session_id)
        except Session.DoesNotExist:
            return Response(
                {"error": "Session not found."}, status=status.HTTP_404_NOT_FOUND
            )

        if not session.teacher_can_manage(request.user):
            return Response({"error": "Forbidden."}, status=status.HTTP_403_FORBIDDEN)

        attendances = Attendance.objects.filter(session=session)
        suspicious = SuspiciousAttempt.objects.filter(session=session)
        total_students = session.classe.students.count()

        duplicate_attempts = suspicious.filter(
            attempt_type__in=[
                SuspiciousAttempt.ATTEMPT_DUPLICATE_STUDENT,
                SuspiciousAttempt.ATTEMPT_DUPLICATE_DEVICE,
            ]
        ).count()

        geofence_violations = suspicious.filter(
            attempt_type=SuspiciousAttempt.ATTEMPT_GEOFENCE
        ).count()

        devices_used = (
            attendances.exclude(device_fingerprint="")
            .values("device_fingerprint")
            .distinct()
            .count()
        )

        return Response(
            {
                "session_id": session.id,
                "subject": session.subject,
                "total_students_in_class": total_students,
                "attendance_count": attendances.count(),
                "attendance_rate": round(
                    (attendances.count() / total_students * 100)
                    if total_students
                    else 0,
                    1,
                ),
                "duplicate_attempts": duplicate_attempts,
                "geofence_violations": geofence_violations,
                "suspicious_attempts_total": suspicious.count(),
                "unique_devices": devices_used,
                "locations": [
                    {
                        "student_name": f"{a.student.first_name} {a.student.last_name}",
                        "code_massar": a.student.code_massar,
                        "latitude": a.latitude,
                        "longitude": a.longitude,
                        "validation_time": a.validation_time,
                    }
                    for a in attendances.filter(
                        latitude__isnull=False, longitude__isnull=False
                    )
                ],
            }
        )


class ExportAttendanceView(APIView):
    permission_classes = [IsAuthenticated, IsAdminOrTeacher]

    def get(self, request, session_id):
        try:
            session = Session.objects.select_related("teacher", "classe").get(
                pk=session_id
            )
        except Session.DoesNotExist:
            return Response(
                {"error": "Session not found."}, status=status.HTTP_404_NOT_FOUND
            )

        if not session.teacher_can_manage(request.user):
            return Response({"error": "Forbidden."}, status=status.HTTP_403_FORBIDDEN)

        attendances = Attendance.objects.select_related(
            "student__classe", "session"
        ).filter(session=session)

        wb = openpyxl.Workbook()
        ws = wb.active
        ws.title = f"Présence - {session.subject[:20]}"

        headers = [
            "#",
            "Prénom",
            "Nom",
            "Code Massar",
            "Classe",
            "Matière",
            "Date séance",
            "Heure validation",
            "Adresse IP",
            "Empreinte appareil",
            "Latitude",
            "Longitude",
            "Statut",
            "QR Session ID",
        ]
        ws.append(headers)

        from openpyxl.styles import Alignment, Font, PatternFill

        header_font = Font(bold=True, color="FFFFFF")
        header_fill = PatternFill(
            start_color="1F4E79", end_color="1F4E79", fill_type="solid"
        )
        for cell in ws[1]:
            cell.font = header_font
            cell.fill = header_fill
            cell.alignment = Alignment(horizontal="center")

        for idx, att in enumerate(attendances, start=1):
            local_time = timezone.localtime(att.validation_time)
            ws.append(
                [
                    idx,
                    att.student.first_name,
                    att.student.last_name,
                    att.student.code_massar,
                    att.student.classe.name,
                    session.subject,
                    str(session.date),
                    local_time.strftime("%Y-%m-%d %H:%M:%S"),
                    att.ip_address or "",
                    att.device_fingerprint or att.device_id or "",
                    str(att.latitude) if att.latitude is not None else "",
                    str(att.longitude) if att.longitude is not None else "",
                    att.attendance_status,
                    att.qr_session_id,
                ]
            )

        for column in ws.columns:
            max_len = max((len(str(cell.value or "")) for cell in column), default=0)
            ws.column_dimensions[column[0].column_letter].width = max_len + 4

        buffer = BytesIO()
        wb.save(buffer)
        buffer.seek(0)

        safe_subject = "".join(c if c.isalnum() else "_" for c in session.subject)[:30]
        filename = f"presence_{safe_subject}_{session.date}.xlsx"
        response = HttpResponse(
            buffer.read(),
            content_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        )
        response["Content-Disposition"] = f'attachment; filename="{filename}"'
        logger.info(
            f"Exported attendance for session {session_id} by {request.user.email}"
        )
        return response
