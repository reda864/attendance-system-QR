from rest_framework import serializers

from .models import Session


class SessionSerializer(serializers.ModelSerializer):
    teacher_name = serializers.CharField(source="teacher.full_name", read_only=True)
    classe_name = serializers.CharField(source="classe.name", read_only=True)
    classe_field = serializers.CharField(source="classe.field", read_only=True)
    is_qr_valid = serializers.BooleanField(read_only=True)

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
            "qr_token",
            "qr_expires_at",
            "is_active",
            "is_qr_valid",
            "created_at",
        ]
        read_only_fields = [
            "id",
            "qr_token",
            "qr_expires_at",
            "is_qr_valid",
            "created_at",
        ]

    def validate(self, data):
        teacher = data.get("teacher", getattr(self.instance, "teacher", None))
        classe = data.get("classe", getattr(self.instance, "classe", None))
        request = self.context.get("request")
        if request and request.user.role == "teacher" and classe:
            if not request.user.assigned_classes.filter(pk=classe.pk).exists():
                if teacher and teacher.id != request.user.id:
                    raise serializers.ValidationError(
                        {"classe": "Vous n'êtes pas affecté à cette classe."}
                    )
        return data


class GenerateQRSerializer(serializers.Serializer):
    expiry_minutes = serializers.IntegerField(min_value=1, max_value=120, default=20)
