import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sistema_eleitoral_frontend/core/auth/auth_store.dart';

class GraphQLService {
  const GraphQLService({required this.baseUrl});

  final String baseUrl;

  Future<Map<String, dynamic>> execute({
    required String query,
    Map<String, dynamic>? variables,
  }) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = AuthStore.instance.token;
    if (token != null) headers['Authorization'] = 'Bearer $token';

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: headers,
      body: jsonEncode({
        'query': query,
        if (variables != null) 'variables': variables,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Erro HTTP ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    final errors = body['errors'] as List<dynamic>?;
    if (errors != null && errors.isNotEmpty) {
      throw Exception(errors.first['message']?.toString() ?? 'Erro GraphQL desconhecido');
    }

    return body;
  }
}
