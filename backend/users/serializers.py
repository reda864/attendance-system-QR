from django.contrib.auth import authenticate
from rest_framework import serializers

from .models import Classe, Student, User


class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True, style={"input_type": "password"})

    def validate(self, data):
        email = data.get("email", "").lower().strip()
        password = data.get("password", "")

        if not email or not password:
            raise serializers.ValidationError("Email and password are required.")

        user = authenticate(
            request=self.context.get("request"), username=email, password=password
        )
        if user is None:
            raise serializers.ValidationError("Invalid email or password.")

        if not user.is_active:
            raise serializers.ValidationError("This account has been deactivated.")

        data["user"] = user
        return data


class UserSerializer(serializers.ModelSerializer):
    full_name = serializers.SerializerMethodField()
    student_profile = serializers.SerializerMethodField()
    active_role = serializers.SerializerMethodField()
    available_roles = serializers.SerializerMethodField()
    assigned_class_ids = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            "id",
            "first_name",
            "last_name",
            "full_name",
            "email",
            "role",
            "is_also_teacher",
            "active_role",
            "available_roles",
            "is_active",
            "assigned_class_ids",
            "student_profile",
            "created_at",
        ]
        read_only_fields = [
            "id",
            "created_at",
            "active_role",
            "available_roles",
            "assigned_class_ids",
        ]

    def get_active_role(self, obj):
        return getattr(obj, "active_role", None) or obj.role

    def get_available_roles(self, obj):
        return obj.available_roles

    def get_full_name(self, obj):
        return obj.full_name

    def get_assigned_class_ids(self, obj):
        return obj.get_assigned_class_ids()

    def get_student_profile(self, obj):
        if obj.role != "student":
            return None
        try:
            profile = obj.student_profile
        except Student.DoesNotExist:
            return None
        classe_name = None
        if profile.classe_id:
            try:
                classe_name = profile.classe.name
            except Exception:
                pass
        return {
            "id": profile.id,
            "first_name": profile.first_name,
            "last_name": profile.last_name,
            "code_massar": profile.code_massar,
            "classe_id": profile.classe_id,
            "classe_name": classe_name,
        }


class UserCreateSerializer(serializers.ModelSerializer):
    password = serializers.CharField(
        write_only=True, min_length=8, style={"input_type": "password"}
    )
    password_confirm = serializers.CharField(
        write_only=True,
        required=False,
        allow_blank=True,
        style={"input_type": "password"},
    )
    assigned_class_ids = serializers.PrimaryKeyRelatedField(
        source="assigned_classes",
        many=True,
        queryset=Classe.objects.all(),
        required=False,
    )

    class Meta:
        model = User
        fields = [
            "first_name",
            "last_name",
            "email",
            "role",
            "is_also_teacher",
            "password",
            "password_confirm",
            "assigned_class_ids",
        ]

    def validate(self, data):
        password = data.get("password")
        password_confirm = data.get("password_confirm")
        if password_confirm is not None and password != password_confirm:
            raise serializers.ValidationError(
                {"password_confirm": "Passwords do not match."}
            )
        data.pop("password_confirm", None)
        assigned = data.get("assigned_classes", [])
        role = data.get("role", "teacher")
        is_also_teacher = data.get("is_also_teacher", False)
        can_have_classes = role == "teacher" or (role == "admin" and is_also_teacher)
        if not can_have_classes and assigned:
            raise serializers.ValidationError(
                {"assigned_class_ids": "Seuls les enseignants peuvent avoir des classes."}
            )
        if role != "admin" and is_also_teacher:
            raise serializers.ValidationError(
                {"is_also_teacher": "Seuls les administrateurs peuvent être aussi enseignants."}
            )
        return data

    def create(self, validated_data):
        assigned_classes = validated_data.pop("assigned_classes", [])
        password = validated_data.pop("password")
        user = User(**validated_data)
        user.set_password(password)
        user.save()
        if assigned_classes:
            user.assigned_classes.set(assigned_classes)
        return user


class UserUpdateSerializer(serializers.ModelSerializer):
    password = serializers.CharField(
        write_only=True,
        min_length=8,
        required=False,
        allow_blank=True,
        style={"input_type": "password"},
    )
    assigned_class_ids = serializers.PrimaryKeyRelatedField(
        source="assigned_classes",
        many=True,
        queryset=Classe.objects.all(),
        required=False,
    )

    class Meta:
        model = User
        fields = [
            "first_name",
            "last_name",
            "email",
            "role",
            "is_also_teacher",
            "is_active",
            "password",
            "assigned_class_ids",
        ]

    def validate(self, data):
        role = data.get("role", getattr(self.instance, "role", None))
        is_also_teacher = data.get(
            "is_also_teacher", getattr(self.instance, "is_also_teacher", False)
        )
        assigned = data.get("assigned_classes")
        can_have_classes = role == "teacher" or (role == "admin" and is_also_teacher)
        if assigned is not None and not can_have_classes and assigned:
            raise serializers.ValidationError(
                {"assigned_class_ids": "Seuls les enseignants peuvent avoir des classes."}
            )
        if role != "admin" and is_also_teacher:
            raise serializers.ValidationError(
                {"is_also_teacher": "Seuls les administrateurs peuvent être aussi enseignants."}
            )
        return data

    def update(self, instance, validated_data):
        assigned_classes = validated_data.pop("assigned_classes", None)
        password = validated_data.pop("password", None)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        if password:
            instance.set_password(password)
        instance.save()
        if assigned_classes is not None:
            instance.assigned_classes.set(assigned_classes)
        return instance


class SwitchRoleSerializer(serializers.Serializer):
    role = serializers.ChoiceField(choices=["admin", "teacher"])

    def validate_role(self, value):
        user = self.context["request"].user
        if value not in user.available_roles:
            raise serializers.ValidationError(
                "Vous ne pouvez pas basculer vers ce rôle."
            )
        return value


class ClasseSerializer(serializers.ModelSerializer):
    student_count = serializers.SerializerMethodField()
    teacher_count = serializers.SerializerMethodField()

    class Meta:
        model = Classe
        fields = [
            "id",
            "name",
            "level",
            "field",
            "academic_year",
            "student_count",
            "teacher_count",
            "created_at",
        ]
        read_only_fields = ["id", "created_at"]

    def get_student_count(self, obj):
        return obj.students.count()

    def get_teacher_count(self, obj):
        return obj.teachers.count()


class StudentSerializer(serializers.ModelSerializer):
    classe_name = serializers.CharField(source="classe.name", read_only=True)
    classe_field = serializers.CharField(source="classe.field", read_only=True)

    class Meta:
        model = Student
        fields = [
            "id",
            "user",
            "first_name",
            "last_name",
            "code_massar",
            "classe",
            "classe_name",
            "classe_field",
            "created_at",
        ]
        read_only_fields = ["id", "created_at"]
