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
from rest_framework.views import APIView

from courses.models import Session
from users.permissions import IsAdminOrTeacher

from .models import Attendance
from .serializers import AttendanceSerializer, ValidateAttendanceSerializer
from .services import AttendanceService

logger = logging.getLogger(__name__)


def get_client_ip(request):
    x_forwarded_for = request.META.get("HTTP_X_FORWARDED_FOR")
    if x_forwarded_for:
        return x_forwarded_for.split(",")[0].strip()
    return request.META.get("REMOTE_ADDR")


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


class ValidateAttendanceView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = ValidateAttendanceSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        ip_address = get_client_ip(request)

        try:
            attendance, session = AttendanceService.validate_attendance(
                qr_token=data["qr_token"],
                first_name=data["first_name"],
                last_name=data["last_name"],
                code_massar=data["code_massar"],
                ip_address=ip_address,
                device_id=data.get("device_id", ""),
            )
        except ValueError as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)

        broadcast_attendance(attendance, session)

        return Response(
            AttendanceSerializer(attendance).data, status=status.HTTP_201_CREATED
        )


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
        if user.role == "teacher":
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

        if user.role == "teacher":
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
