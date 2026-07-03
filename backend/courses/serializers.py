from rest_framework import serializers

from attendance.utils import round_coordinate

from users.roles import acting_as_teacher

from .models import Session


class SessionSerializer(serializers.ModelSerializer):
    teacher_name = serializers.CharField(source="teacher.full_name", read_only=True)
    classe_name = serializers.CharField(source="classe.name", read_only=True)
    classe_field = serializers.CharField(source="classe.field", read_only=True)
    is_qr_valid = serializers.BooleanField(read_only=True)
    is_within_session_window = serializers.BooleanField(read_only=True)
    can_generate_qr = serializers.BooleanField(read_only=True)

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        request = self.context.get("request")
        user = getattr(request, "user", None) if request else None
        if user and getattr(user, "is_authenticated", False) and acting_as_teacher(user):
            self.fields["teacher"].required = False
            self.fields["teacher"].read_only = True

    class Meta:
        model = Session
        fields = [
            "id",
            "subject",
            "teacher",
            "teacher_name",
            "classe",
            "classe_name",
            "classe_field",
            "date",
            "start_time",
            "end_time",
            "qr_token",
            "qr_session_id",
            "qr_expires_at",
            "attendance_radius_meters",
            "location_latitude",
            "location_longitude",
            "is_active",
            "is_qr_valid",
            "is_within_session_window",
            "can_generate_qr",
            "created_at",
        ]
        read_only_fields = [
            "id",
            "qr_token",
            "qr_session_id",
            "qr_expires_at",
            "attendance_radius_meters",
            "location_latitude",
            "location_longitude",
            "is_qr_valid",
            "is_within_session_window",
            "can_generate_qr",
            "created_at",
        ]

    def validate(self, data):
        start_time = data.get("start_time", getattr(self.instance, "start_time", None))
        end_time = data.get("end_time", getattr(self.instance, "end_time", None))
        if start_time and end_time and end_time <= start_time:
            raise serializers.ValidationError(
                {"end_time": "L'heure de fin doit être après l'heure de début."}
            )

        teacher = data.get("teacher", getattr(self.instance, "teacher", None))
        classe = data.get("classe", getattr(self.instance, "classe", None))
        request = self.context.get("request")
        if request and acting_as_teacher(request.user) and classe:
            assigned = request.user.assigned_classes.filter(pk=classe.pk).exists()
            has_sessions = Session.objects.filter(
                classe=classe, teacher=request.user
            ).exists()
            if not assigned and not has_sessions:
                raise serializers.ValidationError(
                    {"classe": "Vous n'êtes pas affecté à cette classe."}
                )
            if teacher and teacher.id != request.user.id:
                raise serializers.ValidationError(
                    {"teacher": "Vous ne pouvez pas assigner une autre enseignant."}
                )
        return data


class GenerateQRSerializer(serializers.Serializer):
    expiry_minutes = serializers.IntegerField(min_value=1, max_value=120, default=20)
    attendance_radius_meters = serializers.IntegerField(
        min_value=20, max_value=200, default=50
    )
    latitude = serializers.DecimalField(
        max_digits=10, decimal_places=7, required=False, allow_null=True
    )
    longitude = serializers.DecimalField(
        max_digits=10, decimal_places=7, required=False, allow_null=True
    )

    def validate_latitude(self, value):
        return round_coordinate(value)

    def validate_longitude(self, value):
        return round_coordinate(value)
