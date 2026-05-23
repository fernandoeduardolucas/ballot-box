import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sistema_eleitoral_frontend/core/theme/app_colors.dart';

class AdminPanelSection extends StatelessWidget {
  const AdminPanelSection({super.key});

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
