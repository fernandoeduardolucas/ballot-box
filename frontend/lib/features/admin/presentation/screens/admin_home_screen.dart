import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sistema_eleitoral_frontend/core/auth/auth_store.dart';
import 'package:sistema_eleitoral_frontend/core/presentation/widgets/responsive_layout.dart';
import 'package:sistema_eleitoral_frontend/core/theme/app_colors.dart';
import 'package:sistema_eleitoral_frontend/features/admin/presentation/widgets/admin_audit_console.dart';
import 'package:sistema_eleitoral_frontend/features/admin/presentation/widgets/admin_candidates_section.dart';
import 'package:sistema_eleitoral_frontend/features/admin/presentation/widgets/admin_elections_section.dart';
import 'package:sistema_eleitoral_frontend/features/admin/presentation/widgets/admin_panel_section.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    final desktop = Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const _Dateline(),
          const _Masthead(),
          _NavStrip(activeIndex: _navIndex, onTap: (i) => setState(() => _navIndex = i)),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final showAuditRail = constraints.maxWidth >= 1100 && _navIndex != 4;
                return Row(
                  children: [
                    Expanded(child: _buildSection()),
                    if (showAuditRail)
                      const SizedBox(
                        width: 370,
                        child: AdminAuditConsole(),
                      ),
                  ],
                );
              },
            ),
          ),
          _Footer(),
        ],
      ),
    );

    final mobile = Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('VotoSeguro', style: GoogleFonts.instrumentSerif(color: AppColors.ink, fontSize: 24)),
        backgroundColor: AppColors.surface,
        centerTitle: true,
      ),
      body: _buildSection(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex > 2 ? 3 : _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.oxblood,
        unselectedItemColor: AppColors.inkMuted,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Painel'),
          BottomNavigationBarItem(icon: Icon(Icons.how_to_vote_rounded), label: 'Eleições'),
          BottomNavigationBarItem(icon: Icon(Icons.people_rounded), label: 'Candidatos'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_rounded), label: 'Mais'),
        ],
      ),
    );

    return ResponsiveLayout(
      mobile: mobile,
      desktop: desktop,
    );
  }

  Widget _buildSection() {
    if (!ResponsiveLayout.isDesktop(context) && _navIndex == 3) {
      return const _PlaceholderSection(title: 'Mais', message: 'Menu secundário de administração (Resultados, Auditoria, etc).');
    }
    return switch (_navIndex) {
      0 => const AdminPanelSection(),
      1 => const AdminElectionsSection(),
      2 => const AdminCandidatesSection(),
      3 => const _PlaceholderSection(title: 'Resultados', message: 'Os resultados estarão disponíveis após o encerramento das eleições.'),
      4 => const AdminAuditConsole(),
      _ => const AdminPanelSection(),
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
          decoration: BoxDecoration(
            color: AppColors.goldContainer,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: AppColors.goldContainer.withValues(alpha: 0.35), blurRadius: 4, spreadRadius: 2)],
          ),
        ),
      ),
    );
  }
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
