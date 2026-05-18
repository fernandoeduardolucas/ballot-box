import 'package:sistema_eleitoral_frontend/core/services/graphql_service.dart';

sealed class AddCandidateResult {}

final class AddCandidateSuccess extends AddCandidateResult {
  AddCandidateSuccess({
    required this.id,
    required this.electionId,
    required this.name,
    required this.number,
    this.party,
    this.photoUrl,
  });

  final String id;
  final String electionId;
  final String name;
  final int number;
  final String? party;
  final String? photoUrl;
}

final class AddCandidateFailure extends AddCandidateResult {
  AddCandidateFailure({required this.message});
  final String message;
}

class CandidateService {
  CandidateService(this._graphql);

  final GraphQLService _graphql;

  Future<AddCandidateResult> addCandidate({
    required String electionId,
    required String name,
    required int number,
    String? party,
    String? photoUrl,
  }) async {
    const mutation = r'''
      mutation AddCandidate(
        $electionId: String!
        $name: String!
        $number: Int!
        $party: String
        $photoUrl: String
      ) {
        addCandidate(
          electionId: $electionId
          name: $name
          number: $number
          party: $party
          photoUrl: $photoUrl
        ) {
          ... on CandidatePayload {
            id
            electionId
            name
            number
            party
            photoUrl
          }
          ... on CandidateError {
            message
          }
        }
      }
    ''';

    final result = await _graphql.execute(
      query: mutation,
      variables: {
        'electionId': electionId,
        'name': name,
        'number': number,
        if (party != null) 'party': party,
        if (photoUrl != null) 'photoUrl': photoUrl,
      },
    );

    final data = result['data']?['addCandidate'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Resposta inválida do servidor.');

    if (data.containsKey('id')) {
      return AddCandidateSuccess(
        id:         data['id'] as String,
        electionId: data['electionId'] as String,
        name:       data['name'] as String,
        number:     data['number'] as int,
        party:      data['party'] as String?,
        photoUrl:   data['photoUrl'] as String?,
      );
    }

    return AddCandidateFailure(
      message: data['message'] as String? ?? 'Erro desconhecido.',
    );
  }
}
