import 'package:daily_life_os/core/constants/string_constants.dart';
import 'package:daily_life_os/core/database/app_database.dart';
import 'package:daily_life_os/core/database/database_seeder.dart';
import 'package:daily_life_os/di/injection_container.dart';
import 'package:daily_life_os/main.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/notifications/fake_notification_service.dart';

class _DeviceSpec {
  final String name;
  final Size logicalSize;
  final double textScale;

  const _DeviceSpec(this.name, this.logicalSize, {this.textScale = 1.0});
}

void main() {
  const devices = <_DeviceSpec>[
    _DeviceSpec('Compact Android Phone (360x640)', Size(360, 640)),
    _DeviceSpec('Standard Modern Phone (390x844)', Size(390, 844)),
    _DeviceSpec(
      'Standard Phone + 1.25x Accessibility Font (390x844 @1.25x)',
      Size(390, 844),
      textScale: 1.25,
    ),
    _DeviceSpec('Large Flagship Phone (430x932)', Size(430, 932)),
    _DeviceSpec('Tablet Portrait (768x1024)', Size(768, 1024)),
    _DeviceSpec('Tablet / Desktop Landscape (1024x768)', Size(1024, 768)),
  ];

  group('Multi-Device Viewport, Orientation & Dark Mode Matrix Suite', () {
    for (final device in devices) {
      for (final initialTheme in ['light', 'dark']) {
        testWidgets(
          '${device.name} in ${initialTheme.toUpperCase()} mode renders Today Hub, Profile Sheet Dark Mode toggle, Planner, Notes & Vault with zero overflow',
          (tester) async {
            tester.view.physicalSize = device.logicalSize;
            tester.view.devicePixelRatio = 1.0;
            tester.platformDispatcher.textScaleFactorTestValue =
                device.textScale;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );

            SharedPreferences.setMockInitialValues({
              'os_pref_theme_mode': initialTheme,
            });
            FlutterSecureStorage.setMockInitialValues({});
            final db = AppDatabase(NativeDatabase.memory());
            addTearDown(db.close);

            await initDependencies(
              database: db,
              notificationService: FakeNotificationService(),
            );
            await DatabaseSeeder.seedIfEmpty(db);

            await tester.pumpWidget(const DailyLifeOSApp());
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);

            // Verify initial theme brightness matches device run
            final expectedBrightness = initialTheme == 'dark'
                ? Brightness.dark
                : Brightness.light;
            expect(
              Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
              expectedBrightness,
            );

            // Open Profile Sheet via Profile Avatar button & verify Dark Mode controls
            await tester.tap(
              find.byKey(const ValueKey('today_profile_avatar_button')),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);

            expect(
              find.byKey(const ValueKey('toggle_dark_mode_switch')),
              findsOneWidget,
            );

            // Close Profile Sheet
            await tester.tap(find.byTooltip('Close'));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);

            // Visit Planner, Notes, and Vault tabs to verify responsive layout
            for (final tab in [
              StringConstants.navPlanner,
              StringConstants.navNotes,
              StringConstants.navVault,
            ]) {
              await tester.tap(find.text(tab));
              await tester.pumpAndSettle();
              expect(
                tester.takeException(),
                isNull,
                reason: 'Overflow/error on $tab for ${device.name}',
              );
            }
          },
        );
      }
    }
  });
}
