import logging

from courses.models import Session
from django.utils import timezone
from users.models import Student

from .models import Attendance

logger = logging.getLogger(__name__)


class AttendanceService:
    @staticmethod
    def validate_attendance(
        qr_token: str,
        first_name: str,
        last_name: str,
        code_massar: str,
        ip_address: str = None,
        device_id: str = "",
    ):
        # 1. Validate the QR token
        try:
            session = Session.objects.select_related("course__teacher").get(
                qr_token=qr_token
            )
        except Session.DoesNotExist:
            raise ValueError("Invalid QR token.")

        if not session.is_qr_valid:
            raise ValueError(
                "QR code has expired. Please ask your teacher to regenerate."
            )

        if not session.is_active:
            raise ValueError("This session is no longer active.")

        # 2. Find the student by code_massar
        try:
            student = Student.objects.get(code_massar=code_massar)
        except Student.DoesNotExist:
            raise ValueError(
                f"Student with code massar '{code_massar}' not found. "
                "Please contact your teacher to register you."
            )

        # 3. Optionally verify name matches (soft check)
        name_matches = (
            student.first_name.strip().lower() == first_name.strip().lower()
            and student.last_name.strip().lower() == last_name.strip().lower()
        )
        if not name_matches:
            raise ValueError(
                "Student name does not match records. "
                "Please check your first name and last name."
            )

        # 4. Check for duplicate attendance
        if Attendance.objects.filter(student=student, session=session).exists():
            raise ValueError("Attendance already recorded for this session.")

        # 5. Create attendance record
        attendance = Attendance.objects.create(
            student=student,
            session=session,
            ip_address=ip_address,
            device_id=device_id,
        )

        logger.info(
            f"Attendance recorded: student={student.code_massar} "
            f"session={session.id} course={session.course.code}"
        )

        return attendance, session
