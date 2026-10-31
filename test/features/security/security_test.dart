import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:daily_life_os/features/security/data/datasources/security_local_datasource.dart';
import 'package:daily_life_os/features/security/data/repositories/security_repository_impl.dart';
import 'package:daily_life_os/features/security/domain/entities/security_config_entity.dart';
import 'package:daily_life_os/features/security/presentation/widgets/pin_dialpad_widget.dart';
import 'package:daily_life_os/features/security/presentation/widgets/pattern_lock_grid_widget.dart';
import 'package:daily_life_os/features/security/presentation/widgets/vault_lock_screen.dart';

import 'package:local_auth/local_auth.dart';

// In-Memory Fake for FlutterSecureStorage in tests
class FakeSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _data[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _data[key] = value;
    } else {
      _data.remove(key);
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _data.remove(key);
  }

  @override
  Future<void> deleteAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _data.clear();
}

class FakeLocalAuth extends Fake implements LocalAuthentication {
  @override
  Future<bool> get canCheckBiometrics async => false;

  @override
  Future<bool> isDeviceSupported() async => false;
}

void main() {
  late FakeSecureStorage fakeStorage;
  late SecurityLocalDataSource dataSource;
  late SecurityRepositoryImpl repository;

  setUp(() {
    fakeStorage = FakeSecureStorage();
    dataSource = SecurityLocalDataSourceImpl(
      storage: fakeStorage,
      localAuth: FakeLocalAuth(),
    );
    repository = SecurityRepositoryImpl(dataSource);
  });

  group('SecurityRepository & Cryptographic Salting Tests', () {
    test(
      'Fresh installation defaults to opt-in disabled and has NO default PIN/pattern',
      () async {
        final config = await repository.getConfig();
        expect(config.isSecurityEnabled, isFalse);
        expect(config.isConfigured, isFalse);
        expect(config.hasPin, isFalse);
        expect(config.hasPattern, isFalse);

        // Verify no hardcoded backdoor PINs or patterns work
        expect(await repository.verifyPin('1234'), isFalse);
        expect(await repository.verifyPin('0000'), isFalse);
        expect(await repository.isDecoyPin('9999'), isFalse);
        expect(await repository.verifyPattern([0, 1, 2, 5, 8]), isFalse);
      },
    );

    test(
      'Setting PIN configures salted hash, enables security, and supports decoy PIN',
      () async {
        await repository.setPin(pin: '5678', decoyPin: '1111');

        expect(await repository.verifyPin('5678'), isTrue);
        expect(await repository.verifyPin('1234'), isFalse);
        expect(await repository.isDecoyPin('1111'), isTrue);
        expect(await repository.isDecoyPin('5678'), isFalse);

        final config = await repository.getConfig();
        expect(config.isSecurityEnabled, isTrue);
        expect(config.hasPin, isTrue);
        expect(config.hasDecoyPin, isTrue);
        expect(config.isConfigured, isTrue);
      },
    );

    test(
      'Setting Pattern configures salted hash and supports decoy pattern',
      () async {
        await repository.setPattern(
          pattern: [1, 4, 7],
          decoyPattern: [3, 4, 5],
        );

        expect(await repository.verifyPattern([1, 4, 7]), isTrue);
        expect(await repository.verifyPattern([0, 1, 2]), isFalse);
        expect(await repository.isDecoyPattern([3, 4, 5]), isTrue);
        expect(await repository.isDecoyPattern([1, 4, 7]), isFalse);

        final config = await repository.getConfig();
        expect(config.isSecurityEnabled, isTrue);
        expect(config.hasPattern, isTrue);
        expect(config.hasDecoyPattern, isTrue);
      },
    );

    test(
      'Updating decoy PIN and pattern independently works via dedicated setters',
      () async {
        await repository.setPin(pin: '4321');
        await repository.setDecoyPin('8888');

        expect(await repository.verifyPin('4321'), isTrue);
        expect(await repository.isDecoyPin('8888'), isTrue);

        await repository.setPattern(pattern: [0, 1, 2]);
        await repository.setDecoyPattern([6, 7, 8]);

        expect(await repository.verifyPattern([0, 1, 2]), isTrue);
        expect(await repository.isDecoyPattern([6, 7, 8]), isTrue);
      },
    );

    test('Toggling biometrics and lock mode persists in config', () async {
      await repository.setLockMode(SecurityLockMode.pattern);
      var config = await repository.getConfig();
      expect(config.activeMode, SecurityLockMode.pattern);

      await repository.setBiometricsEnabled(false);
      config = await repository.getConfig();
      expect(config.isBiometricEnabled, isFalse);

      await repository.setBiometricsEnabled(true);
      config = await repository.getConfig();
      expect(config.isBiometricEnabled, isTrue);
    });

    test(
      'Vulnerability Test: 5 consecutive failed attempts trigger rate-limiting lockout',
      () async {
        await repository.setPin(pin: '2468');

        expect(await repository.getLockoutUntil(), isNull);
        expect(await repository.getFailedAttempts(), 0);

        // 4 incorrect attempts
        for (int i = 0; i < 4; i++) {
          final res = await repository.verifyPin('0000');
          expect(res, isFalse);
        }
        expect(await repository.getFailedAttempts(), 4);
        expect(await repository.getLockoutUntil(), isNull);

        // 5th incorrect attempt -> triggers 30s lockout
        final fifthAttempt = await repository.verifyPin('0000');
        expect(fifthAttempt, isFalse);
        expect(await repository.getFailedAttempts(), 5);

        final lockoutUntil = await repository.getLockoutUntil();
        expect(lockoutUntil, isNotNull);
        expect(lockoutUntil!.isAfter(DateTime.now()), isTrue);

        // During lockout, even correct PIN is rejected
        expect(await repository.verifyPin('2468'), isFalse);
      },
    );

    test(
      'clearAllSecurity() wipes all credentials and resets configuration',
      () async {
        await repository.setPin(pin: '1234', decoyPin: '9999');
        await repository.setPattern(pattern: [0, 1, 2]);

        await repository.clearAllSecurity();

        final config = await repository.getConfig();
        expect(config.isSecurityEnabled, isFalse);
        expect(config.hasPin, isFalse);
        expect(config.hasPattern, isFalse);
        expect(config.isConfigured, isFalse);
        expect(await repository.verifyPin('1234'), isFalse);
      },
    );
  });

  group('PinDialpadWidget UI Tests', () {
    testWidgets('Renders dialpad digits and updates PIN on tap', (
      WidgetTester tester,
    ) async {
      String currentPin = '';
      bool biometricTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => PinDialpadWidget(
                pinLength: 4,
                currentPin: currentPin,
                onPinChanged: (val) => setState(() => currentPin = val),
                onBiometricTap: () => biometricTapped = true,
              ),
            ),
          ),
        ),
      );

      // Verify digits 0-9 exist
      for (int i = 0; i <= 9; i++) {
        expect(find.text('$i'), findsOneWidget);
      }

      // Tap 1, 2, 3
      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();
      expect(currentPin, '1');

      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();
      expect(currentPin, '12');

      // Tap Backspace
      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pumpAndSettle();
      expect(currentPin, '1');

      // Tap Biometric icon
      await tester.tap(find.byIcon(Icons.fingerprint_rounded));
      await tester.pumpAndSettle();
      expect(biometricTapped, isTrue);
    });
  });

  group('PatternLockGridWidget UI Tests', () {
    testWidgets(
      'Renders 3x3 pattern lock canvas and responds to drag gesture',
      (WidgetTester tester) async {
        List<int>? completedPattern;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: PatternLockGridWidget(
                  size: 250,
                  onPatternComplete: (p) => completedPattern = p,
                ),
              ),
            ),
          ),
        );

        final gridFinder = find.byType(PatternLockGridWidget);
        expect(gridFinder, findsOneWidget);

        // Drag across nodes
        final center = tester.getCenter(gridFinder);
        final gesture = await tester.startGesture(
          center - const Offset(50, 50),
        );
        await gesture.moveTo(center);
        await gesture.moveTo(center + const Offset(50, 50));
        await gesture.up();
        await tester.pumpAndSettle();

        expect(completedPattern, isNotNull);
        expect(completedPattern!.isNotEmpty, isTrue);
      },
    );
  });

  group('VaultLockScreen Full Flow Tests', () {
    testWidgets(
      'Entering user-configured master PIN unlocks vault in standard mode',
      (WidgetTester tester) async {
        // User sets up their PIN
        await repository.setPin(pin: '1234', decoyPin: '9999');

        bool unlocked = false;
        bool wasDecoy = true;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VaultLockScreen(
                securityRepository: repository,
                onUnlock: ({required bool isDecoy}) {
                  unlocked = true;
                  wasDecoy = isDecoy;
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Enter 1, 2, 3, 4
        await tester.tap(find.text('1'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('2'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('3'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('4'));
        await tester.pumpAndSettle();

        expect(unlocked, isTrue);
        expect(wasDecoy, isFalse);
      },
    );

    testWidgets(
      'Entering user-configured decoy PIN unlocks vault in decoy mode',
      (WidgetTester tester) async {
        // User sets up their PIN and decoy PIN
        await repository.setPin(pin: '1234', decoyPin: '9999');

        bool unlocked = false;
        bool wasDecoy = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VaultLockScreen(
                securityRepository: repository,
                onUnlock: ({required bool isDecoy}) {
                  unlocked = true;
                  wasDecoy = isDecoy;
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Enter 9, 9, 9, 9
        for (int i = 0; i < 4; i++) {
          await tester.tap(find.text('9'));
          await tester.pumpAndSettle();
        }

        expect(unlocked, isTrue);
        expect(wasDecoy, isTrue);
      },
    );

    testWidgets('Switching to Pattern Lock tab displays 3x3 pattern canvas', (
      WidgetTester tester,
    ) async {
      await repository.setPin(pin: '1234');
      await repository.setPattern(pattern: [0, 1, 2, 5]);
      await repository.setLockMode(SecurityLockMode.pin);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VaultLockScreen(
              securityRepository: repository,
              onUnlock: ({required bool isDecoy}) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Pattern Lock tab
      await tester.tap(find.text('Pattern Lock'));
      await tester.pumpAndSettle();

      expect(find.byType(PatternLockGridWidget), findsOneWidget);
    });
  });
}
