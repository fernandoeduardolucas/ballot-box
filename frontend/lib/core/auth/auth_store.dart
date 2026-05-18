class AuthStore {
  AuthStore._();
  static final AuthStore instance = AuthStore._();

  String? _token;
  bool _isAdmin = false;

  String? get token => _token;
  bool get isAdmin => _isAdmin;
  bool get isAuthenticated => _token != null;

  void setSession({required String token, required bool isAdmin}) {
    _token = token;
    _isAdmin = isAdmin;
  }

  void clearToken() {
    _token = null;
    _isAdmin = false;
  }
}
