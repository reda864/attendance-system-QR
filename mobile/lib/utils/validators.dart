class Validators {
  Validators._();

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'L\'adresse e-mail est requise';
    }
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Saisissez une adresse e-mail valide';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis';
    }
    if (value.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName est requis';
    }
    return null;
  }

  static String? validateFirstName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le prénom est requis';
    }
    if (value.trim().length < 2) {
      return 'Le prénom doit contenir au moins 2 caractères';
    }
    final nameRegex = RegExp(r"^[a-zA-ZÀ-ÿ\s'\-]+$");
    if (!nameRegex.hasMatch(value.trim())) {
      return 'Le prénom contient des caractères invalides';
    }
    return null;
  }

  static String? validateLastName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le nom est requis';
    }
    if (value.trim().length < 2) {
      return 'Le nom doit contenir au moins 2 caractères';
    }
    final nameRegex = RegExp(r"^[a-zA-ZÀ-ÿ\s'\-]+$");
    if (!nameRegex.hasMatch(value.trim())) {
      return 'Le nom contient des caractères invalides';
    }
    return null;
  }

  static String? validateCodeMassar(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le code Massar est requis';
    }
    if (value.trim().length < 3) {
      return 'Saisissez un code Massar valide';
    }
    if (value.trim().length > 50) {
      return 'Le code Massar est trop long';
    }
    return null;
  }

  static bool isValidQrToken(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;

    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}'
      r'-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    if (uuidRegex.hasMatch(trimmed)) return true;

    final base64urlRegex = RegExp(r'^[A-Za-z0-9_\-]{20,100}$');
    return base64urlRegex.hasMatch(trimmed);
  }

  static String? validateQrToken(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Jeton QR vide';
    }
    if (!isValidQrToken(value)) {
      return 'Format de jeton QR invalide';
    }
    return null;
  }

  static bool isNotEmpty(String? value) =>
      value != null && value.trim().isNotEmpty;
}
