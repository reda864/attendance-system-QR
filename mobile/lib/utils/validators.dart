class Validators {
  Validators._();

  // ─── Email ─────────────────────────────────────────────────────────────────
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  // ─── Password ──────────────────────────────────────────────────────────────
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  // ─── Generic required field ────────────────────────────────────────────────
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // ─── First name ────────────────────────────────────────────────────────────
  static String? validateFirstName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'First name is required';
    }
    if (value.trim().length < 2) {
      return 'First name must be at least 2 characters';
    }
    final nameRegex = RegExp(r"^[a-zA-ZÀ-ÿ\s'\-]+$");
    if (!nameRegex.hasMatch(value.trim())) {
      return 'First name contains invalid characters';
    }
    return null;
  }

  // ─── Last name ─────────────────────────────────────────────────────────────
  static String? validateLastName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Last name is required';
    }
    if (value.trim().length < 2) {
      return 'Last name must be at least 2 characters';
    }
    final nameRegex = RegExp(r"^[a-zA-ZÀ-ÿ\s'\-]+$");
    if (!nameRegex.hasMatch(value.trim())) {
      return 'Last name contains invalid characters';
    }
    return null;
  }

  // ─── Code Massar ───────────────────────────────────────────────────────────
  static String? validateCodeMassar(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Code Massar is required';
    }
    if (value.trim().length < 3) {
      return 'Enter a valid Code Massar';
    }
    if (value.trim().length > 50) {
      return 'Code Massar is too long';
    }
    return null;
  }

  // ─── QR Token ─────────────────────────────────────────────────────────────
  // Accepts both:
  //   • UUID format:       xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  //   • base64url format:  secrets.token_urlsafe(32) → 43 chars [A-Za-z0-9_-]
  static bool isValidQrToken(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;

    // UUID format
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}'
      r'-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    if (uuidRegex.hasMatch(trimmed)) return true;

    // base64url format (token_urlsafe): 20–100 chars, only A-Za-z0-9_-
    final base64urlRegex = RegExp(r'^[A-Za-z0-9_\-]{20,100}$');
    return base64urlRegex.hasMatch(trimmed);
  }

  static String? validateQrToken(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'QR token is empty';
    }
    if (!isValidQrToken(value)) {
      return 'Invalid QR token format';
    }
    return null;
  }

  // ─── Non-empty string (generic) ────────────────────────────────────────────
  static bool isNotEmpty(String? value) =>
      value != null && value.trim().isNotEmpty;
}
