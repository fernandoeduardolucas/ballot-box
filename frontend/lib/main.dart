import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sistema_eleitoral_frontend/core/auth/auth_store.dart';
import 'package:sistema_eleitoral_frontend/core/services/graphql_service.dart';
import 'package:sistema_eleitoral_frontend/core/theme/app_colors.dart';
import 'package:sistema_eleitoral_frontend/features/election/data/election_service.dart';
import 'package:sistema_eleitoral_frontend/features/election/presentation/screens/active_elections_screen.dart';
import 'package:sistema_eleitoral_frontend/features/election/presentation/screens/add_candidate_screen.dart';
import 'package:sistema_eleitoral_frontend/features/election/presentation/screens/create_election_screen.dart';
import 'package:sistema_eleitoral_frontend/features/election/presentation/screens/election_detail_screen.dart';
import 'package:sistema_eleitoral_frontend/features/election/presentation/screens/vote_screen.dart';
import 'package:sistema_eleitoral_frontend/features/identity/presentation/screens/login_screen.dart';

void main() => runApp(const ElectionApp());

class ElectionApp extends StatelessWidget {
  const ElectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.primary,
      secondary: AppColors.oxblood,
      onSecondary: AppColors.surface,
      secondaryContainer: AppColors.oxbloodContainer,
      onSecondaryContainer: AppColors.onOxbloodContainer,
      tertiary: AppColors.gold,
      onTertiary: AppColors.surface,
      tertiaryContainer: AppColors.goldContainer,
      onTertiaryContainer: AppColors.onGoldContainer,
      error: AppColors.error,
      onError: AppColors.surface,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onOxbloodContainer,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      surfaceContainerLowest: AppColors.background,
      surfaceContainerLow: AppColors.surfaceContainerLow,
      surfaceContainer: AppColors.surfaceContainer,
      surfaceContainerHigh: AppColors.surfaceContainerHigh,
      surfaceContainerHighest: AppColors.hairline,
      outline: AppColors.hairline,
      outlineVariant: AppColors.hairlineStrong,
      shadow: const Color(0xFF0B1118),
      scrim: const Color(0xFF0B1118),
      inverseSurface: AppColors.primary,
      onInverseSurface: AppColors.onPrimary,
      inversePrimary: AppColors.primaryContainer,
    );

    return MaterialApp(
      title: 'VotoSeguro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: cs,
        scaffoldBackgroundColor: AppColors.background,
        textTheme: GoogleFonts.ibmPlexSansTextTheme().copyWith(
          displayLarge: GoogleFonts.instrumentSerif(fontSize: 57, color: AppColors.ink, letterSpacing: -2),
          displayMedium: GoogleFonts.instrumentSerif(fontSize: 45, color: AppColors.ink, letterSpacing: -1.5),
          displaySmall: GoogleFonts.instrumentSerif(fontSize: 36, color: AppColors.ink, letterSpacing: -1),
          headlineLarge: GoogleFonts.instrumentSerif(fontSize: 32, color: AppColors.ink, letterSpacing: -0.6),
          headlineMedium: GoogleFonts.instrumentSerif(fontSize: 28, color: AppColors.ink, letterSpacing: -0.4),
          headlineSmall: GoogleFonts.instrumentSerif(fontSize: 24, color: AppColors.ink, letterSpacing: -0.3),
          titleLarge: GoogleFonts.ibmPlexSans(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.ink),
          bodyLarge: GoogleFonts.atkinsonHyperlegible(fontSize: 16, color: AppColors.inkSubtle),
          bodyMedium: GoogleFonts.atkinsonHyperlegible(fontSize: 14, color: AppColors.inkMuted),
          labelSmall: GoogleFonts.ibmPlexMono(fontSize: 10, letterSpacing: 1.4, color: AppColors.inkMuted),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.ink,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: GoogleFonts.ibmPlexSans(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink),
          iconTheme: const IconThemeData(color: AppColors.ink),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            minimumSize: const Size(double.infinity, 46),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            textStyle: GoogleFonts.ibmPlexSans(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 1.6),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.ink,
            minimumSize: const Size(double.infinity, 46),
            side: const BorderSide(color: AppColors.hairlineStrong),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            textStyle: GoogleFonts.ibmPlexSans(fontWeight: FontWeight.w600, fontSize: 12, letterSpacing: 1.6),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppColors.hairlineStrong),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppColors.hairlineStrong),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          labelStyle: GoogleFonts.ibmPlexSans(color: AppColors.inkMuted),
          hintStyle: GoogleFonts.ibmPlexSans(color: AppColors.inkDim),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: AppColors.hairline),
          ),
          margin: EdgeInsets.zero,
        ),
        dividerTheme: const DividerThemeData(color: AppColors.hairline, thickness: 1, space: 0),
      ),
      home: const ActiveElectionsScreen(),
      routes: {
        '/home':             (_) => const HomePage(),
        '/auth/login':       (_) => const LoginScreen(),
        '/elections/create': (_) => const CreateElectionScreen(),
        '/elections/active': (_) => const ActiveElectionsScreen(),
        '/candidates/add':   (_) => const AddCandidateScreen(),
        '/elections/vote':   (_) => const VoteScreen(),
        '/elections/detail': (ctx) {
          final e = ModalRoute.of(ctx)!.settings.arguments as ElectionItem;
          return ElectionDetailScreen(election: e);
        },
      },
    );
  }
}

// ── HomePage ──────────────────────────────────────────────────────────────────

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const _Dateline(),
          const _Masthead(),
          _NavStrip(activeIndex: _navIndex, onTap: (i) => setState(() => _navIndex = i)),
          Expanded(child: _buildSection()),
          _Footer(),
        ],
      ),
    );
  }

  Widget _buildSection() {
    return switch (_navIndex) {
      0 => const _PainelSection(),
      1 => const _EleicoesAdminSection(),
      2 => const _CandidatosSection(),
      3 => const _PlaceholderSection(title: 'Resultados', message: 'Os resultados estarão disponíveis após o encerramento das eleições.'),
      4 => const _PlaceholderSection(title: 'Auditoria', message: 'O registo de auditoria está em desenvolvimento.'),
      _ => const _PainelSection(),
    };
  }
}

// ── Dateline ──────────────────────────────────────────────────────────────────

class _Dateline extends StatelessWidget {
  const _Dateline();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekdays = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];
    final months = ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez'];
    final date = '${weekdays[now.weekday - 1]} · ${now.day} ${months[now.month - 1]} ${now.year}';

    return Container(
      color: AppColors.ink,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 7),
      child: Row(
        children: [
          Text(date, style: GoogleFonts.ibmPlexMono(fontSize: 10, color: AppColors.surface, letterSpacing: 1.2, height: 1)),
          const SizedBox(width: 18),
          Container(width: 1, height: 10, color: AppColors.surface.withValues(alpha: 0.3)),
          const SizedBox(width: 18),
          Text('Área de Administração', style: GoogleFonts.ibmPlexMono(fontSize: 10, color: AppColors.surface, letterSpacing: 1.2, height: 1)),
          const Spacer(),
          _LiveDot(),
          const SizedBox(width: 6),
          Text('sistema operacional', style: GoogleFonts.ibmPlexMono(fontSize: 10, color: AppColors.goldContainer, letterSpacing: 1.2, height: 1)),
        ],
      ),
    );
  }
}

class _LiveDot extends StatefulWidget {
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);
    _anim = Tween<double>(begin: 1.0, end: 0.45).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (_, __) => Opacity(
      opacity: _anim.value,
      child: Container(
        width: 7, height: 7,
        decoration: BoxDecoration(
          color: AppColors.goldContainer,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: AppColors.goldContainer.withValues(alpha: 0.35), blurRadius: 4, spreadRadius: 2)],
        ),
      ),
    ),
  );
}

// ── Masthead ──────────────────────────────────────────────────────────────────

class _Masthead extends StatelessWidget {
  const _Masthead();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.ink, width: 2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Plataforma Oficial de Administração Eleitoral',
                style: GoogleFonts.ibmPlexSans(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 2, color: AppColors.inkMuted)),
              const SizedBox(height: 4),
              RichText(text: TextSpan(children: [
                TextSpan(text: 'Voto', style: GoogleFonts.instrumentSerif(fontSize: 40, color: AppColors.ink, height: 0.95, letterSpacing: -1)),
                TextSpan(text: 'Seguro', style: GoogleFonts.instrumentSerif(fontSize: 40, color: AppColors.oxblood, fontStyle: FontStyle.italic, height: 0.95, letterSpacing: -1)),
              ])),
            ],
          ),
          const Spacer(),
          FilledButton(
            onPressed: () => Navigator.pushNamed(context, '/elections/create'),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 40), padding: const EdgeInsets.symmetric(horizontal: 18)),
            child: Text('+ Nova Eleição', style: GoogleFonts.ibmPlexSans(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.4)),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: () {
              AuthStore.instance.clearToken();
              Navigator.pushReplacementNamed(context, '/elections/active');
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              foregroundColor: AppColors.oxblood,
              side: const BorderSide(color: AppColors.oxblood),
            ),
            child: Text('Sair', style: GoogleFonts.ibmPlexSans(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.4)),
          ),
        ],
      ),
    );
  }
}

// ── Nav strip ─────────────────────────────────────────────────────────────────

class _NavStrip extends StatelessWidget {
  const _NavStrip({required this.activeIndex, required this.onTap});
  final int activeIndex;
  final ValueChanged<int> onTap;

  static const _labels = ['Painel', 'Eleições', 'Candidatos', 'Resultados', 'Auditoria'];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.hairline)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(_labels.length, (i) => _NavItem(
          label: _labels[i],
          active: i == activeIndex,
          onTap: () => onTap(i),
        )),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: active ? AppColors.oxblood : Colors.transparent, width: 2)),
          ),
          child: Text(label, style: GoogleFonts.ibmPlexSans(
            fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.4,
            color: active ? AppColors.ink : AppColors.inkMuted,
          )),
        ),
      ),
    );
  }
}

// ── Painel section ────────────────────────────────────────────────────────────

class _PainelSection extends StatelessWidget {
  const _PainelSection();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero
              Container(
                padding: const EdgeInsets.fromLTRB(32, 48, 32, 40),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(bottom: BorderSide(color: AppColors.hairline)),
                ),
                child: LayoutBuilder(builder: (_, c) {
                  if (c.maxWidth > 680) {
                    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Expanded(flex: 3, child: _PainelHeadline()),
                      const SizedBox(width: 60),
                      Expanded(flex: 2, child: _PainelIntro()),
                    ]);
                  }
                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _PainelHeadline(),
                    const SizedBox(height: 28),
                    _PainelIntro(),
                  ]);
                }),
              ),
              // Quick actions
              Container(
                padding: const EdgeInsets.all(32),
                color: AppColors.surface,
                child: LayoutBuilder(builder: (_, c) {
                  if (c.maxWidth > 580) {
                    return Row(children: [
                      Expanded(child: _ActionCard(
                        index: '01',
                        title: 'Nova Eleição',
                        subtitle: 'Criar processo eleitoral com datas e configurações.',
                        cta: 'Criar eleição',
                        primary: true,
                        onTap: () => Navigator.pushNamed(context, '/elections/create'),
                      )),
                      Container(width: 1, height: 200, color: AppColors.hairline),
                      Expanded(child: _ActionCard(
                        index: '02',
                        title: 'Adicionar Candidato',
                        subtitle: 'Associar candidato a uma eleição existente.',
                        cta: 'Adicionar candidato',
                        primary: false,
                        onTap: () => Navigator.pushNamed(context, '/candidates/add'),
                      )),
                    ]);
                  }
                  return Column(children: [
                    _ActionCard(index: '01', title: 'Nova Eleição',
                      subtitle: 'Criar processo eleitoral com datas e configurações.',
                      cta: 'Criar eleição', primary: true,
                      onTap: () => Navigator.pushNamed(context, '/elections/create')),
                    const Divider(height: 1, color: AppColors.hairline),
                    _ActionCard(index: '02', title: 'Adicionar Candidato',
                      subtitle: 'Associar candidato a uma eleição existente.',
                      cta: 'Adicionar candidato', primary: false,
                      onTap: () => Navigator.pushNamed(context, '/candidates/add')),
                  ]);
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PainelHeadline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 36, height: 1, color: AppColors.oxblood),
        const SizedBox(width: 12),
        Text('Painel de administração', style: GoogleFonts.ibmPlexSans(
          fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 2.4, color: AppColors.oxblood,
        )),
      ]),
      const SizedBox(height: 22),
      RichText(text: TextSpan(children: [
        TextSpan(text: 'Gerir eleições\n', style: GoogleFonts.instrumentSerif(fontSize: 64, color: AppColors.ink, height: 0.95, letterSpacing: -2)),
        TextSpan(text: 'e candidatos —\n', style: GoogleFonts.instrumentSerif(fontSize: 64, color: AppColors.ink, height: 0.95, letterSpacing: -2)),
        TextSpan(text: 'com rigor.', style: GoogleFonts.instrumentSerif(fontSize: 64, color: AppColors.oxblood, fontStyle: FontStyle.italic, height: 0.95, letterSpacing: -2)),
      ])),
    ]);
  }
}

class _PainelIntro extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        'Utilize os atalhos abaixo para criar e gerir processos eleitorais. '
        'Os dados são actualizados em tempo real via GraphQL.',
        style: GoogleFonts.atkinsonHyperlegible(fontSize: 15, height: 1.6, color: AppColors.inkSubtle),
      ),
      const SizedBox(height: 20),
      Text('Navegue pelos separadores acima para aceder a Eleições, Candidatos, Resultados e Auditoria.',
        style: GoogleFonts.atkinsonHyperlegible(fontSize: 13, height: 1.5, color: AppColors.inkMuted)),
    ]);
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.index, required this.title, required this.subtitle,
    required this.cta, required this.primary, required this.onTap,
  });
  final String index, title, subtitle, cta;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(index, style: GoogleFonts.ibmPlexMono(fontSize: 11, color: AppColors.inkDim, letterSpacing: 1.4)),
        const SizedBox(height: 12),
        Text(title, style: GoogleFonts.instrumentSerif(fontSize: 28, color: AppColors.ink, letterSpacing: -0.5, height: 1.05)),
        const SizedBox(height: 10),
        Text(subtitle, style: GoogleFonts.atkinsonHyperlegible(fontSize: 14, color: AppColors.inkMuted, height: 1.5)),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: primary
              ? FilledButton(onPressed: onTap, child: Text(cta.toUpperCase()))
              : OutlinedButton(onPressed: onTap, child: Text(cta.toUpperCase())),
        ),
      ]),
    );
  }
}

// ── Eleições section (admin) ──────────────────────────────────────────────────

class _EleicoesAdminSection extends StatefulWidget {
  const _EleicoesAdminSection();

  @override
  State<_EleicoesAdminSection> createState() => _EleicoesAdminSectionState();
}

class _EleicoesAdminSectionState extends State<_EleicoesAdminSection> {
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

// ── Candidatos section ────────────────────────────────────────────────────────

class _CandidatosSection extends StatelessWidget {
  const _CandidatosSection();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              padding: const EdgeInsets.all(40),
              color: AppColors.surface,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Candidatos', style: GoogleFonts.instrumentSerif(fontSize: 36, color: AppColors.ink, letterSpacing: -1)),
                const SizedBox(height: 12),
                Text('Adicione candidatos a eleições existentes. Selecione uma eleição no separador Eleições para adicionar candidatos diretamente.',
                  style: GoogleFonts.atkinsonHyperlegible(fontSize: 14, color: AppColors.inkMuted, height: 1.6)),
                const SizedBox(height: 28),
                SizedBox(
                  width: 240,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/candidates/add'),
                    icon: const Icon(Icons.person_add_rounded, size: 18),
                    label: Text('Adicionar Candidato', style: GoogleFonts.ibmPlexSans(fontSize: 13, fontWeight: FontWeight.w600)),
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Placeholder section ───────────────────────────────────────────────────────

class _PlaceholderSection extends StatelessWidget {
  const _PlaceholderSection({required this.title, required this.message});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(60),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(border: Border.all(color: AppColors.hairlineStrong), borderRadius: BorderRadius.circular(2)),
            child: const Icon(Icons.construction_rounded, color: AppColors.inkDim, size: 28),
          ),
          const SizedBox(height: 24),
          Text(title, style: GoogleFonts.instrumentSerif(fontSize: 28, color: AppColors.ink, letterSpacing: -0.5)),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center,
            style: GoogleFonts.atkinsonHyperlegible(fontSize: 14, color: AppColors.inkMuted, height: 1.5)),
        ]),
      ),
    );
  }
}

// ── Footer ────────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.ink,
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 28),
      child: Row(children: [
        RichText(text: TextSpan(children: [
          TextSpan(text: 'Voto', style: GoogleFonts.instrumentSerif(fontSize: 22, color: AppColors.surface, letterSpacing: -0.5)),
          TextSpan(text: 'Seguro', style: GoogleFonts.instrumentSerif(fontSize: 22, color: AppColors.gold, fontStyle: FontStyle.italic, letterSpacing: -0.5)),
        ])),
        const Spacer(),
        Text('© 2026 · Comissão Nacional de Eleições',
          style: GoogleFonts.ibmPlexMono(fontSize: 10, color: AppColors.surface.withValues(alpha: 0.5), letterSpacing: 1)),
      ]),
    );
  }
}
