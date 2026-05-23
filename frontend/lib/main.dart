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
import 'package:sistema_eleitoral_frontend/features/admin/presentation/screens/admin_home_screen.dart';

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
        pageTransitionsTheme: const PageTransitionsTheme(
                  builders: <TargetPlatform, PageTransitionsBuilder>{
                    TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
                    TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
                    TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
                    TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
                    TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(), // Resolve o problema da Web
                    // O iOS foi propositadamente omitido. O Flutter aplicará o Cupertino nativo sozinho.
                  },
                ),
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
      initialRoute: AuthStore.instance.isAuthenticated
          ? (AuthStore.instance.isAdmin ? '/home' : '/elections/active')
          : '/elections/active',
      routes: {
        '/auth/login':       (_) => const LoginScreen(),
        '/auth/register':    (_) => const RegisterScreen(),
        '/home':             (_) => const AdminHomeScreen(),
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

