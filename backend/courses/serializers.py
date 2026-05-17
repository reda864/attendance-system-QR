import base64
from io import BytesIO

import qrcode
from django.conf import settings
from rest_framework import serializers

from .models import Course, Session


class CourseSerializer(serializers.ModelSerializer):
    teacher_name = serializers.CharField(source="teacher.get_full_name", read_only=True)

    class Meta:
        model = Course
        fields = ["id", "title", "code", "teacher", "teacher_name", "created_at"]
        read_only_fields = ["id", "created_at"]


class SessionSerializer(serializers.ModelSerializer):
    course_title = serializers.CharField(source="course.title", read_only=True)
    course_code = serializers.CharField(source="course.code", read_only=True)
    is_qr_valid = serializers.BooleanField(read_only=True)

    class Meta:
        model = Session
        fields = [
            "id",
            "course",
            "course_title",
            "course_code",
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


class GenerateQRSerializer(serializers.Serializer):
    expiry_minutes = serializers.IntegerField(min_value=1, max_value=120, default=20)


class SessionQRResponseSerializer(serializers.Serializer):
    qr_token = serializers.CharField()
    qr_expires_at = serializers.DateTimeField()
    qr_image_base64 = serializers.CharField()
