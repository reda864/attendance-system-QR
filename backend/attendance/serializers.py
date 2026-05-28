from rest_framework import serializers

from .models import Attendance


class AttendanceSerializer(serializers.ModelSerializer):
    student_name = serializers.SerializerMethodField()
    student_code_massar = serializers.CharField(
        source="student.code_massar", read_only=True
    )
    classe_name = serializers.CharField(
        source="student.classe.name", read_only=True
    )
    session_date = serializers.DateField(source="session.date", read_only=True)
    subject = serializers.CharField(source="session.subject", read_only=True)
    classe_session = serializers.CharField(source="session.classe.name", read_only=True)
    teacher_name = serializers.SerializerMethodField()

    class Meta:
        model = Attendance
        fields = [
            "id",
            "student",
            "student_name",
            "student_code_massar",
            "classe_name",
            "session",
            "session_date",
            "subject",
            "classe_session",
            "teacher_name",
            "validation_time",
            "ip_address",
            "device_id",
        ]
        read_only_fields = ["id", "validation_time", "ip_address"]

    def get_student_name(self, obj):
        return f"{obj.student.first_name} {obj.student.last_name}"

    def get_teacher_name(self, obj):
        teacher = obj.session.teacher
        return teacher.full_name


class ValidateAttendanceSerializer(serializers.Serializer):
    qr_token = serializers.CharField(max_length=100)
    first_name = serializers.CharField(max_length=100)
    last_name = serializers.CharField(max_length=100)
    code_massar = serializers.CharField(max_length=50)
    device_id = serializers.CharField(max_length=255, required=False, default="")
