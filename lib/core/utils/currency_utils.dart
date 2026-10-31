import 'package:intl/intl.dart';

/// Supported display currency for the Money module.
class AppCurrency {
  final String code;
  final String symbol;
  final String locale;
  final String label;

  const AppCurrency({
    required this.code,
    required this.symbol,
    required this.locale,
    required this.label,
  });
}

/// Centralised currency formatting (uses `intl` NumberFormat).
///
/// The active currency is configured once from Money settings via
/// [CurrencyUtils.setCurrency]; every money widget formats through here so
/// the symbol / grouping stay consistent across the app.
class CurrencyUtils {
  CurrencyUtils._();

  static const List<AppCurrency> supportedCurrencies = [
    AppCurrency(
      code: 'INR',
      symbol: '₹',
      locale: 'en_IN',
      label: 'Indian Rupee',
    ),
    AppCurrency(code: 'USD', symbol: r'$', locale: 'en_US', label: 'US Dollar'),
    AppCurrency(code: 'EUR', symbol: '€', locale: 'en_IE', label: 'Euro'),
    AppCurrency(
      code: 'GBP',
      symbol: '£',
      locale: 'en_GB',
      label: 'British Pound',
    ),
    AppCurrency(
      code: 'AED',
      symbol: 'AED ',
      locale: 'en_US',
      label: 'UAE Dirham',
    ),
    AppCurrency(
      code: 'JPY',
      symbol: '¥',
      locale: 'ja_JP',
      label: 'Japanese Yen',
    ),
  ];

  static AppCurrency _current = supportedCurrencies.first;

  /// Currently active currency.
  static AppCurrency get current => _current;

  /// Active currency symbol, e.g. `₹`.
  static String get symbol => _current.symbol;

  /// Switches the active currency. Unknown codes fall back to INR.
  static void setCurrency(String code) {
    _current = currencyFor(code);
  }

  static AppCurrency currencyFor(String code) {
    return supportedCurrencies.firstWhere(
      (c) => c.code == code,
      orElse: () => supportedCurrencies.first,
    );
  }

  /// `₹1,23,456.50` (decimals = 2) or `₹1,23,457` (decimals = 0).
  static String format(double amount, {int decimals = 0}) {
    final formatter = NumberFormat.currency(
      locale: _current.locale,
      symbol: _current.symbol,
      decimalDigits: decimals,
    );
    return formatter.format(amount);
  }

  /// Signed amount for transaction rows: `+₹500` / `-₹500`.
  static String signed(
    double amount, {
    required bool isCredit,
    int decimals = 0,
  }) {
    final prefix = isCredit ? '+' : '-';
    return '$prefix${format(amount.abs(), decimals: decimals)}';
  }

  /// Compact form for chart labels: `₹1.2K`, `₹3.4L` (INR) / `$3.4M`.
  static String compact(double amount) {
    final formatter = NumberFormat.compactCurrency(
      locale: _current.locale,
      symbol: _current.symbol,
      decimalDigits: amount.abs() >= 1000 ? 1 : 0,
    );
    return formatter.format(amount);
  }

  /// Plain number without symbol, e.g. for pre-filling input fields.
  static String plain(double amount, {int decimals = 0}) {
    return amount.toStringAsFixed(decimals);
  }

  /// Percentage label, e.g. `12.5%`.
  static String percent(double value, {int decimals = 0}) {
    return '${value.toStringAsFixed(decimals)}%';
  }
}
