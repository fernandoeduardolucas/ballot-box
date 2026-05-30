import 'dart:convert';

import 'package:sistema_eleitoral_frontend/features/election/domain/election_eligibility.dart';

class AuthStore {
  AuthStore._();
  static final AuthStore instance = AuthStore._();

  String? _token;
  String? _nut3Region;
  bool _isAdmin = false;

  String? get token => _token;
  String? get nut3Region => _nut3Region;
  bool get isAdmin => _isAdmin;
  bool get isAuthenticated => _token != null;

  void setSession({required String token, required bool isAdmin}) {
    _token = token;
    _nut3Region = _readNut3Region(token);
    _isAdmin = isAdmin;
  }

  void clearToken() {
    _token = null;
    _nut3Region = null;
    _isAdmin = false;
  }

  bool isEligibleForScope(String? scopeRegion) {
    return isEligibleForElectionScope(
      voterNut3Region: _nut3Region,
      electionScopeRegion: scopeRegion,
    );
  }

  String? _readNut3Region(String token) {
    final parts = token.split('.');
    if (parts.length < 2) return null;

    try {
      final payload =
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final data = jsonDecode(payload) as Map<String, dynamic>;
      return data['nut3Region'] as String?;
    } catch (_) {
      return null;
    }
  }
}
