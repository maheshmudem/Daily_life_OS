import 'package:daily_life_os/config/theme/app_colors.dart';
import 'package:daily_life_os/config/theme/app_decorations.dart';
import 'package:daily_life_os/config/theme/app_theme.dart';
import 'package:daily_life_os/config/theme/theme_context.dart';
import 'package:daily_life_os/core/utils/snackbar_utils.dart';
import 'package:daily_life_os/core/widgets/app_bottom_sheet.dart';
import 'package:daily_life_os/core/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppText and Theme compliance', () {
    testWidgets(
      'bare AppText with weight/size override preserves button DefaultTextStyle color',
      (tester) async {
        const expectedForeground = AppColors.textWhite;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: FilledButton(
                style: FilledButton.styleFrom(
                  foregroundColor: expectedForeground,
                ),
                onPressed: () {},
                child: const AppText(
                  'Complete',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        );

        final textWidget = tester.widget<Text>(find.text('Complete'));
        final context = tester.element(find.text('Complete'));
        final inherited = DefaultTextStyle.of(context).style;
        final resolvedColor = textWidget.style?.color ?? inherited.color;

        expect(resolvedColor, expectedForeground);
        expect(textWidget.style?.fontSize, 11.5);
        expect(textWidget.style?.fontWeight, FontWeight.w700);
      },
    );

    testWidgets(
      'AppText variants and AppDecorations adapt colors cleanly in dark mode',
      (tester) async {
        late AppPalette darkPalette;
        late BoxDecoration cardDecoration;
        late BoxDecoration elevatedDecoration;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  darkPalette = context.palette;
                  cardDecoration = AppDecorations.card(context);
                  elevatedDecoration = AppDecorations.cardElevated(context);
                  return Container(
                    decoration: cardDecoration,
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppSheetHandle(),
                        AppText.titleMedium('Dark Heading'),
                        AppText.bodyMedium('Dark Body'),
                        AppText.captionBold('Dark Caption'),
                        AppText.monoCode('AES-256'),
                        AppText.currencyHero('₹1,250'),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );

        expect(darkPalette.isDark, isTrue);
        expect(cardDecoration.color, AppColors.darkCardBackground);
        expect(elevatedDecoration.color, AppColors.darkSurfaceSecondary);

        final headingText = tester.widget<Text>(find.text('Dark Heading'));
        final bodyText = tester.widget<Text>(find.text('Dark Body'));
        final monoText = tester.widget<Text>(find.text('AES-256'));
        final heroText = tester.widget<Text>(find.text('₹1,250'));

        expect(headingText.style?.color, AppColors.darkTextHeading);
        expect(bodyText.style?.color, AppColors.darkTextBody);
        expect(monoText.style?.color, AppColors.darkTextHeading);
        expect(heroText.style?.color, AppColors.darkTextHeading);
      },
    );

    testWidgets('SnackbarUtils displays message with AppText inside SnackBar', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () =>
                    SnackbarUtils.showMessage(context, 'Saved safely'),
                child: const AppText('Trigger'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.byType(AppText), findsAtLeastNWidgets(2));
      expect(find.text('Saved safely'), findsOneWidget);
    });
  });
}
