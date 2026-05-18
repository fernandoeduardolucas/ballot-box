import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sistema_eleitoral_frontend/core/theme/app_colors.dart';

class VoteScreen extends StatefulWidget {
  const VoteScreen({super.key});

  @override
  State<VoteScreen> createState() => _VoteScreenState();
}

class _Candidate {
  const _Candidate({
    required this.id,
    required this.number,
    required this.name,
    required this.party,
    required this.acronym,
    required this.partyColor,
    required this.imageUrl,
  });
  final int id;
  final int number;
  final String name;
  final String party;
  final String acronym;
  final Color partyColor;
  final String imageUrl;
}

class _VoteScreenState extends State<VoteScreen> {
  int? _selectedId;
  bool _voted = false;

  static const _candidates = [
    _Candidate(
      id: 0, number: 1,
      name: 'António Monteiro Silva',
      party: 'Partido da Democracia Social',
      acronym: 'PDS',
      partyColor: Color(0xFF1565C0),
      imageUrl: 'https://i.pravatar.cc/300?img=11',
    ),
    _Candidate(
      id: 1, number: 2,
      name: 'Maria João Fonseca',
      party: 'Aliança Nacional',
      acronym: 'AN',
      partyColor: Color(0xFFB71C1C),
      imageUrl: 'https://i.pravatar.cc/300?img=5',
    ),
    _Candidate(
      id: 2, number: 3,
      name: 'Carlos Eduardo Pereira',
      party: 'Movimento Independente',
      acronym: 'MI',
      partyColor: Color(0xFF2E7D32),
      imageUrl: 'https://i.pravatar.cc/300?img=8',
    ),
    _Candidate(
      id: 3, number: 4,
      name: 'Ana Cristina Lopes',
      party: 'União Progressista',
      acronym: 'UP',
      partyColor: Color(0xFFE65100),
      imageUrl: 'https://i.pravatar.cc/300?img=47',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final selected =
        _selectedId != null ? _candidates.firstWhere((c) => c.id == _selectedId) : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildEditorialHeader(),
          _StatusBar(voted: _voted),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!_voted) ...[
                        const _InstructionBanner(),
                        const SizedBox(height: 20),
                      ],
                      for (final c in _candidates)
                        _CandidateCard(
                          candidate: c,
                          isSelected: _selectedId == c.id,
                          disabled: _voted,
                          onTap: () => setState(() => _selectedId = c.id),
                        ),
                      const SizedBox(height: 8),
                      if (!_voted)
                        _VoteButton(
                          enabled: selected != null,
                          onVote: () => _confirmVote(selected!),
                        ),
                      if (_voted && selected != null)
                        _VotedBanner(candidate: selected),
                      const SizedBox(height: 32),
                      _buildFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorialHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.oxblood, width: 3),
          bottom: BorderSide(color: AppColors.ink, width: 2),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 16, 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
                tooltip: 'Voltar',
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      'VotoSeguro — Boletim de Voto',
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 10, letterSpacing: 1.8, color: AppColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    RichText(
                      text: TextSpan(children: [
                        TextSpan(
                          text: 'Eleições Presidenciais ',
                          style: GoogleFonts.instrumentSerif(
                            fontSize: 24, color: AppColors.ink,
                            letterSpacing: -0.4, height: 1.1,
                          ),
                        ),
                        TextSpan(
                          text: '2026.',
                          style: GoogleFonts.instrumentSerif(
                            fontSize: 24, color: AppColors.oxblood,
                            fontStyle: FontStyle.italic,
                            letterSpacing: -0.4, height: 1.1,
                          ),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border(left: BorderSide(color: AppColors.oxblood, width: 3)),
      ),
      child: RichText(
        text: TextSpan(children: [
          TextSpan(
            text: 'O seu voto é ',
            style: GoogleFonts.atkinsonHyperlegible(
              fontSize: 12, color: AppColors.inkMuted, height: 1.6,
            ),
          ),
          TextSpan(
            text: 'secreto',
            style: GoogleFonts.instrumentSerif(
              fontSize: 13, color: AppColors.oxblood,
              fontStyle: FontStyle.italic,
            ),
          ),
          TextSpan(
            text: ', ',
            style: GoogleFonts.atkinsonHyperlegible(
              fontSize: 12, color: AppColors.inkMuted,
            ),
          ),
          TextSpan(
            text: 'cifrado',
            style: GoogleFonts.instrumentSerif(
              fontSize: 13, color: AppColors.oxblood,
              fontStyle: FontStyle.italic,
            ),
          ),
          TextSpan(
            text: ' e ',
            style: GoogleFonts.atkinsonHyperlegible(
              fontSize: 12, color: AppColors.inkMuted,
            ),
          ),
          TextSpan(
            text: 'verificável',
            style: GoogleFonts.instrumentSerif(
              fontSize: 13, color: AppColors.oxblood,
              fontStyle: FontStyle.italic,
            ),
          ),
          TextSpan(
            text: '. O endereço IP não é associado ao boletim.',
            style: GoogleFonts.atkinsonHyperlegible(
              fontSize: 12, color: AppColors.inkMuted, height: 1.6,
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _confirmVote(_Candidate candidate) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppColors.hairline),
        ),
        titlePadding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CONFIRMAR VOTO',
              style: GoogleFonts.ibmPlexSans(
                fontSize: 10, fontWeight: FontWeight.w700,
                letterSpacing: 2, color: AppColors.inkMuted,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Esta acção é irreversível.',
              style: GoogleFonts.instrumentSerif(
                fontSize: 22, color: AppColors.ink, letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
        content: Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerLow,
            border: Border(left: BorderSide(color: AppColors.gold, width: 3)),
          ),
          child: Text(
            '"${candidate.name}"',
            style: GoogleFonts.instrumentSerif(
              fontSize: 18, color: AppColors.ink,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    side: const BorderSide(color: AppColors.hairlineStrong),
                    foregroundColor: AppColors.ink,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: Text(
                    'Cancelar',
                    style: GoogleFonts.ibmPlexSans(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: Text(
                    'CONFIRMAR',
                    style: GoogleFonts.ibmPlexSans(
                      fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) setState(() => _voted = true);
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.voted});
  final bool voted;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.successContainer,
              border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'VOTAÇÃO ABERTA',
                  style: GoogleFonts.ibmPlexMono(
                    color: AppColors.success,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          const Icon(Icons.timer_outlined, size: 13, color: AppColors.inkMuted),
          const SizedBox(width: 5),
          Text(
            'Encerra em 2h 45m',
            style: GoogleFonts.ibmPlexMono(color: AppColors.inkMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _InstructionBanner extends StatelessWidget {
  const _InstructionBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.goldContainer,
        border: Border(left: BorderSide(color: AppColors.gold, width: 3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.gold, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Selecione o candidato da sua preferência e prima "Votar". O seu voto é secreto e inviolável.',
              style: GoogleFonts.atkinsonHyperlegible(
                color: AppColors.onGoldContainer, fontSize: 13, height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({
    required this.candidate,
    required this.isSelected,
    required this.disabled,
    required this.onTap,
  });
  final _Candidate candidate;
  final bool isSelected;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? candidate.partyColor.withValues(alpha: 0.06)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isSelected
                  ? candidate.partyColor.withValues(alpha: 0.7)
                  : AppColors.hairline,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: candidate.partyColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: candidate.partyColor.withValues(alpha: 0.4),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${candidate.number}',
                  style: TextStyle(
                    color: candidate.partyColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              ClipOval(
                child: Image.network(
                  candidate.imageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 60,
                    height: 60,
                    color: AppColors.surfaceContainerLow,
                    child: const Icon(Icons.person_rounded, color: AppColors.inkDim, size: 28),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      candidate.name,
                      style: GoogleFonts.ibmPlexSans(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: candidate.partyColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            candidate.acronym,
                            style: GoogleFonts.ibmPlexSans(
                              color: candidate.partyColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            candidate.party,
                            style: GoogleFonts.ibmPlexSans(
                              color: AppColors.inkMuted, fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              AnimatedOpacity(
                opacity: isSelected ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: candidate.partyColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoteButton extends StatelessWidget {
  const _VoteButton({required this.enabled, required this.onVote});
  final bool enabled;
  final VoidCallback onVote;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: enabled ? 1 : 0.35,
      duration: const Duration(milliseconds: 200),
      child: Column(
        children: [
          FilledButton.icon(
            onPressed: enabled ? onVote : null,
            icon: const Icon(Icons.how_to_vote_rounded),
            label: Text(
              'VOTAR',
              style: GoogleFonts.ibmPlexSans(
                fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 2,
              ),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _VotedBanner extends StatelessWidget {
  const _VotedBanner({required this.candidate});
  final _Candidate candidate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.successContainer,
        border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          const Icon(Icons.verified_rounded, color: AppColors.success, size: 44),
          const SizedBox(height: 14),
          Text(
            'Voto Registado.',
            style: GoogleFonts.instrumentSerif(
              color: AppColors.success, fontSize: 22, letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'O seu voto em ${candidate.name} foi registado com sucesso.',
            style: GoogleFonts.atkinsonHyperlegible(
              color: AppColors.success, fontSize: 13, height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
