import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sistema_eleitoral_frontend/core/auth/auth_store.dart';
import 'package:sistema_eleitoral_frontend/core/services/graphql_service.dart';
import 'package:sistema_eleitoral_frontend/core/theme/app_colors.dart';
import 'package:sistema_eleitoral_frontend/features/election/data/election_service.dart';

class ElectionDetailScreen extends StatefulWidget {
  const ElectionDetailScreen({super.key, required this.election});
  final ElectionItem election;

  @override
  State<ElectionDetailScreen> createState() => _ElectionDetailScreenState();
}

class _ElectionDetailScreenState extends State<ElectionDetailScreen> {
  final _service = ElectionService(GraphQLService(baseUrl: 'http://localhost:8080/graphql'));
  late Future<List<CandidateItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.listElectionCandidates(widget.election.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _Header(election: widget.election),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: FutureBuilder<List<CandidateItem>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 1.5),
                      );
                    }
                    if (snapshot.hasError) {
                      return _ErrorState(message: snapshot.error.toString());
                    }
                    final candidates = snapshot.data ?? [];
                    return CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(child: _InfoSection(election: widget.election)),
                        SliverToBoxAdapter(child: _CandidatesHeader(count: candidates.length)),
                        if (candidates.isEmpty)
                          const SliverToBoxAdapter(child: _EmptyCandidates())
                        else
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (_, i) => _CandidateRow(candidate: candidates[i]),
                              childCount: candidates.length,
                            ),
                          ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: FilledButton.icon(
                              onPressed: AuthStore.instance.isAuthenticated
                                  ? () => Navigator.pushNamed(context, '/elections/vote',
                                        arguments: VoteScreenArgs(
                                          election: widget.election,
                                          candidates: candidates,
                                        ))
                                  : () => Navigator.pushNamed(context, '/auth/login'),
                              icon: const Icon(Icons.fingerprint_rounded, size: 16),
                              label: Text(
                                AuthStore.instance.isAuthenticated ? 'VOTAR' : 'ENTRAR PARA VOTAR',
                                style: GoogleFonts.ibmPlexSans(
                                  fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.6,
                                ),
                              ),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(double.infinity, 48),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.election});
  final ElectionItem election;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.oxblood, width: 3),
          bottom: BorderSide(color: AppColors.ink, width: 2),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (Navigator.canPop(context))
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, size: 20),
                      color: AppColors.ink,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('VotoSeguro — Detalhe da Eleição',
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 10, letterSpacing: 1.8, color: AppColors.inkMuted,
                        )),
                      const SizedBox(height: 6),
                      Text(election.title, style: GoogleFonts.instrumentSerif(
                        fontSize: 28, color: AppColors.ink, letterSpacing: -0.4, height: 1.1,
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Info section ──────────────────────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.election});
  final ElectionItem election;

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toUtc();
    final remaining = election.endDate.difference(now);
    final urgent = remaining.inHours < 24 && remaining.inSeconds > 0;
    final ended = now.isAfter(election.endDate);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.hairline)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: ended
                  ? AppColors.surfaceContainerHigh
                  : urgent
                      ? AppColors.oxbloodContainer
                      : AppColors.goldContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              ended ? 'ENCERRADA' : urgent ? 'ENCERRA HOJE' : 'EM CURSO',
              style: GoogleFonts.ibmPlexMono(
                fontSize: 9, letterSpacing: 1.4, fontWeight: FontWeight.w700,
                color: ended ? AppColors.inkMuted : urgent ? AppColors.oxblood : AppColors.inkSubtle,
              ),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _InfoCell(label: 'Abertura', value: _fmt(election.startDate))),
          const SizedBox(width: 24),
          Expanded(child: _InfoCell(label: 'Encerramento', value: _fmt(election.endDate))),
        ]),
        if (!ended) ...[
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: _progressValue(),
              minHeight: 3,
              backgroundColor: AppColors.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation(urgent ? AppColors.oxblood : AppColors.primary),
            ),
          ),
        ],
      ]),
    );
  }

  double _progressValue() {
    final total = election.endDate.difference(election.startDate).inMinutes;
    final elapsed = DateTime.now().toUtc().difference(election.startDate).inMinutes;
    if (total <= 0) return 0;
    return (elapsed / total).clamp(0.0, 1.0);
  }
}

class _InfoCell extends StatelessWidget {
  const _InfoCell({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.ibmPlexSans(
        fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.6, color: AppColors.inkMuted,
      )),
      const SizedBox(height: 4),
      Text(value, style: GoogleFonts.ibmPlexMono(
        fontSize: 13, color: AppColors.ink, letterSpacing: 0.2,
      )),
    ]);
  }
}

// ── Candidates ────────────────────────────────────────────────────────────────

class _CandidatesHeader extends StatelessWidget {
  const _CandidatesHeader({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border.symmetric(horizontal: BorderSide(color: AppColors.hairline)),
      ),
      child: Row(children: [
        Text('I.', style: GoogleFonts.instrumentSerif(
          fontSize: 18, color: AppColors.oxblood, fontStyle: FontStyle.italic,
        )),
        const SizedBox(width: 10),
        Text('CANDIDATOS', style: GoogleFonts.ibmPlexSans(
          fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.8, color: AppColors.ink,
        )),
        const Spacer(),
        Text('$count inscritos', style: GoogleFonts.ibmPlexMono(
          fontSize: 10, color: AppColors.inkMuted, letterSpacing: 1,
        )),
      ]),
    );
  }
}

class _CandidateRow extends StatelessWidget {
  const _CandidateRow({required this.candidate});
  final CandidateItem candidate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.hairline)),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(2),
          ),
          child: candidate.photoUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Image.network(candidate.photoUrl!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _AvatarPlaceholder(number: candidate.number),
                  ),
                )
              : _AvatarPlaceholder(number: candidate.number),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(candidate.name, style: GoogleFonts.instrumentSerif(
              fontSize: 18, color: AppColors.ink, letterSpacing: -0.2,
            )),
            if (candidate.party != null)
              Text(candidate.party!, style: GoogleFonts.ibmPlexSans(
                fontSize: 12, color: AppColors.inkMuted,
              )),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.hairlineStrong),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text('Nº ${candidate.number}', style: GoogleFonts.ibmPlexMono(
            fontSize: 12, color: AppColors.inkSubtle, fontWeight: FontWeight.w600,
          )),
        ),
      ]),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder({required this.number});
  final int number;

  @override
  Widget build(BuildContext context) => Center(
    child: Text('$number', style: GoogleFonts.instrumentSerif(
      fontSize: 18, color: AppColors.inkDim,
    )),
  );
}

class _EmptyCandidates extends StatelessWidget {
  const _EmptyCandidates();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Text('Ainda não foram inscritos candidatos.',
          style: GoogleFonts.atkinsonHyperlegible(
            fontSize: 14, color: AppColors.inkMuted,
          )),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 32),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center,
            style: GoogleFonts.atkinsonHyperlegible(fontSize: 13, color: AppColors.inkMuted)),
        ]),
      ),
    );
  }
}
