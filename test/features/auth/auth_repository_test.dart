import 'package:flutter_test/flutter_test.dart';
import 'package:growthstreak/features/auth/domain/auth_repository.dart';
import 'package:growthstreak/features/auth/data/mock_auth_repository.dart';

void main() {
  group('AuthRepository Seam (MockAuthRepository)', () {
    late AuthRepository authRepository;

    setUp(() {
      authRepository = MockAuthRepository();
    });

    test('initial auth state is null (unauthenticated)', () async {
      expect(authRepository.currentUser, isNull);
      expect(await authRepository.authStateChanges.first, isNull);
    });

    test('signInWithGoogle emits authenticated AuthUser', () async {
      final user = await authRepository.signInWithGoogle();

      expect(user.uid, isNotEmpty);
      expect(user.email, contains('@'));
      expect(user.displayName, isNotEmpty);
      expect(authRepository.currentUser, equals(user));
      expect(await authRepository.authStateChanges.first, equals(user));
    });

    test('signOut resets currentUser to null and emits null', () async {
      await authRepository.signInWithGoogle();
      expect(authRepository.currentUser, isNotNull);

      await authRepository.signOut();
      expect(authRepository.currentUser, isNull);
      expect(await authRepository.authStateChanges.first, isNull);
    });
  });
}
