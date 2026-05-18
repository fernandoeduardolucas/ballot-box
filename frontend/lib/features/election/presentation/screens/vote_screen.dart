import 'package:flutter/material.dart';
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
      backgroundColor: AppColors.navy,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.offWhite),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ELEIÇÕES PRESIDENCIAIS 2026',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.gold,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              'Selecione o seu candidato',
              style: TextStyle(fontSize: 15, color: AppColors.offWhite),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.gold.withValues(alpha: 0.3)),
        ),
      ),
      body: Column(
        children: [
          const _StatusBar(),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _InstructionBanner(),
                      const SizedBox(height: 20),
                      for (final c in _candidates)
                        _CandidateCard(
                          candidate: c,
                          isSelected: _selectedId == c.id,
                          disabled: _voted,
                          onTap: () => setState(() => _selectedId = c.id),
                        ),
                      const SizedBox(height: 24),
                      if (!_voted)
                        _VoteButton(
                          enabled: selected != null,
                          onVote: () => _confirmVote(selected!),
                        ),
                      if (_voted && selected != null)
                        _VotedBanner(candidate: selected),
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

  Future<void> _confirmVote(_Candidate candidate) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.navySurf,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.gold.withValues(alpha: 0.3)),
        ),
        title: const Text(
          'Confirmar Voto',
          style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Confirma o seu voto no candidato:\n\n"${candidate.name}"\n\nEsta ação é irreversível.',
          style: const TextStyle(color: AppColors.offWhite, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.subtle)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar Voto'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) setState(() => _voted = true);
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _StatusBar extends StatelessWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.navyLight,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1B3A20),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF2E7D32)),
            ),
            child: const Row(
              children: [
                _Dot(color: Color(0xFF4CAF50)),
                SizedBox(width: 6),
                Text(
                  'VOTAÇÃO ABERTA',
                  style: TextStyle(
                    color: Color(0xFF81C784),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          const Icon(Icons.timer_outlined, size: 13, color: AppColors.subtle),
          const SizedBox(width: 5),
          const Text(
            'Encerra em 2h 45m',
            style: TextStyle(color: AppColors.subtle, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) =>
      Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

class _InstructionBanner extends StatelessWidget {
  const _InstructionBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.22)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.gold, size: 18),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Selecione o candidato da sua preferência e prima "Votar". O seu voto é secreto e inviolável.',
              style: TextStyle(color: AppColors.offWhite, fontSize: 13, height: 1.5),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? candidate.partyColor.withValues(alpha: 0.10)
                : AppColors.navySurf,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? candidate.partyColor : const Color(0xFF1E2D42),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: candidate.partyColor.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(color: candidate.partyColor.withValues(alpha: 0.5)),
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
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 64,
                    height: 64,
                    color: AppColors.navyLight,
                    child: const Icon(Icons.person_rounded, color: AppColors.subtle, size: 30),
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
                      style: const TextStyle(
                        color: AppColors.offWhite,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: candidate.partyColor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            candidate.acronym,
                            style: TextStyle(
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
                            style: const TextStyle(color: AppColors.subtle, fontSize: 12),
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
                  decoration: BoxDecoration(color: candidate.partyColor, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
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
      child: FilledButton.icon(
        onPressed: enabled ? onVote : null,
        icon: const Icon(Icons.how_to_vote_rounded),
        label: const Text(
          'Votar',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.navy,
        ),
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
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF0C2010),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2E7D32)),
      ),
      child: Column(
        children: [
          const Icon(Icons.verified_rounded, color: Color(0xFF4CAF50), size: 48),
          const SizedBox(height: 16),
          const Text(
            'Voto Registado com Sucesso',
            style: TextStyle(
              color: Color(0xFF81C784),
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'O seu voto em ${candidate.name} foi registado com sucesso e é inviolável.',
            style: const TextStyle(color: AppColors.offWhite, fontSize: 13, height: 1.6),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
