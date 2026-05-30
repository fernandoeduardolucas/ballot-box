import 'package:sistema_eleitoral_frontend/features/election/data/election_service.dart';

bool isEligibleForElectionScope({
  required String? voterNut3Region,
  required String? electionScopeRegion,
}) {
  if (electionScopeRegion == null) return true;
  return voterNut3Region == electionScopeRegion;
}

List<ElectionItem> filterEligibleElections(
  List<ElectionItem> elections, {
  required bool isAuthenticated,
  required String? voterNut3Region,
}) {
  if (!isAuthenticated) return elections;

  return elections
      .where(
        (election) => isEligibleForElectionScope(
          voterNut3Region: voterNut3Region,
          electionScopeRegion: election.scopeRegion,
        ),
      )
      .toList();
}
