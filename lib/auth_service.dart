import 'package:core/core.dart';
import 'package:dependencies/dependencies.dart';

const noSessionRecordedMsg = 'No session recorded';
const invalidAccessCodePleaseTryAgain = 'Invalid access code, please try again';
const rememberKey = 'remember_key';

const _mnemonicTest = 'still more purpose seminar sponsor section sibling apology circle more dutch casino';

@singleton
class AuthService {
  final ISecureStorage secureStorage;
  final ICacheStorage cacheStorage;
  static String? mnemonic;

  AuthService(this.secureStorage, this.cacheStorage);

  Future<(Failure?, (String, String)?)> login({
    String? accessCode,
    bool biometrics = false,
    bool remember = false,
    bool testing = false,
  }) async {
    if (testing) {
      mnemonic = _mnemonicTest;
      register(accessCode: accessCode!, priKey: mnemonic!);

      return (null, (accessCode, mnemonic!));
    }

    final accCod = await secureStorage.read<String>(accessCodeKey);
    final priKey = await secureStorage.read<String>(privateKey);

    if (accCod.$2 != null && (accCod.$2 == accessCode || biometrics || remember) && priKey.$2 != null) {
      mnemonic = priKey.$2!;

      return (null, (accCod.$2!, priKey.$2!));
    } else if (accCod.$2 != null && accCod.$2 != accessCode && !biometrics) {
      return (const CacheFailure(message: invalidAccessCodePleaseTryAgain), null);
    } else {
      return (const CacheFailure(message: noSessionRecordedMsg), null);
    }
  }

  Future<(Failure?, bool)> register({
    required String accessCode,
    required String priKey,
  }) async {
    final passCached = await secureStorage.write(accessCodeKey, accessCode);
    if (passCached.$2) {
      final priKeyCached = await secureStorage.write(privateKey, priKey);

      if (priKeyCached.$2) {
        mnemonic = priKey;

        return (null, true);
      } else {
        return (priKeyCached.$1, false);
      }

    } else {
      return (passCached.$1, false);
    }
  }

  Future<bool> setRemember(bool value) async {
    return await cacheStorage.setBool(rememberKey, value);
  }

  bool get remember {
    return cacheStorage.getBool(rememberKey) ?? false;
  }

  Future<bool> logout({required bool synchronized}) async {
    mnemonic = null;

    return await setRemember(false);
  }
}