from django.contrib.auth.models import (
    AbstractBaseUser,
    BaseUserManager,
    PermissionsMixin,
)
from django.db import models

ROLE_CHOICES = [
    ("admin", "Admin"),
    ("teacher", "Enseignant"),
    ("student", "Étudiant"),
]


class UserManager(BaseUserManager):
    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError("Email is required")
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault("role", "admin")
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)
        return self.create_user(email, password, **extra_fields)


class User(AbstractBaseUser, PermissionsMixin):
    first_name = models.CharField(max_length=100)
    last_name = models.CharField(max_length=100)
    email = models.EmailField(unique=True)
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default="teacher")
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    assigned_classes = models.ManyToManyField(
        "Classe",
        blank=True,
        related_name="teachers",
        help_text="Classes assignées (enseignants uniquement).",
    )

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = ["first_name", "last_name"]

    objects = UserManager()

    class Meta:
        db_table = "users"

    def __str__(self):
        return f"{self.first_name} {self.last_name} ({self.role})"

    @property
    def full_name(self):
        return f"{self.first_name} {self.last_name}"


class Classe(models.Model):
    """Groupe d'étudiants (nom, niveau, filière, année universitaire)."""

    name = models.CharField(max_length=100, verbose_name="Nom de la classe")
    level = models.CharField(max_length=50, verbose_name="Niveau")
    field = models.CharField(max_length=100, verbose_name="Filière")
    academic_year = models.CharField(max_length=20, verbose_name="Année universitaire")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "classes"
        ordering = ["name", "academic_year"]
        verbose_name = "Classe"
        verbose_name_plural = "Classes"

    def __str__(self):
        return f"{self.name} — {self.field} ({self.academic_year})"


class Student(models.Model):
    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name="student_profile",
        limit_choices_to={"role": "student"},
    )
    first_name = models.CharField(max_length=100)
    last_name = models.CharField(max_length=100)
    code_massar = models.CharField(max_length=50, unique=True)
    classe = models.ForeignKey(
        Classe,
        on_delete=models.PROTECT,
        related_name="students",
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "students"

    def __str__(self):
        return f"{self.first_name} {self.last_name} ({self.code_massar})"
