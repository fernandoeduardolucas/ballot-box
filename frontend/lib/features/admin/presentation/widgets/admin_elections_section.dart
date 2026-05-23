import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sistema_eleitoral_frontend/core/services/graphql_service.dart';
import 'package:sistema_eleitoral_frontend/core/theme/app_colors.dart';
import 'package:sistema_eleitoral_frontend/features/election/data/election_service.dart';

class AdminElectionsSection extends StatefulWidget {
  const AdminElectionsSection({super.key});

  @override
  State<AdminElectionsSection> createState() => _AdminElectionsSectionState();
}

class _AdminElectionsSectionState extends State<AdminElectionsSection> {
  final _service = ElectionService(GraphQLService(baseUrl: 'http://localhost:8080/graphql'));
  late Future<List<ElectionItem>> _electionsFuture;
  String? _expandedId;
  Future<List<CandidateItem>>? _candidatesFuture;

  @override
  void initState() {
    super.initState();
    _electionsFuture = _service.listAllElections();
  }

  void _toggleElection(ElectionItem election) {
    setState(() {
      if (_expandedId == election.id) {
        _expandedId = null;
        _candidatesFuture = null;
      } else {
        _expandedId = election.id;
        _candidatesFuture = _service.listElectionCandidates(election.id);
      }
    });
  }

  void _refresh() => setState(() {
    _expandedId = null;
    _candidatesFuture = null;
    _electionsFuture = _service.listAllElections();
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Section header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  border: Border.symmetric(horizontal: BorderSide(color: AppColors.hairline)),
                ),
                child: Row(children: [
                  Text('I.', style: GoogleFonts.instrumentSerif(fontSize: 18, color: AppColors.oxblood, fontStyle: FontStyle.italic)),
                  const SizedBox(width: 10),
                  Text('TODAS AS ELEIÇÕES', style: GoogleFonts.ibmPlexSans(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.8, color: AppColors.ink)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    color: AppColors.inkMuted,
                    onPressed: _refresh,
                    tooltip: 'Atualizar',
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.pushNamed(context, '/elections/create').then((_) => _refresh()),
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 36), padding: const EdgeInsets.symmetric(horizontal: 14)),
                    child: Text('+ Nova Eleição', style: GoogleFonts.ibmPlexSans(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                  ),
                ]),
              ),
              // Elections
              FutureBuilder<List<ElectionItem>>(
                future: _electionsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(60),
                      child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 1.5)),
                    );
                  }
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 32),
                        const SizedBox(height: 12),
                        Text(snapshot.error.toString(), textAlign: TextAlign.center,
                          style: GoogleFonts.atkinsonHyperlegible(fontSize: 13, color: AppColors.inkMuted)),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: Text('Tentar novamente', style: GoogleFonts.ibmPlexSans(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ])),
                    );
                  }
                  final elections = snapshot.data ?? [];
                  if (elections.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(60),
                      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.how_to_vote_outlined, color: AppColors.inkDim, size: 32),
                        const SizedBox(height: 16),
                        Text('Sem eleições registadas.', style: GoogleFonts.instrumentSerif(fontSize: 22, color: AppColors.ink)),
                        const SizedBox(height: 8),
                        Text('Crie a primeira eleição usando o botão acima.',
                          style: GoogleFonts.atkinsonHyperlegible(fontSize: 14, color: AppColors.inkMuted)),
                      ])),
                    );
                  }
                  return Column(
                    children: elections.map((e) => _ElectionAdminRow(
                      election: e,
                      isExpanded: _expandedId == e.id,
                      candidatesFuture: _expandedId == e.id ? _candidatesFuture : null,
                      onToggle: () => _toggleElection(e),
                    )).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ElectionAdminRow extends StatelessWidget {
  const _ElectionAdminRow({
    required this.election,
    required this.isExpanded,
    required this.candidatesFuture,
    required this.onToggle,
  });
  final ElectionItem election;
  final bool isExpanded;
  final Future<List<CandidateItem>>? candidatesFuture;
  final VoidCallback onToggle;

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final ended = now.isAfter(election.endDate);
    final active = now.isAfter(election.startDate) && !ended;

    return Column(children: [
      MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 20, 16),
            decoration: BoxDecoration(
              color: isExpanded ? AppColors.surfaceContainerLow : AppColors.surface,
              border: const Border(bottom: BorderSide(color: AppColors.hairline)),
            ),
            child: Row(children: [
              // Status chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: ended
                      ? AppColors.surfaceContainerHigh
                      : active
                          ? AppColors.goldContainer.withValues(alpha: 0.3)
                          : AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  ended ? 'ENCERRADA' : active ? 'EM CURSO' : 'AGENDADA',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 9, letterSpacing: 1.2, fontWeight: FontWeight.w700,
                    color: ended ? AppColors.inkDim : active ? AppColors.inkSubtle : AppColors.inkMuted,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(election.title, style: GoogleFonts.instrumentSerif(
                    fontSize: 20, color: AppColors.ink, letterSpacing: -0.2,
                  )),
                  Text(
                    '${_fmt(election.startDate)} — ${_fmt(election.endDate)}',
                    style: GoogleFonts.ibmPlexMono(fontSize: 11, color: AppColors.inkMuted, letterSpacing: 0.3),
                  ),
                ]),
              ),
              Icon(
                isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                color: AppColors.inkMuted, size: 20,
              ),
            ]),
          ),
        ),
      ),
      if (isExpanded)
        _ElectionInlineDetail(election: election, candidatesFuture: candidatesFuture),
    ]);
  }
}

class _ElectionInlineDetail extends StatelessWidget {
  const _ElectionInlineDetail({required this.election, required this.candidatesFuture});
  final ElectionItem election;
  final Future<List<CandidateItem>>? candidatesFuture;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.hairlineStrong)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Candidates sub-header
        Container(
          padding: const EdgeInsets.fromLTRB(40, 10, 24, 10),
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerLow,
            border: Border(bottom: BorderSide(color: AppColors.hairline)),
          ),
          child: Row(children: [
            Text('Candidatos', style: GoogleFonts.ibmPlexSans(
              fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.6, color: AppColors.inkMuted,
            )),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/candidates/add', arguments: election.id),
              icon: const Icon(Icons.person_add_rounded, size: 14),
              label: Text('Adicionar Candidato', style: GoogleFonts.ibmPlexSans(
                fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1,
              )),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 34),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ]),
        ),
        // Candidates list
        if (candidatesFuture == null)
          const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(strokeWidth: 1.5)))
        else
          FutureBuilder<List<CandidateItem>>(
            future: candidatesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 1.5)),
                );
              }
              final candidates = snapshot.data ?? [];
              if (candidates.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(40, 20, 40, 20),
                  child: Text('Sem candidatos registados nesta eleição.',
                    style: GoogleFonts.atkinsonHyperlegible(fontSize: 13, color: AppColors.inkMuted)),
                );
              }
              return Column(
                children: candidates.map((c) => Container(
                  padding: const EdgeInsets.fromLTRB(40, 12, 24, 12),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(bottom: BorderSide(color: AppColors.hairline)),
                  ),
                  child: Row(children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: c.photoUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: Image.network(c.photoUrl!, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(child: Text('${c.number}',
                                  style: GoogleFonts.ibmPlexMono(fontSize: 12, color: AppColors.inkDim))),
                              ),
                            )
                          : Center(child: Text('${c.number}',
                              style: GoogleFonts.ibmPlexMono(fontSize: 12, color: AppColors.inkDim))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(c.name, style: GoogleFonts.ibmPlexSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
                      if (c.party != null)
                        Text(c.party!, style: GoogleFonts.ibmPlexSans(fontSize: 12, color: AppColors.inkMuted)),
                    ])),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.hairlineStrong),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text('Nº ${c.number}', style: GoogleFonts.ibmPlexMono(
                        fontSize: 11, color: AppColors.inkSubtle, fontWeight: FontWeight.w600,
                      )),
                    ),
                  ]),
                )).toList(),
              );
            },
          ),
      ]),
    );
  }
}
