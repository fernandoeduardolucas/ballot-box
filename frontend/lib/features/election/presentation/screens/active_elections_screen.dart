import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sistema_eleitoral_frontend/core/auth/auth_store.dart';
import 'package:sistema_eleitoral_frontend/core/services/graphql_service.dart';
import 'package:sistema_eleitoral_frontend/core/theme/app_colors.dart';
import 'package:sistema_eleitoral_frontend/features/election/data/election_service.dart';
import 'package:sistema_eleitoral_frontend/core/presentation/widgets/responsive_layout.dart';

class ActiveElectionsScreen extends StatefulWidget {
  const ActiveElectionsScreen({super.key});

  @override
  State<ActiveElectionsScreen> createState() => _ActiveElectionsScreenState();
}

class _ActiveElectionsScreenState extends State<ActiveElectionsScreen> {
  final _service = ElectionService(
    GraphQLService(baseUrl: 'http://localhost:8080/graphql'),
  );

  late Future<List<ElectionItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.listActiveElections();
  }

  void _refresh() => setState(() {
        _future = _service.listActiveElections();
      });

  void _logout() {
    AuthStore.instance.clearToken();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _ElectionsHeader(
              onRefresh: _refresh,
              isAuthenticated: AuthStore.instance.isAuthenticated,
              isAdmin: AuthStore.instance.isAdmin,
              onLogout: _logout,
            ),
            const _NavDivider(),
            Expanded(
              child: FutureBuilder<List<ElectionItem>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 1.5),
                    );
                  }
                  if (snapshot.hasError) {
                    return _ErrorState(
                      message: snapshot.error.toString(),
                      onRetry: _refresh,
                    );
                  }
                  final elections = snapshot.data!;
                  if (elections.isEmpty) return const _EmptyState();
                  return _ElectionsList(elections: elections);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _ElectionsHeader extends StatelessWidget {
  const _ElectionsHeader({
    required this.onRefresh,
    required this.isAuthenticated,
    required this.isAdmin,
    required this.onLogout,
  });
  final VoidCallback onRefresh;
  final bool isAuthenticated;
  final bool isAdmin;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.oxblood, width: 3),
          bottom: BorderSide(color: AppColors.ink, width: 2),
        ),
      ),
      child: Column(children: [
        // Dateline
        Container(
          color: AppColors.ink,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Row(children: [
            Text('VotoSeguro — Portal do Eleitor',
              style: GoogleFonts.ibmPlexMono(
                fontSize: 10, color: AppColors.surface, letterSpacing: 1.2,
              )),
            const Spacer(),
            _MiniLiveDot(),
            const SizedBox(width: 6),
            Text('ao vivo', style: GoogleFonts.ibmPlexMono(
              fontSize: 10, color: AppColors.goldContainer, letterSpacing: 1.2,
            )),
          ]),
        ),
        // Main bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Eleições em curso', style: GoogleFonts.ibmPlexSans(
                  fontSize: 10, fontWeight: FontWeight.w600,
                  letterSpacing: 2, color: AppColors.inkMuted,
                )),
                const SizedBox(height: 4),
                Text('VotoSeguro', style: GoogleFonts.instrumentSerif(
                  fontSize: 28, color: AppColors.ink, letterSpacing: -0.5,
                )),
              ]),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                color: AppColors.ink,
                onPressed: onRefresh,
                tooltip: 'Atualizar',
              ),
              const SizedBox(width: 4),
              if (isAuthenticated && isAdmin)
                OutlinedButton(
                  onPressed: () => Navigator.pushNamed(context, '/home'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: Text('Administração', style: GoogleFonts.ibmPlexSans(
                    fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2,
                  )),
                )
              else if (isAuthenticated)
                OutlinedButton(
                  onPressed: onLogout,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    foregroundColor: AppColors.oxblood,
                    side: const BorderSide(color: AppColors.oxblood),
                  ),
                  child: Text('Sair', style: GoogleFonts.ibmPlexSans(
                    fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2,
                  )),
                )
              else
                OutlinedButton(
                  onPressed: () => Navigator.pushNamed(context, '/auth/login'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: Text('Entrar', style: GoogleFonts.ibmPlexSans(
                    fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2,
                  )),
                ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _NavDivider extends StatelessWidget {
  const _NavDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(vertical: 10), // Dá um respiro visual
      child: const Row( // Row para os botões ficarem lado a lado
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavChip(label: 'Eleições activas', active: true),
          _NavChip(label: 'Resultados', active: false),
          _NavChip(label: 'Como votar', active: false),
        ],
      ),
    );
  }
}

class _NavChip extends StatelessWidget {
  const _NavChip({required this.label, required this.active});
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: active ? AppColors.oxblood : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: Text(label, style: GoogleFonts.ibmPlexSans(
        fontSize: 11, fontWeight: FontWeight.w600,
        letterSpacing: 1.4,
        color: active ? AppColors.ink : AppColors.inkMuted,
      )),
    );
  }
}

// ── Elections list ────────────────────────────────────────────────────────────

class _ElectionsList extends StatelessWidget {
  const _ElectionsList({required this.elections});
  final List<ElectionItem> elections;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _HeroSection(count: elections.length)),
        SliverToBoxAdapter(child: _SectionHeader(
          index: 'I',
          title: 'Eleições activas',
          kicker: '${elections.length} · ${_monthYear()}',
        )),
        if (ResponsiveLayout.isDesktop(context))
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 400,
                mainAxisExtent: 260,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => _ElectionItem(election: elections[i]),
                childCount: elections.length,
              ),
            ),
          )
        else
          SliverList(delegate: SliverChildBuilderDelegate(
            (context, i) => _ElectionItem(election: elections[i]),
            childCount: elections.length,
          )),
        const SliverToBoxAdapter(child: _ElectionsFooter()),
      ],
    );
  }

  String _monthYear() {
    final months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
                    'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    final now = DateTime.now();
    return '${months[now.month - 1]} ${now.year}';
  }
}

// ── Hero section ──────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 24, height: 1, color: AppColors.inkMuted),
          const SizedBox(width: 10),
          Text('ELEIÇÕES EM CURSO', style: GoogleFonts.ibmPlexSans(
            fontSize: 10, fontWeight: FontWeight.w600,
            letterSpacing: 2, color: AppColors.inkMuted,
          )),
        ]),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$count', style: GoogleFonts.instrumentSerif(
            fontSize: 88, color: AppColors.primary,
            height: 0.85, letterSpacing: -4,
          )),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                RichText(text: TextSpan(children: [
                  TextSpan(text: 'actos eleitorais\n', style: GoogleFonts.instrumentSerif(
                    fontSize: 24, color: AppColors.ink,
                    height: 1.1, letterSpacing: -0.4,
                  )),
                  TextSpan(text: 'a decorrer.', style: GoogleFonts.instrumentSerif(
                    fontSize: 24, color: AppColors.oxblood,
                    fontStyle: FontStyle.italic,
                    height: 1.1, letterSpacing: -0.4,
                  )),
                ])),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        Text(
          'Identifique-se com a Chave Móvel Digital ou Cartão de Cidadão. '
          'O voto é secreto, cifrado e verificável.',
          style: GoogleFonts.atkinsonHyperlegible(
            fontSize: 14, color: AppColors.inkMuted, height: 1.55,
          ),
        ),
      ]),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.index, required this.title, required this.kicker});
  final String index;
  final String title;
  final String kicker;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border.symmetric(
          horizontal: BorderSide(color: AppColors.hairline),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text('$index.', style: GoogleFonts.instrumentSerif(
            fontSize: 18, color: AppColors.oxblood, fontStyle: FontStyle.italic,
          )),
          const SizedBox(width: 10),
          Text(title.toUpperCase(), style: GoogleFonts.ibmPlexSans(
            fontSize: 10, fontWeight: FontWeight.w700,
            letterSpacing: 1.8, color: AppColors.ink,
          )),
          const Spacer(),
          Text(kicker, style: GoogleFonts.ibmPlexMono(
            fontSize: 10, color: AppColors.inkMuted, letterSpacing: 1,
          )),
        ],
      ),
    );
  }
}

// ── Election item ─────────────────────────────────────────────────────────────

class _ElectionItem extends StatelessWidget {
  const _ElectionItem({required this.election});
  final ElectionItem election;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final remaining = election.endDate.difference(now);
    final urgent = remaining.inHours < 24;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: isDesktop
            ? Border.all(color: AppColors.hairline)
            : const Border(bottom: BorderSide(color: AppColors.hairline)),
        borderRadius: isDesktop ? BorderRadius.circular(6) : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Type kicker
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Eleição Ativa', style: GoogleFonts.ibmPlexSans(
              fontSize: 9.5, fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
              color: urgent ? AppColors.oxblood : AppColors.inkMuted,
            )),
            if (urgent)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.oxbloodContainer,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text('Encerra hoje', style: GoogleFonts.ibmPlexSans(
                  fontSize: 10, fontWeight: FontWeight.w600,
                  letterSpacing: 1.2, color: AppColors.onOxbloodContainer,
                )),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Title
        Text(election.title, style: GoogleFonts.instrumentSerif(
          fontSize: 26, color: AppColors.ink,
          letterSpacing: -0.4, height: 1.1,
        )),
        const SizedBox(height: 4),

        // Date range
        Text(
          '${_fmt(election.startDate)} — ${_fmt(election.endDate)}',
          style: GoogleFonts.ibmPlexMono(
            fontSize: 11, color: AppColors.inkMuted, letterSpacing: 0.4,
          ),
        ),

        // Progress bar
        const SizedBox(height: 14),
        _ProgressBar(value: _progressValue(election), urgent: urgent),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(urgent ? 'Encerra em ${_timeLeft(remaining)}' : _timeLeft(remaining),
              style: GoogleFonts.ibmPlexMono(
                fontSize: 11, letterSpacing: 0.4,
                color: urgent ? AppColors.oxblood : AppColors.ink,
                fontWeight: urgent ? FontWeight.w600 : FontWeight.normal,
              )),
            Text('Em curso', style: GoogleFonts.ibmPlexSans(
              fontSize: 10, color: AppColors.inkMuted, letterSpacing: 0.4,
            )),
          ],
        ),

        // CTA
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, '/elections/detail', arguments: election),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: Text('VER DETALHES', style: GoogleFonts.ibmPlexSans(
                fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.6,
              )),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton.icon(
              onPressed: () => AuthStore.instance.isAuthenticated
                  ? Navigator.pushNamed(context, '/elections/vote', arguments: election)
                  : Navigator.pushNamed(context, '/auth/login'),
              icon: const Icon(Icons.fingerprint_rounded, size: 16),
              label: Text(
                AuthStore.instance.isAuthenticated ? 'VOTAR' : 'ENTRAR',
                style: GoogleFonts.ibmPlexSans(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.6),
              ),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            ),
          ),
        ]),
      ]),
    );
  }

  double _progressValue(ElectionItem e) {
    final total = e.endDate.difference(e.startDate).inMinutes;
    final elapsed = DateTime.now().difference(e.startDate).inMinutes;
    if (total <= 0) return 0;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  String _fmt(DateTime dt) {
    return '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year} '
           '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
  }

  String _timeLeft(Duration d) {
    if (d.inDays > 0) return '${d.inDays}d ${d.inHours.remainder(24)}h restantes';
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}min restantes';
    return '${d.inMinutes}min restantes';
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value, required this.urgent});
  final double value;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 4,
        backgroundColor: AppColors.surfaceContainerHigh,
        valueColor: AlwaysStoppedAnimation(
          urgent ? AppColors.oxblood : AppColors.primary,
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.hairlineStrong),
              borderRadius: BorderRadius.circular(2),
            ),
            child: const Icon(Icons.how_to_vote_outlined, color: AppColors.inkDim, size: 28),
          ),
          const SizedBox(height: 20),
          Text('Sem eleições activas', style: GoogleFonts.instrumentSerif(
            fontSize: 24, color: AppColors.ink, letterSpacing: -0.3,
          )),
          const SizedBox(height: 8),
          Text(
            'Não existem processos eleitorais em curso neste momento.',
            textAlign: TextAlign.center,
            style: GoogleFonts.atkinsonHyperlegible(
              fontSize: 14, color: AppColors.inkMuted, height: 1.5,
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 36),
          const SizedBox(height: 16),
          Text('Erro ao carregar eleições', style: GoogleFonts.instrumentSerif(
            fontSize: 22, color: AppColors.ink,
          )),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center,
            style: GoogleFonts.atkinsonHyperlegible(
              fontSize: 13, color: AppColors.inkMuted, height: 1.5,
            )),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: Text('Tentar novamente', style: GoogleFonts.ibmPlexSans(
              fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2,
            )),
          ),
        ]),
      ),
    );
  }
}

// ── Footer ────────────────────────────────────────────────────────────────────

class _ElectionsFooter extends StatelessWidget {
  const _ElectionsFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      color: AppColors.surfaceContainerLow,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Garantias', style: GoogleFonts.ibmPlexSans(
          fontSize: 9.5, fontWeight: FontWeight.w700,
          letterSpacing: 2, color: AppColors.inkMuted,
        )),
        const SizedBox(height: 10),
        RichText(text: TextSpan(children: [
          TextSpan(text: 'O voto é ', style: GoogleFonts.instrumentSerif(
            fontSize: 20, color: AppColors.ink, height: 1.3,
          )),
          TextSpan(text: 'secreto', style: GoogleFonts.instrumentSerif(
            fontSize: 20, color: AppColors.oxblood,
            fontStyle: FontStyle.italic, height: 1.3,
          )),
          TextSpan(text: ', ', style: GoogleFonts.instrumentSerif(
            fontSize: 20, color: AppColors.ink, height: 1.3,
          )),
          TextSpan(text: 'cifrado', style: GoogleFonts.instrumentSerif(
            fontSize: 20, color: AppColors.oxblood,
            fontStyle: FontStyle.italic, height: 1.3,
          )),
          TextSpan(text: ' e ', style: GoogleFonts.instrumentSerif(
            fontSize: 20, color: AppColors.ink, height: 1.3,
          )),
          TextSpan(text: 'verificável', style: GoogleFonts.instrumentSerif(
            fontSize: 20, color: AppColors.oxblood,
            fontStyle: FontStyle.italic, height: 1.3,
          )),
          TextSpan(text: '.', style: GoogleFonts.instrumentSerif(
            fontSize: 20, color: AppColors.ink, height: 1.3,
          )),
        ])),
        const SizedBox(height: 10),
        Text(
          'Após submissão, recebe um recibo criptográfico que permite confirmar '
          'a contabilização sem revelar a sua escolha.',
          style: GoogleFonts.atkinsonHyperlegible(
            fontSize: 12.5, color: AppColors.inkMuted, height: 1.55,
          ),
        ),
      ]),
    );
  }
}

// ── Mini live dot ─────────────────────────────────────────────────────────────

class _MiniLiveDot extends StatefulWidget {
  @override
  State<_MiniLiveDot> createState() => _MiniLiveDotState();
}

class _MiniLiveDotState extends State<_MiniLiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 1.0, end: 0.45).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (!ResponsiveLayout.isDesktop(context)) {
      return Container(
        width: 7, height: 7,
        decoration: const BoxDecoration(
          color: AppColors.goldContainer,
          shape: BoxShape.circle,
        ),
      );
    }
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          width: 7, height: 7,
          decoration: const BoxDecoration(
            color: AppColors.goldContainer,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
