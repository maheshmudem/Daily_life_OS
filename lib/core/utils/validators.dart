class Validators {
  Validators._();

  static const int maxEmailLength = 254;
  static const int maxPasswordLength = 128;
  static const int maxFieldLength = 500;
  static const double maxSupportedAmount = 1e12; // 1 trillion cap

  static final RegExp _controlCharsRegex = RegExp(
    r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]',
  );

  static bool containsControlCharacters(String value) {
    return _controlCharsRegex.hasMatch(value);
  }

  /// Strips null bytes / unsafe control characters, normalizes whitespace,
  /// and enforces a hard upper bound [maxLength] to prevent memory/UI DoS.
  static String sanitizeText(String input, {int maxLength = 2000}) {
    if (input.isEmpty) return '';
    var cleaned = input.replaceAll(_controlCharsRegex, '');
    if (cleaned.length > maxLength) {
      cleaned = cleaned.substring(0, maxLength);
    }
    return cleaned.trim();
  }

  /// Rejects `javascript:`, `data:`, `vbscript:`, `file:`, and (when
  /// [requireHttps] is true) cleartext `http://` URLs.
  static bool isSafeUrl(String? rawUrl, {bool requireHttps = true}) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return false;
    final trimmed = rawUrl.trim();
    if (trimmed.length > 2048 || containsControlCharacters(trimmed)) {
      return false;
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return false;
    final scheme = uri.scheme.toLowerCase();
    if (scheme == 'https') return true;
    if (!requireHttps && scheme == 'http') return true;
    return false;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final trimmed = value.trim();
    if (trimmed.length > maxEmailLength || containsControlCharacters(trimmed)) {
      return 'Please enter a valid email address';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
    );
    if (!emailRegex.hasMatch(trimmed)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (containsControlCharacters(value)) {
      return 'Password contains invalid characters';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (value.length > maxPasswordLength) {
      return 'Password must not exceed $maxPasswordLength characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    if (value.length > 32 || containsControlCharacters(value)) {
      return 'Please enter a valid 10-digit phone number';
    }
    final cleanValue = value.trim().replaceAll(RegExp(r'\D'), '');
    if (cleanValue.length != 10) {
      return 'Please enter a valid 10-digit phone number';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    final trimmed = value.trim();
    if (containsControlCharacters(trimmed)) {
      return 'Name contains invalid characters';
    }
    if (trimmed.length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (trimmed.length > 50) {
      return 'Name must not exceed 50 characters';
    }
    final nameRegex = RegExp(r'^[a-zA-Z\s.]+$');
    if (!nameRegex.hasMatch(trimmed)) {
      return 'Name can only contain letters, spaces, and periods';
    }
    return null;
  }

  static String? validateDateOfBirth(DateTime? value) {
    if (value == null) {
      return 'Date of birth is required';
    }
    final now = DateTime.now();
    if (value.isAfter(now)) {
      return 'Date of birth cannot be in the future';
    }
    final age = now.year - value.year;
    if (age > 120) {
      return 'Please enter a valid date of birth';
    }
    return null;
  }

  static String? validateGender(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select a gender';
    }
    const validGenders = ['Male', 'Female', 'Other'];
    if (!validGenders.contains(value)) {
      return 'Please select a valid gender';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final trimmed = value.trim();
    if (containsControlCharacters(trimmed)) {
      return '$fieldName contains invalid characters';
    }
    if (trimmed.length > maxFieldLength) {
      return '$fieldName must not exceed $maxFieldLength characters';
    }
    return null;
  }

  /// Money amount: required, finite numeric, greater than zero, within cap.
  static String? validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter an amount';
    }
    final trimmed = value.trim();
    if (trimmed.length > 24 || containsControlCharacters(trimmed)) {
      return 'Enter a valid amount';
    }
    final parsed = double.tryParse(trimmed);
    if (parsed == null ||
        !parsed.isFinite ||
        parsed <= 0 ||
        parsed > maxSupportedAmount) {
      return 'Enter a valid amount';
    }
    return null;
  }

  /// Money amount that may be zero (e.g. budget limit, account balance).
  static String? validateNonNegativeAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter an amount';
    }
    final trimmed = value.trim();
    if (trimmed.length > 24 || containsControlCharacters(trimmed)) {
      return 'Enter a valid positive amount';
    }
    final parsed = double.tryParse(trimmed);
    if (parsed == null ||
        !parsed.isFinite ||
        parsed < 0 ||
        parsed > maxSupportedAmount) {
      return 'Enter a valid positive amount';
    }
    return null;
  }

  static int getPasswordStrength(String password) {
    if (password.isEmpty || password.length > maxPasswordLength) return 0;
    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;
    return strength; // 0-5
  }
}
