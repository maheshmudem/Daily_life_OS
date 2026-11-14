import 'package:daily_life_os/config/theme/app_colors.dart';
import 'package:daily_life_os/core/constants/string_constants.dart';
import 'package:daily_life_os/core/database/app_database.dart';
import 'package:daily_life_os/core/database/database_seeder.dart';
import 'package:daily_life_os/core/monitoring/app_monitor.dart';
import 'package:daily_life_os/di/injection_container.dart';
import 'package:daily_life_os/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:daily_life_os/main.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/notifications/fake_notification_service.dart';

void main() {
  late AppDatabase db;
  late FakeNotificationService notificationService;

  Future<void> bootWithPrefs(Map<String, Object> initialPrefs) async {
    SharedPreferences.setMockInitialValues(initialPrefs);
    FlutterSecureStorage.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    notificationService = FakeNotificationService();
    await initDependencies(
      database: db,
      notificationService: notificationService,
    );
    await DatabaseSeeder.seedIfEmpty(db);
  }

  tearDown(() async {
    await db.close();
  });

  group('Dark Mode & Profile Sheet Entry Point — Unit & Widget Suite', () {
    test(
      'ProfileBloc toggles Dark Mode, normalizes invalid values, and persists to SharedPreferences',
      () async {
        await bootWithPrefs({});
        final bloc = sl<ProfileBloc>();

        // 1. Toggle Dark Mode ON
        bloc.add(const ToggleDarkModePreference(true));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(bloc.state.profile.themeMode, 'dark');

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('os_pref_theme_mode'), 'dark');

        // 2. Toggle Dark Mode OFF -> switches to 'light'
        bloc.add(const ToggleDarkModePreference(false));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(bloc.state.profile.themeMode, 'light');
        expect(prefs.getString('os_pref_theme_mode'), 'light');

        // 3. Invalid mode normalizes safely to 'system'
        bloc.add(const ChangeThemeModePreference('UNSUPPORTED_MODE'));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(bloc.state.profile.themeMode, 'system');
        expect(prefs.getString('os_pref_theme_mode'), 'system');
      },
    );

    testWidgets(
      'Zero-Flash Startup: persisted Dark Mode renders Brightness.dark on the very first frame',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await bootWithPrefs({'os_pref_theme_mode': 'dark'});

        // Pump ONLY frame 1 (no pumpAndSettle) to prove zero light-to-dark flash!
        await tester.pumpWidget(const DailyLifeOSApp());

        final scaffoldFinder = find.byType(Scaffold).first;
        final context = tester.element(scaffoldFinder);
        expect(Theme.of(context).brightness, Brightness.dark);
        expect(
          Theme.of(context).scaffoldBackgroundColor,
          AppColors.darkScaffoldBackground,
        );

        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'Tapping Profile avatar opens ProfileSettingsSheet with top-level Dark Mode switch & selector, updating all modules live',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        // Mock SystemChannels.platform Clipboard so Clipboard.setData resolves immediately in widget test
        String? copiedClipboardText;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (MethodCall call) async {
            if (call.method == 'Clipboard.setData') {
              final args = call.arguments as Map<dynamic, dynamic>;
              copiedClipboardText = args['text'] as String?;
            }
            return null;
          },
        );
        addTearDown(() {
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          );
        });

        await bootWithPrefs({'os_pref_theme_mode': 'light'});

        await tester.pumpWidget(const DailyLifeOSApp());
        await tester.pumpAndSettle();

        // Starts in Light Mode
        Element rootScaffoldContext() =>
            tester.element(find.byType(Scaffold).first);
        expect(Theme.of(rootScaffoldContext()).brightness, Brightness.light);

        // 1. Tap Profile Avatar on Today Hub
        final avatarButton = find.byKey(
          const ValueKey('today_profile_avatar_button'),
        );
        expect(avatarButton, findsOneWidget);
        await tester.tap(avatarButton);
        await tester.pumpAndSettle();

        // 2. Appearance & Dark Mode card is prominently visible right at the top
        expect(
          find.byKey(const ValueKey('profile_settings_sheet')),
          findsOneWidget,
        );
        expect(
          find.text(StringConstants.appearanceAndDarkModeSection),
          findsOneWidget,
        );
        final darkSwitch = find.byKey(
          const ValueKey('toggle_dark_mode_switch'),
        );
        expect(darkSwitch, findsOneWidget);

        // 3. Toggle Dark Mode switch ON -> app immediately transitions to Dark Mode!
        await tester.tap(darkSwitch);
        await tester.pumpAndSettle();

        expect(sl<ProfileBloc>().state.profile.themeMode, 'dark');
        expect(Theme.of(rootScaffoldContext()).brightness, Brightness.dark);
        expect(
          find.text(StringConstants.darkModeActiveSubtitle),
          findsOneWidget,
        );

        // 4. Tap 'Light' mode option chip -> transitions to Light Mode
        await tester.tap(find.byKey(const ValueKey('theme_mode_light')));
        await tester.pumpAndSettle();
        expect(sl<ProfileBloc>().state.profile.themeMode, 'light');
        expect(Theme.of(rootScaffoldContext()).brightness, Brightness.light);

        // 5. Tap 'Dark' mode option chip -> transitions back to Dark Mode
        await tester.tap(find.byKey(const ValueKey('theme_mode_dark')));
        await tester.pumpAndSettle();
        expect(sl<ProfileBloc>().state.profile.themeMode, 'dark');
        expect(Theme.of(rootScaffoldContext()).brightness, Brightness.dark);

        // 6. Verify App Care & Smoothness card and Copy Support Summary button
        final copyDiagBtn = find.byKey(
          const ValueKey('copy_diagnostics_report_btn'),
        );
        await tester.ensureVisible(copyDiagBtn);
        await tester.pumpAndSettle();
        await tester.tap(copyDiagBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
        expect(copiedClipboardText, contains('APP CARE & SUPPORT SUMMARY'));
        expect(
          AppMonitor.containsTechnicalJargon(copiedClipboardText ?? ''),
          isFalse,
        );
        expect(
          find.text(StringConstants.diagnosticsCopiedMessage),
          findsOneWidget,
        );

        // 7. Close sheet and verify Dark Mode across Planner, Notes, and Vault tabs
        await tester.tap(find.byTooltip('Close'));
        await tester.pumpAndSettle();

        final bottomNav = find.byKey(const ValueKey('main_bottom_nav_bar'));
        expect(bottomNav, findsOneWidget);

        // Switch to Planner
        await tester.tap(find.text(StringConstants.navPlanner));
        await tester.pumpAndSettle();
        expect(Theme.of(rootScaffoldContext()).brightness, Brightness.dark);

        // Switch to Notes
        await tester.tap(find.text(StringConstants.navNotes));
        await tester.pumpAndSettle();
        expect(Theme.of(rootScaffoldContext()).brightness, Brightness.dark);

        // Switch to Vault
        await tester.tap(find.text(StringConstants.navVault));
        await tester.pumpAndSettle();
        expect(Theme.of(rootScaffoldContext()).brightness, Brightness.dark);
      },
    );
  });
}
