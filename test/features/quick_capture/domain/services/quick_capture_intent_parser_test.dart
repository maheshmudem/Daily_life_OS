import 'package:daily_life_os/features/quick_capture/domain/entities/quick_capture_entities.dart';
import 'package:daily_life_os/features/quick_capture/domain/services/quick_capture_intent_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = QuickCaptureIntentParser();

  group('QuickCaptureIntentParser intent detection', () {
    final cases = <String, DetectedIntent>{
      'Spent ₹450 on electricity bill': DetectedIntent.expense,
      'Paid 1200 rent via UPI': DetectedIntent.expense,
      'Earned 50000 salary': DetectedIntent.expense,
      'Daily habit Read 20 mins before bed': DetectedIntent.habit,
      'Morning routine stretch': DetectedIntent.habit,
      'Idea: launch Q4 roadmap @Office': DetectedIntent.note,
      'Buy phone charger @Market': DetectedIntent.note,
      'Call bank tomorrow at 5pm': DetectedIntent.reminder,
      'Team meeting at 10 am': DetectedIntent.reminder,
      'something without keywords': DetectedIntent.reminder,
    };

    cases.forEach((input, expected) {
      test('"$input" → $expected', () {
        expect(parser.parse(input).detectedIntent, expected);
      });
    });

    test('manual override always wins over auto-detection', () {
      final parsed = parser.parse(
        'Spent ₹450 on bill',
        manualOverride: DetectedIntent.note,
      );
      expect(parsed.detectedIntent, DetectedIntent.note);
    });
  });

  group('QuickCaptureIntentParser field extraction', () {
    test('extracts amount, category and payment mode for expenses', () {
      final parsed = parser.parse('Spent ₹850 on grocery via Card');
      expect(parsed.extractedAmount, '850');
      expect(parsed.expenseCategory, 'food');
      expect(parsed.paymentMode, 'Card');
      expect(parsed.isIncome, isFalse);
    });

    test('detects income keywords', () {
      expect(parser.parse('Received 3000 refund').isIncome, isTrue);
    });

    test('normalises time and detects tomorrow + urgent priority', () {
      final parsed = parser.parse('Call bank tomorrow at 5:30 PM urgent');
      expect(parsed.extractedTime, '05:30 PM');
      expect(parsed.isTomorrow, isTrue);
      expect(parsed.reminderPriority, 'urgent');
    });

    test('pads hour and defaults minutes to 00', () {
      expect(parser.parse('gym at 7am').extractedTime, '07:00 AM');
    });

    test('maps note tags and sensitive words to @Vault', () {
      expect(parser.parse('note @home wifi').noteTag, '@Home');
      expect(parser.parse('locker secret code').noteTag, '@Vault');
    });

    test('returns nulls when nothing is detected', () {
      final parsed = parser.parse('hello');
      expect(parsed.extractedAmount, isNull);
      expect(parsed.extractedTime, isNull);
      expect(parsed.isTomorrow, isNull);
      expect(parsed.expenseCategory, isNull);
      expect(parsed.paymentMode, isNull);
    });
  });
}
