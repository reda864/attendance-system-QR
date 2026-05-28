import logging

from courses.models import Session
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
        try:
            session = Session.objects.select_related("teacher", "classe").get(
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

        try:
            student = Student.objects.select_related("classe").get(
                code_massar=code_massar
            )
        except Student.DoesNotExist:
            raise ValueError(
                f"Student with code massar '{code_massar}' not found. "
                "Please contact your teacher to register you."
            )

        if student.classe_id != session.classe_id:
            raise ValueError(
                "Vous n'appartenez pas à la classe de cette séance."
            )

        name_matches = (
            student.first_name.strip().lower() == first_name.strip().lower()
            and student.last_name.strip().lower() == last_name.strip().lower()
        )
        if not name_matches:
            raise ValueError(
                "Student name does not match records. "
                "Please check your first name and last name."
            )

        if Attendance.objects.filter(student=student, session=session).exists():
            raise ValueError("Attendance already recorded for this session.")

        if ip_address and Attendance.objects.filter(
            session=session, ip_address=ip_address
        ).exists():
            raise ValueError(
                "This device has already been used to mark attendance for this session."
            )

        if device_id and Attendance.objects.filter(
            session=session, device_id=device_id
        ).exists():
            raise ValueError(
                "This device has already been used to mark attendance for this session."
            )

        attendance = Attendance.objects.create(
            student=student,
            session=session,
            ip_address=ip_address,
            device_id=device_id,
        )

        logger.info(
            f"Attendance recorded: student={student.code_massar} "
            f"session={session.id} subject={session.subject}"
        )

        return attendance, session
