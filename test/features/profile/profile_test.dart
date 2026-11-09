import 'package:daily_life_os/core/constants/string_constants.dart';
import 'package:daily_life_os/core/database/app_database.dart';
import 'package:daily_life_os/core/database/database_seeder.dart';
import 'package:daily_life_os/di/injection_container.dart';
import 'package:daily_life_os/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:daily_life_os/main.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/notifications/fake_notification_service.dart';

void main() {
  late AppDatabase db;
  late FakeNotificationService notificationService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    notificationService = FakeNotificationService();
    await initDependencies(
      database: db,
      notificationService: notificationService,
    );
    await DatabaseSeeder.seedIfEmpty(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Profile & OS Preferences Integration Tests', () {
    testWidgets(
      'Tapping profile avatar on Today Hub opens ProfileSettingsSheet, updates display name & avatar preset, and toggles Floating Quick Ball visibility',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(const DailyLifeOSApp());
        await tester.pumpAndSettle();

        // 1. Initially, 'Aarav' and Floating Quick Ball are visible
        expect(find.textContaining('Aarav'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('quick_capture_ball')),
          findsOneWidget,
        );

        // 2. Tap the profile avatar button in Today Hub AppBar
        final avatarButton = find.byKey(
          const ValueKey('today_profile_avatar_button'),
        );
        expect(avatarButton, findsOneWidget);
        await tester.tap(avatarButton);
        await tester.pumpAndSettle();

        // 3. Verify ProfileSettingsSheet is open
        expect(find.text(StringConstants.profileTitle), findsOneWidget);
        expect(
          find.byKey(const ValueKey('profile_name_input')),
          findsOneWidget,
        );

        // 4. Select a new Avatar Preset ('Emerald Flow', index 1)
        await tester.tap(find.byKey(const ValueKey('avatar_preset_chip_1')));
        await tester.pumpAndSettle();
        expect(sl<ProfileBloc>().state.profile.avatarPresetIndex, 1);

        // 5. Change display name to 'Vikram' and save
        await tester.enterText(
          find.byKey(const ValueKey('profile_name_input')),
          'Vikram',
        );
        await tester.tap(
          find.byKey(const ValueKey('save_profile_identity_btn')),
        );
        await tester.pumpAndSettle();

        expect(sl<ProfileBloc>().state.profile.displayName, 'Vikram');

        // 6. Toggle OFF the Floating Quick-Access Ball switch
        final quickBallSwitch = find.byKey(
          const ValueKey('toggle_quick_access_ball'),
        );
        await tester.ensureVisible(quickBallSwitch);
        await tester.pumpAndSettle();
        await tester.tap(quickBallSwitch);
        await tester.pumpAndSettle();

        expect(sl<ProfileBloc>().state.profile.showFloatingQuickBall, isFalse);

        // 7. Close the Profile sheet and verify Today Hub shows 'Vikram' ('V' monogram)
        //    and the Floating Quick Ball is hidden!
        await tester.tap(find.byTooltip('Close'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Vikram'), findsWidgets);
        expect(find.text('V'), findsOneWidget);
        expect(find.byKey(const ValueKey('quick_capture_ball')), findsNothing);

        // 8. Re-open Profile sheet and turn Floating Quick-Access Ball back ON
        await tester.tap(avatarButton);
        await tester.pumpAndSettle();

        await tester.ensureVisible(quickBallSwitch);
        await tester.pumpAndSettle();
        await tester.tap(quickBallSwitch);
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Close'));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('quick_capture_ball')),
          findsOneWidget,
        );
      },
    );
  });
}
