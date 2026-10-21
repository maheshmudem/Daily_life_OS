import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_life_os/core/widgets/app_dropdown_menu.dart';
import 'package:daily_life_os/config/theme/app_colors.dart';
import 'package:daily_life_os/core/constants/string_constants.dart';

void main() {
  testWidgets('AppDropdownMenu renders trigger and opens items with callbacks',
      (WidgetTester tester) async {
    String? selectedAction;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AppDropdownMenu<String>(
              tooltip: 'More actions',
              icon: const Icon(Icons.more_horiz_rounded, size: 18),
              onSelected: (val) {
                selectedAction = val;
              },
              items: [
                AppDropdownItem<String>(
                  value: 'edit',
                  icon: Icons.edit_outlined,
                  label: StringConstants.edit,
                ),
                AppDropdownItem<String>(
                  value: 'pin',
                  icon: Icons.push_pin_rounded,
                  label: 'Pin to Top',
                  tintColor: AppColors.moduleNotes,
                ),
                AppDropdownItem<String>(
                  value: 'copy',
                  icon: Icons.copy_rounded,
                  label: 'Copy Text',
                ),
                const AppDropdownDivider(),
                AppDropdownItem<String>(
                  value: 'delete',
                  icon: Icons.delete_outline_rounded,
                  label: StringConstants.delete,
                  isDestructive: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // 1. Verify trigger icon exists
    expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);

    // 2. Tap trigger icon to open dropdown
    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();

    // 3. Verify all items exist in dropdown
    expect(find.text(StringConstants.edit), findsOneWidget);
    expect(find.text('Pin to Top'), findsOneWidget);
    expect(find.text('Copy Text'), findsOneWidget);
    expect(find.text(StringConstants.delete), findsOneWidget);

    // 4. Tap 'Copy Text' and verify callback is invoked
    await tester.tap(find.text('Copy Text'));
    await tester.pumpAndSettle();

    expect(selectedAction, 'copy');
    // Dropdown should be dismissed after selection
    expect(find.text('Copy Text'), findsNothing);
  });
}
