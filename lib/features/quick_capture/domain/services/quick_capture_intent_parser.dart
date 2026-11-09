import '../entities/quick_capture_entities.dart';

/// Pure-Dart, rule-based NLP parser for Quick Capture input.
///
/// Lives in the domain layer because it encodes business rules (what counts
/// as an expense, which words imply urgency, ...) and has no I/O, so it is
/// deterministic and fully unit-testable.
class QuickCaptureIntentParser {
  const QuickCaptureIntentParser();

  static final RegExp _amountWithKeyword = RegExp(
    r'(?:₹|rs\.?\s*|spent\s+|paid\s+|earned\s+|cost\s+|bill\s+)(\d+(?:\.\d+)?)',
    caseSensitive: false,
  );
  static final RegExp _bareAmount = RegExp(r'\b(\d{2,6}(?:\.\d{1,2})?)\b');
  static final RegExp _time = RegExp(
    r'\b(\d{1,2})(?::(\d{2}))?\s*(am|pm)\b',
    caseSensitive: false,
  );

  ParsedQuickCaptureIntentEntity parse(
    String rawText, {
    DetectedIntent? manualOverride,
  }) {
    final text = rawText.toLowerCase();
    bool has(List<String> words) => words.any(text.contains);

    // 1. Amount
    final amountMatch =
        _amountWithKeyword.firstMatch(rawText) ??
        _bareAmount.firstMatch(rawText);
    final amountGroup = amountMatch?.group(1);
    final extractedAmount = (amountGroup != null && amountGroup.isNotEmpty)
        ? amountGroup
        : null;

    // 2. Time (normalised to `hh:mm AM`)
    String? extractedTime;
    final timeMatch = _time.firstMatch(rawText);
    if (timeMatch != null) {
      final hour = int.tryParse(timeMatch.group(1)!) ?? 5;
      final minute = timeMatch.group(2) ?? '00';
      final meridiem = timeMatch.group(3)!.toUpperCase();
      extractedTime = '${hour.toString().padLeft(2, '0')}:$minute $meridiem';
    }

    // 3. Day
    final bool? isTomorrow = has(['tomorrow', 'tmrw'])
        ? true
        : (text.contains('today') ? false : null);

    // 4. Priority
    final String? priority = has(['urgent', 'asap'])
        ? 'urgent'
        : (has(['high', 'important']) ? 'high' : null);

    // 5. Income vs expense, category, payment mode
    final bool? isIncome = has(['earned', 'salary', 'income', 'received'])
        ? true
        : (has(['spent', 'paid', 'bought']) ? false : null);

    final String? category = has(['bill', 'electr', 'wifi', 'rent'])
        ? 'bills'
        : has(['food', 'coffee', 'lunch', 'dinner', 'grocery'])
        ? 'food'
        : has(['cab', 'uber', 'metro', 'fuel', 'taxi'])
        ? 'transport'
        : has(['shop', 'amazon', 'charger'])
        ? 'shopping'
        : null;

    final String? paymentMode = text.contains('cash')
        ? 'Cash'
        : has(['card', 'credit'])
        ? 'Card'
        : has(['upi', 'gpay'])
        ? 'UPI'
        : null;

    // 6. Note tag
    final String? noteTag = text.contains('@market')
        ? '@Market'
        : has(['@office', '@work'])
        ? '@Office'
        : text.contains('@home')
        ? '@Home'
        : has(['password', 'pin', 'secret', 'warranty'])
        ? '@Vault'
        : null;

    // 7. Primary intent (precedence: expense > habit > note > reminder)
    final DetectedIntent autoIntent;
    if (has([
      'spent',
      'paid',
      'bought',
      'earned',
      'salary',
      'rs',
      '₹',
      'bill',
      'cost',
    ])) {
      autoIntent = DetectedIntent.expense;
    } else if (has(['habit', 'routine', 'every day', 'daily'])) {
      autoIntent = DetectedIntent.habit;
    } else if (has([
      'note',
      'idea',
      '@market',
      '@office',
      '@home',
      'password',
      'secret',
    ])) {
      autoIntent = DetectedIntent.note;
    } else {
      // Reminder is the default: anything with a time/day/verb, or plain text.
      autoIntent = DetectedIntent.reminder;
    }

    return ParsedQuickCaptureIntentEntity(
      detectedIntent: manualOverride ?? autoIntent,
      extractedAmount: extractedAmount,
      extractedTime: extractedTime,
      isTomorrow: isTomorrow,
      reminderPriority: priority,
      isIncome: isIncome,
      expenseCategory: category,
      paymentMode: paymentMode,
      noteTag: noteTag,
    );
  }
}
