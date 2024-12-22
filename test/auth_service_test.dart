import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart' hide test;
import 'package:stn_auth/auth_service.dart';

class MockSecureStorage extends Mock implements ISecureStorage {}
class MockCacheStorage extends Mock implements ICacheStorage {}

void main() {
  group('AuthService', () {
    late MockSecureStorage mockSecureStorage;
    late MockCacheStorage mockCacheStorage;
    late AuthService authService;

    setUp(() {
      mockSecureStorage = MockSecureStorage();
      mockCacheStorage = MockCacheStorage();
      authService = AuthService(mockSecureStorage, mockCacheStorage);
    });

    group('login', () {
      test('should return access code and private key when valid access code is provided', () async {
        when(mockSecureStorage.read<String>(accessCodeKey))
            .thenAnswer((_) async => (null, 'validAccessCode'));
        when(mockSecureStorage.read<String>(privateKey))
            .thenAnswer((_) async => (null, 'validPrivateKey'));

        final (failure, result) = await authService.login(accessCode: 'validAccessCode');

        expect(failure, isNull);
        expect(result, isNotNull);
        expect(result, ('validAccessCode', 'validPrivateKey'));
      });

      test('should return CacheFailure when access code is invalid', () async {
        when(mockSecureStorage.read<String>(accessCodeKey))
            .thenAnswer((_) async => (null, 'validAccessCode'));
        when(mockSecureStorage.read<String>(privateKey))
            .thenAnswer((_) async => (null, 'validPrivateKey'));

        final (failure, result) = await authService.login(accessCode: 'invalidAccessCode');

        expect(failure, isA<CacheFailure>());
        expect(failure?.message, invalidAccessCodePleaseTryAgain);
        expect(result, isNull);
      });

      test('should return CacheFailure when no session is recorded', () async {
        when(mockSecureStorage.read<String>(accessCodeKey))
            .thenAnswer((_) async => (null, null));
        when(mockSecureStorage.read<String>(privateKey))
            .thenAnswer((_) async => (null, null));

        final (failure, result) = await authService.login(accessCode: 'anyAccessCode');

        expect(failure, isA<CacheFailure>());
        expect(failure?.message, noSessionRecordedMsg);
        expect(result, isNull);
      });
    });

    group('register', () {
      test('should return true when registration is successful', () async {
        when(mockSecureStorage.write(accessCodeKey, Strings.empty))
            .thenAnswer((_) async => (null, true));
        when(mockSecureStorage.write(privateKey, Strings.empty))
            .thenAnswer((_) async => (null, true));

        final (failure, success) = await authService.register(
          accessCode: 'newAccessCode',
          priKey: 'newPrivateKey',
        );

        expect(failure, isNull);
        expect(success, true);
      });

      test('should return failure when writing access code fails', () async {
        when(mockSecureStorage.write(accessCodeKey, Strings.empty))
            .thenAnswer((_) async => (const CacheFailure(message: 'Error writing access code'), false));

        final (failure, success) = await authService.register(accessCode: 'newAccessCode', priKey: 'newPrivateKey');

        expect(failure, isNotNull);
        expect(success, false);
      });

      test('should return failure when writing private key fails', () async {
        when(mockSecureStorage.write(accessCodeKey, Strings.empty))
            .thenAnswer((_) async => (null, true));
        when(mockSecureStorage.write(privateKey, Strings.empty))
            .thenAnswer((_) async => (const CacheFailure(message: 'Error writing private key'), false));

        final (failure, success) = await authService.register(accessCode: 'newAccessCode', priKey: 'newPrivateKey');

        expect(failure, isNotNull);
        expect(success, false);
      });
    });

    group('setRemember', () {
      test('should set remember key and return true', () async {
        when(mockCacheStorage.setBool(rememberKey, true))
            .thenAnswer((_) async => true);

        final result = await authService.setRemember(true);

        expect(result, true);
        verify(mockCacheStorage.setBool(rememberKey, true)).called(1);
      });
    });

    group('remember', () {
      test('should return true if remember key is set', () {
        when(mockCacheStorage.getBool(rememberKey)).thenReturn(true);

        final result = authService.remember;

        expect(result, true);
      });

      test('should return false if remember key is not set', () {
        when(mockCacheStorage.getBool(rememberKey)).thenReturn(false);

        final result = authService.remember;

        expect(result, false);
      });
    });

    group('logout', () {
      test('should clear mnemonic and set remember to false', () async {
        when(mockCacheStorage.setBool(rememberKey, false)).thenAnswer((_) async => true);

        final result = await authService.logout();

        expect(result, true);
        expect(AuthService.mnemonic, isNull);
        verify(mockCacheStorage.setBool(rememberKey, false)).called(1);
      });
    });
  });
}
