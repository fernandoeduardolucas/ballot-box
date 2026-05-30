import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_eleitoral_frontend/core/auth/auth_store.dart';

void main() {
  tearDown(() => AuthStore.instance.clearToken());

  test('stores voter NUT3 region from JWT payload', () {
    AuthStore.instance.setSession(
      token: _tokenWithPayload({'nut3Region': 'am-porto'}),
      isAdmin: false,
    );

    expect(AuthStore.instance.nut3Region, 'am-porto');
    expect(AuthStore.instance.isEligibleForScope(null), isTrue);
    expect(AuthStore.instance.isEligibleForScope('am-porto'), isTrue);
    expect(AuthStore.instance.isEligibleForScope('am-lisboa'), isFalse);
  });

  test('clears voter region on logout', () {
    AuthStore.instance.setSession(
      token: _tokenWithPayload({'nut3Region': 'am-porto'}),
      isAdmin: false,
    );

    AuthStore.instance.clearToken();

    expect(AuthStore.instance.token, isNull);
    expect(AuthStore.instance.nut3Region, isNull);
    expect(AuthStore.instance.isAuthenticated, isFalse);
  });
}

String _tokenWithPayload(Map<String, Object?> payload) {
  final header = _base64UrlJson({'alg': 'none', 'typ': 'JWT'});
  final body = _base64UrlJson(payload);
  return '$header.$body.signature';
}

String _base64UrlJson(Map<String, Object?> value) {
  return base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
}
