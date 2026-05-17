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

        # Broadcast via WebSocket
        try:
            channel_layer = get_channel_layer()
            async_to_sync(channel_layer.group_send)(
                f"attendance_{session.id}",
                {
                    "type": "attendance_update",
                    "data": AttendanceSerializer(attendance).data,
                },
            )
        except Exception as e:
            logger.warning(f"WebSocket broadcast failed: {e}")

        return Response(
            AttendanceSerializer(attendance).data, status=status.HTTP_201_CREATED
        )


class SessionAttendanceListView(ListAPIView):
    serializer_class = AttendanceSerializer
    permission_classes = [IsAuthenticated, IsAdminOrTeacher]

    def get_queryset(self):
        session_id = self.kwargs["session_id"]
        return (
            Attendance.objects.select_related("student", "session__course")
            .filter(session_id=session_id)
            .order_by("-validation_time")
        )


class ExportAttendanceView(APIView):
    permission_classes = [IsAuthenticated, IsAdminOrTeacher]

    def get(self, request, session_id):
        try:
            session = Session.objects.select_related("course__teacher").get(
                pk=session_id
            )
        except Session.DoesNotExist:
            return Response(
                {"error": "Session not found."}, status=status.HTTP_404_NOT_FOUND
            )

        # Check ownership for teachers
        if request.user.role == "teacher" and session.course.teacher != request.user:
            return Response({"error": "Forbidden."}, status=status.HTTP_403_FORBIDDEN)

        attendances = Attendance.objects.select_related(
            "student", "session__course"
        ).filter(session=session)

        wb = openpyxl.Workbook()
        ws = wb.active
        ws.title = f"Attendance - {session.course.code}"

        # Header styling
        headers = [
            "#",
            "First Name",
            "Last Name",
            "Code Massar",
            "Field",
            "Course",
            "Session Date",
            "Validation Time",
            "IP Address",
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

        # Data rows
        for idx, att in enumerate(attendances, start=1):
            local_time = timezone.localtime(att.validation_time)
            ws.append(
                [
                    idx,
                    att.student.first_name,
                    att.student.last_name,
                    att.student.code_massar,
                    att.student.field,
                    session.course.title,
                    str(session.date),
                    local_time.strftime("%Y-%m-%d %H:%M:%S"),
                    att.ip_address or "",
                ]
            )

        # Auto column width
        for column in ws.columns:
            max_len = max((len(str(cell.value or "")) for cell in column), default=0)
            ws.column_dimensions[column[0].column_letter].width = max_len + 4

        buffer = BytesIO()
        wb.save(buffer)
        buffer.seek(0)

        filename = f"attendance_{session.course.code}_{session.date}.xlsx"
        response = HttpResponse(
            buffer.read(),
            content_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        )
        response["Content-Disposition"] = f'attachment; filename="{filename}"'
        logger.info(
            f"Exported attendance for session {session_id} by {request.user.email}"
        )
        return response
