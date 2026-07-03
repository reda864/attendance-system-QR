from django.contrib.auth import authenticate
from rest_framework import serializers

from .models import Classe, Module, Semester, Student, User


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
    teaching_module_ids = serializers.SerializerMethodField()

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
            "teaching_module_ids",
            "student_profile",
            "created_at",
        ]
        read_only_fields = [
            "id",
            "created_at",
            "active_role",
            "available_roles",
            "assigned_class_ids",
            "teaching_module_ids",
        ]

    def get_active_role(self, obj):
        return getattr(obj, "active_role", None) or obj.role

    def get_available_roles(self, obj):
        return obj.available_roles

    def get_full_name(self, obj):
        return obj.full_name

    def get_assigned_class_ids(self, obj):
        return obj.get_assigned_class_ids()

    def get_teaching_module_ids(self, obj):
        return obj.get_teaching_module_ids()

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
        ]

    def validate(self, data):
        password = data.get("password")
        password_confirm = data.get("password_confirm")
        if password_confirm is not None and password != password_confirm:
            raise serializers.ValidationError(
                {"password_confirm": "Passwords do not match."}
            )
        data.pop("password_confirm", None)
        role = data.get("role", "teacher")
        is_also_teacher = data.get("is_also_teacher", False)
        if role != "admin" and is_also_teacher:
            raise serializers.ValidationError(
                {"is_also_teacher": "Seuls les administrateurs peuvent être aussi enseignants."}
            )
        return data

    def create(self, validated_data):
        password = validated_data.pop("password")
        user = User(**validated_data)
        user.set_password(password)
        user.save()
        return user


class UserUpdateSerializer(serializers.ModelSerializer):
    password = serializers.CharField(
        write_only=True,
        min_length=8,
        required=False,
        allow_blank=True,
        style={"input_type": "password"},
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
        ]

    def validate(self, data):
        role = data.get("role", getattr(self.instance, "role", None))
        is_also_teacher = data.get(
            "is_also_teacher", getattr(self.instance, "is_also_teacher", False)
        )
        if role != "admin" and is_also_teacher:
            raise serializers.ValidationError(
                {"is_also_teacher": "Seuls les administrateurs peuvent être aussi enseignants."}
            )
        return data

    def update(self, instance, validated_data):
        password = validated_data.pop("password", None)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        if password:
            instance.set_password(password)
        instance.save()
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
    semester_count = serializers.SerializerMethodField()
    module_count = serializers.SerializerMethodField()

    class Meta:
        model = Classe
        fields = [
            "id",
            "name",
            "code",
            "level",
            "field",
            "academic_year",
            "student_count",
            "semester_count",
            "module_count",
            "created_at",
        ]
        read_only_fields = ["id", "created_at"]

    def get_student_count(self, obj):
        return obj.students.count()

    def get_semester_count(self, obj):
        return obj.semesters.count()

    def get_module_count(self, obj):
        return Module.objects.filter(semester__classe=obj).count()


class SemesterSerializer(serializers.ModelSerializer):
    classe_name = serializers.CharField(source="classe.name", read_only=True)
    module_count = serializers.SerializerMethodField()

    class Meta:
        model = Semester
        fields = [
            "id",
            "classe",
            "classe_name",
            "code",
            "name",
            "order",
            "module_count",
            "created_at",
        ]
        read_only_fields = ["id", "created_at"]

    def get_module_count(self, obj):
        return obj.modules.count()


class ModuleSerializer(serializers.ModelSerializer):
    semester_code = serializers.CharField(source="semester.code", read_only=True)
    classe_id = serializers.IntegerField(source="semester.classe_id", read_only=True)
    classe_name = serializers.CharField(source="semester.classe.name", read_only=True)
    teacher_name = serializers.CharField(source="teacher.full_name", read_only=True)

    class Meta:
        model = Module
        fields = [
            "id",
            "semester",
            "semester_code",
            "classe_id",
            "classe_name",
            "name",
            "code",
            "teacher",
            "teacher_name",
            "created_at",
        ]
        read_only_fields = ["id", "created_at"]

    def validate_teacher(self, value):
        if not value.is_teacher_capable:
            raise serializers.ValidationError(
                "L'enseignant assigné doit avoir le rôle enseignant."
            )
        return value


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
