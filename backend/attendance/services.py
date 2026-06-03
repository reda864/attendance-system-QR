import logging
from decimal import Decimal
from typing import Optional, Tuple

from courses.models import Session
from users.models import Student

from .models import Attendance, SuspiciousAttempt
from .utils import compute_device_fingerprint, haversine_distance_meters

logger = logging.getLogger(__name__)


class AttendanceService:
    @staticmethod
    def _log_suspicious(
        attempt_type: str,
        error_message: str,
        session: Optional[Session] = None,
        qr_token: str = "",
        code_massar: str = "",
        first_name: str = "",
        last_name: str = "",
        ip_address: str = None,
        device_id: str = "",
        device_fingerprint: str = "",
        device_info: str = "",
        latitude=None,
        longitude=None,
    ):
        SuspiciousAttempt.objects.create(
            session=session,
            attempt_type=attempt_type,
            qr_token=qr_token,
            qr_session_id=getattr(session, "qr_session_id", "") or "",
            code_massar=code_massar,
            first_name=first_name,
            last_name=last_name,
            ip_address=ip_address,
            device_id=device_id,
            device_fingerprint=device_fingerprint,
            device_info=device_info,
            latitude=latitude,
            longitude=longitude,
            error_message=error_message,
        )
        logger.warning(
            "Suspicious attendance attempt [%s]: %s (token=%s, massar=%s, ip=%s)",
            attempt_type,
            error_message,
            qr_token[:8] if qr_token else "",
            code_massar,
            ip_address,
        )

    @staticmethod
    def _check_geofence(session: Session, latitude, longitude) -> None:
        if session.location_latitude is None or session.location_longitude is None:
            return

        if latitude is None or longitude is None:
            raise ValueError(
                "La localisation GPS est requise pour valider la présence."
            )

        lat = float(latitude)
        lon = float(longitude)
        center_lat = float(session.location_latitude)
        center_lon = float(session.location_longitude)
        distance = haversine_distance_meters(center_lat, center_lon, lat, lon)
        radius = session.attendance_radius_meters or 50

        if distance > radius:
            raise ValueError(
                "Vous êtes en dehors de la zone de présence autorisée."
            )

    @staticmethod
    def _check_duplicate_device(
        session: Session,
        ip_address: str,
        device_id: str,
        device_fingerprint: str,
    ) -> None:
        if ip_address and Attendance.objects.filter(
            session=session, ip_address=ip_address
        ).exists():
            raise ValueError(
                "Cet appareil a déjà été utilisé pour marquer la présence "
                "pour cette séance."
            )

        if device_id and Attendance.objects.filter(
            session=session, device_id=device_id
        ).exists():
            raise ValueError(
                "Cet appareil a déjà été utilisé pour marquer la présence "
                "pour cette séance."
            )

        if device_fingerprint and Attendance.objects.filter(
            session=session, device_fingerprint=device_fingerprint
        ).exists():
            raise ValueError(
                "Cet appareil a déjà été utilisé pour marquer la présence "
                "pour cette séance."
            )

    @staticmethod
    def validate_attendance(
        qr_token: str,
        first_name: str,
        last_name: str,
        code_massar: str,
        ip_address: str = None,
        device_id: str = "",
        device_fingerprint: str = "",
        device_info: str = "",
        latitude=None,
        longitude=None,
        user_agent: str = "",
    ) -> Tuple[Attendance, Session]:
        fingerprint = device_fingerprint or compute_device_fingerprint(
            device_id, ip_address or "", user_agent, device_info
        )

        try:
            session = Session.objects.select_related("teacher", "classe").get(
                qr_token=qr_token
            )
        except Session.DoesNotExist:
            AttendanceService._log_suspicious(
                SuspiciousAttempt.ATTEMPT_INVALID_TOKEN,
                "Invalid QR token.",
                qr_token=qr_token,
                code_massar=code_massar,
                first_name=first_name,
                last_name=last_name,
                ip_address=ip_address,
                device_id=device_id,
                device_fingerprint=fingerprint,
                device_info=device_info,
                latitude=latitude,
                longitude=longitude,
            )
            raise ValueError("Code QR invalide.")

        if not session.is_qr_valid:
            AttendanceService._log_suspicious(
                SuspiciousAttempt.ATTEMPT_EXPIRED_QR,
                "QR code has expired.",
                session=session,
                qr_token=qr_token,
                code_massar=code_massar,
                first_name=first_name,
                last_name=last_name,
                ip_address=ip_address,
                device_id=device_id,
                device_fingerprint=fingerprint,
                device_info=device_info,
                latitude=latitude,
                longitude=longitude,
            )
            raise ValueError(
                "Le code QR a expiré. Demandez à votre enseignant d'en générer un nouveau."
            )

        if not session.is_active:
            AttendanceService._log_suspicious(
                SuspiciousAttempt.ATTEMPT_INACTIVE_SESSION,
                "Session is no longer active.",
                session=session,
                qr_token=qr_token,
                code_massar=code_massar,
                first_name=first_name,
                last_name=last_name,
                ip_address=ip_address,
                device_id=device_id,
                device_fingerprint=fingerprint,
                device_info=device_info,
                latitude=latitude,
                longitude=longitude,
            )
            raise ValueError("Cette séance n'est plus active.")

        try:
            student = Student.objects.select_related("classe").get(
                code_massar=code_massar
            )
        except Student.DoesNotExist:
            AttendanceService._log_suspicious(
                SuspiciousAttempt.ATTEMPT_UNKNOWN_STUDENT,
                f"Student with code massar '{code_massar}' not found.",
                session=session,
                qr_token=qr_token,
                code_massar=code_massar,
                first_name=first_name,
                last_name=last_name,
                ip_address=ip_address,
                device_id=device_id,
                device_fingerprint=fingerprint,
                device_info=device_info,
                latitude=latitude,
                longitude=longitude,
            )
            raise ValueError(
                f"Étudiant avec le code Massar '{code_massar}' introuvable. "
                "Contactez votre enseignant pour vous inscrire."
            )

        if student.classe_id != session.classe_id:
            AttendanceService._log_suspicious(
                SuspiciousAttempt.ATTEMPT_CLASS_MISMATCH,
                "Student does not belong to session class.",
                session=session,
                qr_token=qr_token,
                code_massar=code_massar,
                first_name=first_name,
                last_name=last_name,
                ip_address=ip_address,
                device_id=device_id,
                device_fingerprint=fingerprint,
                device_info=device_info,
                latitude=latitude,
                longitude=longitude,
            )
            raise ValueError(
                "Vous n'appartenez pas à la classe de cette séance."
            )

        name_matches = (
            student.first_name.strip().lower() == first_name.strip().lower()
            and student.last_name.strip().lower() == last_name.strip().lower()
        )
        if not name_matches:
            AttendanceService._log_suspicious(
                SuspiciousAttempt.ATTEMPT_IDENTITY_MISMATCH,
                "Student name does not match records.",
                session=session,
                qr_token=qr_token,
                code_massar=code_massar,
                first_name=first_name,
                last_name=last_name,
                ip_address=ip_address,
                device_id=device_id,
                device_fingerprint=fingerprint,
                device_info=device_info,
                latitude=latitude,
                longitude=longitude,
            )
            raise ValueError(
                "Le nom de l'étudiant ne correspond pas aux enregistrements. "
                "Vérifiez votre prénom et nom."
            )

        if Attendance.objects.filter(student=student, session=session).exists():
            AttendanceService._log_suspicious(
                SuspiciousAttempt.ATTEMPT_DUPLICATE_STUDENT,
                "Attendance already recorded for this session.",
                session=session,
                qr_token=qr_token,
                code_massar=code_massar,
                first_name=first_name,
                last_name=last_name,
                ip_address=ip_address,
                device_id=device_id,
                device_fingerprint=fingerprint,
                device_info=device_info,
                latitude=latitude,
                longitude=longitude,
            )
            raise ValueError(
                "Présence déjà enregistrée pour cette séance."
            )

        try:
            AttendanceService._check_duplicate_device(
                session, ip_address, device_id, fingerprint
            )
        except ValueError as exc:
            AttendanceService._log_suspicious(
                SuspiciousAttempt.ATTEMPT_DUPLICATE_DEVICE,
                str(exc),
                session=session,
                qr_token=qr_token,
                code_massar=code_massar,
                first_name=first_name,
                last_name=last_name,
                ip_address=ip_address,
                device_id=device_id,
                device_fingerprint=fingerprint,
                device_info=device_info,
                latitude=latitude,
                longitude=longitude,
            )
            raise

        try:
            AttendanceService._check_geofence(session, latitude, longitude)
        except ValueError as exc:
            AttendanceService._log_suspicious(
                SuspiciousAttempt.ATTEMPT_GEOFENCE,
                str(exc),
                session=session,
                qr_token=qr_token,
                code_massar=code_massar,
                first_name=first_name,
                last_name=last_name,
                ip_address=ip_address,
                device_id=device_id,
                device_fingerprint=fingerprint,
                device_info=device_info,
                latitude=latitude,
                longitude=longitude,
            )
            raise

        lat_value = Decimal(str(latitude)) if latitude is not None else None
        lon_value = Decimal(str(longitude)) if longitude is not None else None

        attendance = Attendance.objects.create(
            student=student,
            session=session,
            ip_address=ip_address,
            device_id=device_id,
            device_fingerprint=fingerprint,
            device_info=device_info,
            latitude=lat_value,
            longitude=lon_value,
            qr_session_id=session.qr_session_id or "",
            attendance_status=Attendance.STATUS_CONFIRMED,
        )

        logger.info(
            "Attendance recorded: student=%s session=%s subject=%s qr_session=%s",
            student.code_massar,
            session.id,
            session.subject,
            session.qr_session_id,
        )

        return attendance, session

    @staticmethod
    def validate_attendance_for_user(
        qr_token: str,
        user,
        ip_address: str = None,
        device_id: str = "",
        device_fingerprint: str = "",
        device_info: str = "",
        latitude=None,
        longitude=None,
        user_agent: str = "",
    ) -> Tuple[Attendance, Session]:
        try:
            student = Student.objects.select_related("classe").get(user=user)
        except Student.DoesNotExist:
            raise ValueError(
                "Profil étudiant introuvable. Contactez votre enseignant."
            )

        return AttendanceService.validate_attendance(
            qr_token=qr_token,
            first_name=student.first_name,
            last_name=student.last_name,
            code_massar=student.code_massar,
            ip_address=ip_address,
            device_id=device_id,
            device_fingerprint=device_fingerprint,
            device_info=device_info,
            latitude=latitude,
            longitude=longitude,
            user_agent=user_agent,
        )
