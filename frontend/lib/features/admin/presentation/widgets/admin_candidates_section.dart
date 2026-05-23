import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sistema_eleitoral_frontend/core/theme/app_colors.dart';

class AdminCandidatesSection extends StatelessWidget {
  const AdminCandidatesSection({super.key});

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
