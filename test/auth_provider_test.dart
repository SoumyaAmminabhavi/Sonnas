import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/services/auth_provider.dart';

void main() {
  group('AuthNotifier Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state is not authenticated and has 0 attempts', () {
      final state = container.read(authProvider);
      expect(state.isAuthenticated, false);
      expect(state.attempts, 0);
      expect(state.isLockedOut, false);
    });

    test('isLockedOut returns true when lockoutUntil is in the future', () {
      final state = AppAuthState(
        lockoutUntil: DateTime.now().add(const Duration(seconds: 10)),
      );
      expect(state.isLockedOut, true);
    });

    test('isLockedOut returns false when lockoutUntil is in the past', () {
      final state = AppAuthState(
        lockoutUntil: DateTime.now().subtract(const Duration(seconds: 10)),
      );
      expect(state.isLockedOut, false);
    });
  });
}
