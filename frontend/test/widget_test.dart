import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_eleitoral_frontend/core/auth/auth_store.dart';
import 'package:sistema_eleitoral_frontend/features/election/data/election_service.dart';
import 'package:sistema_eleitoral_frontend/features/election/domain/election_eligibility.dart';

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

  test('filters regional elections for authenticated voters', () {
    final elections = [
      _election(scopeRegion: null, scopeLabel: 'Nacional'),
      _election(scopeRegion: 'am-porto', scopeLabel: 'Porto'),
      _election(scopeRegion: 'am-lisboa', scopeLabel: 'Lisboa'),
    ];

    final filtered = filterEligibleElections(
      elections,
      isAuthenticated: true,
      voterNut3Region: 'am-porto',
    );

    expect(filtered.map((election) => election.scopeRegion), [
      null,
      'am-porto',
    ]);
  });

  test('keeps all active elections visible before login', () {
    final elections = [
      _election(scopeRegion: null, scopeLabel: 'Nacional'),
      _election(scopeRegion: 'am-lisboa', scopeLabel: 'Lisboa'),
    ];

    final filtered = filterEligibleElections(
      elections,
      isAuthenticated: false,
      voterNut3Region: null,
    );

    expect(filtered, elections);
  });
}

ElectionItem _election(
    {required String? scopeRegion, required String scopeLabel}) {
  return ElectionItem(
    id: 'election-$scopeLabel',
    title: 'Election $scopeLabel',
    startDate: DateTime.utc(2026),
    endDate: DateTime.utc(2026, 12, 31),
    scopeRegion: scopeRegion,
    scopeLabel: scopeLabel,
  );
}

String _tokenWithPayload(Map<String, Object?> payload) {
  final header = _base64UrlJson({'alg': 'none', 'typ': 'JWT'});
  final body = _base64UrlJson(payload);
  return '$header.$body.signature';
}

String _base64UrlJson(Map<String, Object?> value) {
  return base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
}
