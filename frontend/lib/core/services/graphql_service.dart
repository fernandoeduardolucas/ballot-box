import 'dart:convert';
import 'package:http/http.dart' as http;

class GraphQLService {
  const GraphQLService({required this.baseUrl});

  final String baseUrl;

  Future<Map<String, dynamic>> execute({
    required String query,
    Map<String, dynamic>? variables,
  }) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
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
