import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mylife/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthService', () {
    test('isPinSet is false before a PIN is created', () async {
      expect(await AuthService.isPinSet(), isFalse);
    });

    test('setPin marks the PIN as set and verifyPin accepts the correct PIN', () async {
      await AuthService.setPin('1234');

      expect(await AuthService.isPinSet(), isTrue);
      expect(await AuthService.verifyPin('1234'), isTrue);
    });

    test('verifyPin rejects an incorrect PIN', () async {
      await AuthService.setPin('1234');

      expect(await AuthService.verifyPin('0000'), isFalse);
    });

    test('three wrong attempts trigger a lockout', () async {
      await AuthService.setPin('1234');

      await AuthService.verifyPin('0000');
      await AuthService.verifyPin('0000');
      await AuthService.verifyPin('0000');

      expect(await AuthService.getFailCount(), 3);
      expect(await AuthService.getLockSecondsRemaining(), greaterThan(0));
    });

    test('a correct PIN resets the fail count', () async {
      await AuthService.setPin('1234');

      await AuthService.verifyPin('0000');
      await AuthService.verifyPin('1234');

      expect(await AuthService.getFailCount(), 0);
    });

    test('resetPin clears the stored PIN and fail state', () async {
      await AuthService.setPin('1234');
      await AuthService.verifyPin('0000');

      await AuthService.resetPin();

      expect(await AuthService.isPinSet(), isFalse);
      expect(await AuthService.getFailCount(), 0);
      expect(await AuthService.getLockSecondsRemaining(), 0);
    });
  });
}
