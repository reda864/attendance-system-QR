from rest_framework import serializers

from .models import Attendance


class AttendanceSerializer(serializers.ModelSerializer):
    student_name = serializers.SerializerMethodField()
    student_code_massar = serializers.CharField(
        source="student.code_massar", read_only=True
    )
    student_field = serializers.CharField(source="student.field", read_only=True)
    session_date = serializers.DateField(source="session.date", read_only=True)
    course_title = serializers.CharField(source="session.course.title", read_only=True)
    course_code = serializers.CharField(source="session.course.code", read_only=True)

    class Meta:
        model = Attendance
        fields = [
            "id",
            "student",
            "student_name",
            "student_code_massar",
            "student_field",
            "session",
            "session_date",
            "course_title",
            "course_code",
            "validation_time",
            "ip_address",
            "device_id",
        ]
        read_only_fields = ["id", "validation_time", "ip_address"]

    def get_student_name(self, obj):
        return f"{obj.student.first_name} {obj.student.last_name}"


class ValidateAttendanceSerializer(serializers.Serializer):
    qr_token = serializers.CharField(max_length=100)
    first_name = serializers.CharField(max_length=100)
    last_name = serializers.CharField(max_length=100)
    code_massar = serializers.CharField(max_length=50)
    device_id = serializers.CharField(max_length=255, required=False, default="")
