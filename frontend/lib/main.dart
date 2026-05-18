import 'package:flutter/material.dart';
import 'package:sistema_eleitoral_frontend/core/theme/app_colors.dart';
import 'package:sistema_eleitoral_frontend/features/election/presentation/screens/create_election_screen.dart';
import 'package:sistema_eleitoral_frontend/features/election/presentation/screens/vote_screen.dart';

void main() => runApp(const ElectionApp());

class ElectionApp extends StatelessWidget {
  const ElectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1B3776),
      brightness: Brightness.dark,
    );
    return MaterialApp(
      title: 'Sistema Eleitoral',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: base.copyWith(
          primary: AppColors.gold,
          onPrimary: AppColors.navy,
          secondary: AppColors.sky,
          onSecondary: Colors.white,
          surface: AppColors.navySurf,
          onSurface: AppColors.offWhite,
          surfaceContainerLowest: AppColors.navy,
          surfaceContainerLow: AppColors.navyLight,
          surfaceContainer: AppColors.navySurf,
          surfaceContainerHigh: const Color(0xFF1C2E48),
          surfaceContainerHighest: const Color(0xFF22364E),
          outline: const Color(0xFF2E3D54),
          outlineVariant: const Color(0xFF1E2D42),
          error: const Color(0xFFEF5350),
          onError: Colors.white,
          errorContainer: const Color(0xFF4A1010),
          onErrorContainer: const Color(0xFFEFB8B8),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.navy,
          foregroundColor: AppColors.offWhite,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: AppColors.navy,
            textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.3),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.navyLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2E3D54)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2E3D54)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
          ),
          hintStyle: const TextStyle(color: AppColors.subtle),
          prefixIconColor: AppColors.subtle,
          labelStyle: const TextStyle(color: AppColors.subtle),
        ),
        cardTheme: CardThemeData(
          color: AppColors.navySurf,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF1E2D42)),
          ),
          margin: EdgeInsets.zero,
        ),
      ),
      home: const HomePage(),
      routes: {
        '/elections/create': (_) => const CreateElectionScreen(),
        '/elections/vote':   (_) => const VoteScreen(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Column(
        children: [
          const _HeroBanner(),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _SectionLabel(
                        label: 'TIPOS DE ELEIÇÃO',
                        title: 'O que pretende criar?',
                      ),
                      const SizedBox(height: 16),
                      const _ElectionTypeGrid(),
                      const SizedBox(height: 44),
                      const _SectionLabel(
                        label: 'ACESSO RÁPIDO',
                        title: 'Ações disponíveis',
                      ),
                      const SizedBox(height: 16),
                      const _QuickActions(),
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
}

// ─── Hero ────────────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF04090F), Color(0xFF0A1628), Color(0xFF0F2040)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(bottom: BorderSide(color: AppColors.gold, width: 1.5)),
      ),
      padding: const EdgeInsets.fromLTRB(28, 48, 28, 40),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold, width: 1.5),
              gradient: const RadialGradient(
                colors: [Color(0xFF1C2E50), Color(0xFF0A1628)],
              ),
            ),
            child: const Icon(
              Icons.account_balance_rounded,
              color: AppColors.gold,
              size: 32,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'COMISSÃO NACIONAL DE ELEIÇÕES',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 3.2,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Painel de Administração',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.offWhite,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Gestão e organização de processos eleitorais',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.subtle, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ─── Section label ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.title});
  final String label;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.gold,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.offWhite,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ─── Election type grid ───────────────────────────────────────────────────────

class _ElectionTypeGrid extends StatelessWidget {
  const _ElectionTypeGrid();

  static const _types = [
    (Icons.account_balance_rounded, 'Presidencial',  'Eleição do Presidente da República'),
    (Icons.gavel_rounded,           'Legislativa',   'Eleição para a Assembleia da República'),
    (Icons.location_city_rounded,   'Autárquica',    'Eleições para órgãos autárquicos'),
    (Icons.how_to_vote_rounded,     'Referendo',     'Consulta popular sobre questão específica'),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.8,
      ),
      itemCount: _types.length,
      itemBuilder: (ctx, i) {
        final t = _types[i];
        return _ElectionTypeCard(icon: t.$1, title: t.$2, subtitle: t.$3);
      },
    );
  }
}

class _ElectionTypeCard extends StatelessWidget {
  const _ElectionTypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/elections/create'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.navySurf,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1E2D42)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.gold, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.offWhite,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.subtle, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.gold.withValues(alpha: 0.4),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Quick actions ────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionTile(
            icon: Icons.add_circle_outline_rounded,
            label: 'Nova Eleição',
            description: 'Criar novo processo eleitoral',
            isPrimary: true,
            onTap: () => Navigator.pushNamed(context, '/elections/create'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionTile(
            icon: Icons.ballot_outlined,
            label: 'Demo de Votação',
            description: 'Pré-visualizar interface de voto',
            isPrimary: false,
            onTap: () => Navigator.pushNamed(context, '/elections/vote'),
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.isPrimary,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String description;
  final bool isPrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [Color(0xFF1C2E50), Color(0xFF0F2040)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isPrimary ? null : AppColors.navySurf,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPrimary
                ? AppColors.gold.withValues(alpha: 0.35)
                : const Color(0xFF1E2D42),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: isPrimary ? AppColors.gold : AppColors.subtle,
              size: 24,
            ),
            const SizedBox(height: 14),
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? AppColors.gold : AppColors.offWhite,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(color: AppColors.subtle, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
