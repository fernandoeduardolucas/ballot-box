import 'package:sistema_eleitoral_frontend/core/services/graphql_service.dart';

class CandidateItem {
  CandidateItem({
    required this.id,
    required this.electionId,
    required this.name,
    this.party,
    this.photoUrl,
    required this.number,
  });

  final String id;
  final String electionId;
  final String name;
  final String? party;
  final String? photoUrl;
  final int number;

  factory CandidateItem.fromJson(Map<String, dynamic> json) => CandidateItem(
        id:         json['id'] as String,
        electionId: json['electionId'] as String,
        name:       json['name'] as String,
        party:      json['party'] as String?,
        photoUrl:   json['photoUrl'] as String?,
        number:     json['number'] as int,
      );
}

class ElectionItem {
  ElectionItem({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
  });

  final String id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;

  factory ElectionItem.fromJson(Map<String, dynamic> json) => ElectionItem(
        id:        json['id'] as String,
        title:     json['title'] as String,
        startDate: DateTime.parse(json['startDate'] as String),
        endDate:   DateTime.parse(json['endDate'] as String),
      );
}

class VoteCountItem {
  VoteCountItem({
    required this.candidateId,
    required this.candidateName,
    required this.count,
  });

  final String candidateId;
  final String candidateName;
  final int count;

  factory VoteCountItem.fromJson(Map<String, dynamic> json) => VoteCountItem(
        candidateId:   json['candidateId'] as String,
        candidateName: json['candidateName'] as String,
        count:         json['count'] as int,
      );
}

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

  Future<List<ElectionItem>> listAllElections() async {
    const query = r'''
      query {
        allElections {
          id
          title
          startDate
          endDate
        }
      }
    ''';
    final result = await _graphql.execute(query: query);
    final list = result['data']?['allElections'] as List<dynamic>?;
    if (list == null) throw Exception('Resposta inválida do servidor.');
    return list.cast<Map<String, dynamic>>().map(ElectionItem.fromJson).toList();
  }

  Future<List<CandidateItem>> listElectionCandidates(String electionId) async {
    const query = r'''
      query ElectionCandidates($electionId: String!) {
        electionCandidates(electionId: $electionId) {
          id
          electionId
          name
          party
          photoUrl
          number
        }
      }
    ''';
    final result = await _graphql.execute(query: query, variables: {'electionId': electionId});
    final list = result['data']?['electionCandidates'] as List<dynamic>?;
    if (list == null) throw Exception('Resposta inválida do servidor.');
    return list.cast<Map<String, dynamic>>().map(CandidateItem.fromJson).toList();
  }

  Future<List<ElectionItem>> listActiveElections() async {
    const query = r'''
      query {
        activeElections {
          id
          title
          startDate
          endDate
        }
      }
    ''';

    final result = await _graphql.execute(query: query);
    final list = result['data']?['activeElections'] as List<dynamic>?;
    if (list == null) throw Exception('Resposta inválida do servidor.');

    return list
        .cast<Map<String, dynamic>>()
        .map(ElectionItem.fromJson)
        .toList();
  }

  Future<List<VoteCountItem>> getElectionResults(String electionId) async {
    const query = r'''
      query ElectionResults($electionId: String!) {
        electionResults(electionId: $electionId) {
          candidateId
          candidateName
          count
        }
      }
    ''';
    final result = await _graphql.execute(query: query, variables: {'electionId': electionId});
    final list = result['data']?['electionResults'] as List<dynamic>?;
    if (list == null) throw Exception('Resposta inválida do servidor.');
    return list.cast<Map<String, dynamic>>().map(VoteCountItem.fromJson).toList();
  }
}

final class VoteScreenArgs {
  const VoteScreenArgs({required this.election, required this.candidates});
  final ElectionItem election;
  final List<CandidateItem> candidates;
}
