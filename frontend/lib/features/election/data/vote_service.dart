import 'package:sistema_eleitoral_frontend/core/services/graphql_service.dart';

const _kAlreadyVotedMessage = 'Já votou nesta eleição.';

sealed class CastVoteResult {
  const CastVoteResult();
}

final class CastVoteSuccess extends CastVoteResult {
  const CastVoteSuccess({
    required this.voteId,
    required this.electionId,
    required this.votedAt,
  });
  final String voteId;
  final String electionId;
  final String votedAt;
}

final class CastVoteAlreadyVoted extends CastVoteResult {
  const CastVoteAlreadyVoted();
}

final class CastVoteRateLimited extends CastVoteResult {
  const CastVoteRateLimited({required this.retryAfterSeconds});
  final int retryAfterSeconds;
}

final class CastVoteFailure extends CastVoteResult {
  const CastVoteFailure({required this.message});
  final String message;
}

class VoteCountItem {
  const VoteCountItem({
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
        count:         (json['count'] as num).toInt(),
      );
}

class VoteService {
  VoteService(this._graphql);

  final GraphQLService _graphql;

  Future<CastVoteResult> castVote({
    required String electionId,
    required String candidateId,
  }) async {
    const mutation = r'''
      mutation CastVote($electionId: String!, $candidateId: String!) {
        castVote(electionId: $electionId, candidateId: $candidateId) {
          ... on CastVoteSuccess {
            voteId
            electionId
            votedAt
          }
          ... on CastVoteError {
            message
          }
        }
      }
    ''';
    try {
      final result = await _graphql.execute(
        query: mutation,
        variables: {'electionId': electionId, 'candidateId': candidateId},
      );
      final data = result['data']?['castVote'] as Map<String, dynamic>?;
      if (data == null) {
        return const CastVoteFailure(message: 'Resposta inválida do servidor.');
      }
      if (data.containsKey('voteId')) {
        return CastVoteSuccess(
          voteId:     data['voteId'] as String,
          electionId: data['electionId'] as String,
          votedAt:    data['votedAt'] as String,
        );
      }
      final message = data['message'] as String? ?? 'Erro desconhecido.';
      if (message == _kAlreadyVotedMessage) return const CastVoteAlreadyVoted();
      return CastVoteFailure(message: message);
    } on RateLimitException catch (e) {
      return CastVoteRateLimited(retryAfterSeconds: e.retryAfterSeconds);
    } on Exception catch (e) {
      return CastVoteFailure(message: e.toString());
    }
  }

  Future<List<VoteCountItem>> getVoteResults(String electionId) async {
    const query = r'''
      query ElectionResults($electionId: String!) {
        electionResults(electionId: $electionId) {
          candidateId
          candidateName
          count
        }
      }
    ''';
    final result = await _graphql.execute(
      query: query,
      variables: {'electionId': electionId},
    );
    final list = result['data']?['electionResults'] as List<dynamic>?;
    if (list == null) throw Exception('Resposta inválida do servidor.');
    return list.cast<Map<String, dynamic>>().map(VoteCountItem.fromJson).toList();
  }
}
