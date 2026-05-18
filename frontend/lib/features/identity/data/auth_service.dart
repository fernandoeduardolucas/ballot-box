import 'package:sistema_eleitoral_frontend/core/services/graphql_service.dart';

// ─── Login ────────────────────────────────────────────────────────────────────

sealed class LoginResult {}

final class LoginSuccess extends LoginResult {
  LoginSuccess({required this.token, required this.isAdmin});
  final String token;
  final bool isAdmin;
}

final class LoginFailure extends LoginResult {
  LoginFailure({required this.message});
  final String message;
}

// ─── Register ─────────────────────────────────────────────────────────────────

sealed class RegisterResult {}

final class RegisterSuccess extends RegisterResult {}

final class RegisterFailure extends RegisterResult {
  RegisterFailure({required this.message});
  final String message;
}

// ─── Service ──────────────────────────────────────────────────────────────────

class AuthService {
  AuthService(this._graphql);

  final GraphQLService _graphql;

  Future<LoginResult> login({
    required String civilId,
    required String password,
  }) async {
    const mutation = r'''
      mutation Login($civilId: String!, $password: String!) {
        loginVoter(civilId: $civilId, password: $password) {
          ... on LoginPayload {
            token
            isAdmin
          }
          ... on LoginError {
            message
          }
        }
      }
    ''';

    final result = await _graphql.execute(
      query: mutation,
      variables: {'civilId': civilId, 'password': password},
    );

    final data = result['data']?['loginVoter'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Resposta inválida do servidor.');

    if (data.containsKey('token')) {
      return LoginSuccess(
        token: data['token'] as String,
        isAdmin: data['isAdmin'] as bool? ?? false,
      );
    }
    return LoginFailure(message: data['message'] as String? ?? 'Erro desconhecido.');
  }

  Future<RegisterResult> register({
    required String civilId,
    required String password,
    required String nut3Region,
  }) async {
    const mutation = r'''
      mutation Register($civilId: String!, $password: String!, $nut3Region: String!) {
        registerVoter(civilId: $civilId, password: $password, nut3Region: $nut3Region) {
          ... on Voter {
            id
          }
          ... on RegistrationError {
            message
          }
        }
      }
    ''';

    final result = await _graphql.execute(
      query: mutation,
      variables: {'civilId': civilId, 'password': password, 'nut3Region': nut3Region},
    );

    final data = result['data']?['registerVoter'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Resposta inválida do servidor.');

    if (data.containsKey('id')) return RegisterSuccess();
    return RegisterFailure(message: data['message'] as String? ?? 'Erro desconhecido.');
  }
}
