import 'package:sistema_eleitoral_frontend/core/services/graphql_service.dart';

sealed class CreateElectionResult {}

final class CreateElectionSuccess extends CreateElectionResult {
  CreateElectionSuccess({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
  });
  final String id;
  final String title;
  final String startDate;
  final String endDate;
}

final class CreateElectionFailure extends CreateElectionResult {
  CreateElectionFailure({required this.message});
  final String message;
}

class ElectionService {
  ElectionService(this._graphql);

  final GraphQLService _graphql;

  Future<CreateElectionResult> createElection({
    required String title,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    const mutation = r'''
      mutation CreateElection($title: String!, $startDate: String!, $endDate: String!) {
        createElection(title: $title, startDate: $startDate, endDate: $endDate) {
          ... on ElectionPayload {
            id
            title
            startDate
            endDate
          }
          ... on ElectionError {
            message
          }
        }
      }
    ''';

    final result = await _graphql.execute(
      query: mutation,
      variables: {
        'title': title,
        'startDate': startDate.toUtc().toIso8601String(),
        'endDate': endDate.toUtc().toIso8601String(),
      },
    );

    final data = result['data']?['createElection'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Resposta inválida do servidor.');

    if (data.containsKey('id')) {
      return CreateElectionSuccess(
        id: data['id'] as String,
        title: data['title'] as String,
        startDate: data['startDate'] as String,
        endDate: data['endDate'] as String,
      );
    }

    return CreateElectionFailure(
      message: data['message'] as String? ?? 'Erro desconhecido.',
    );
  }
}
