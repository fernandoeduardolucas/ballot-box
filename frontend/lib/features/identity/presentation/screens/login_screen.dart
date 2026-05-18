import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sistema_eleitoral_frontend/core/auth/auth_store.dart';
import 'package:sistema_eleitoral_frontend/core/services/graphql_service.dart';
import 'package:sistema_eleitoral_frontend/core/theme/app_colors.dart';
import 'package:sistema_eleitoral_frontend/features/identity/data/auth_service.dart';

// ── Login screen ──────────────────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _civilIdCtrl  = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool    _isLoading    = false;
  bool    _obscure      = true;
  String? _errorMessage;

  final _service = AuthService(
    GraphQLService(baseUrl: 'http://localhost:8080/graphql'),
  );

  @override
  void dispose() {
    _civilIdCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final result = await _service.login(
        civilId:  _civilIdCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (!mounted) return;
      switch (result) {
        case LoginSuccess(:final token, :final isAdmin):
          AuthStore.instance.setSession(token: token, isAdmin: isAdmin);
          Navigator.pushReplacementNamed(
            context,
            isAdmin ? '/home' : '/elections/active',
          );
        case LoginFailure(:final message):
          setState(() => _errorMessage = message);
      }
    } catch (_) {
      setState(() => _errorMessage = 'Erro de ligação ao servidor.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _EditorialHeader(
            kicker: 'Portal do Eleitor',
            headline: 'Identifique-se\npara votar.',
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Identificação segura', style: GoogleFonts.ibmPlexSans(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          letterSpacing: 2, color: AppColors.oxblood,
                        )),
                        const SizedBox(height: 8),
                        RichText(text: TextSpan(children: [
                          TextSpan(text: 'Confirme a sua ', style: GoogleFonts.instrumentSerif(
                            fontSize: 28, color: AppColors.ink, letterSpacing: -0.3,
                          )),
                          TextSpan(text: 'identidade.', style: GoogleFonts.instrumentSerif(
                            fontSize: 28, color: AppColors.oxblood,
                            fontStyle: FontStyle.italic, letterSpacing: -0.3,
                          )),
                        ])),
                        const SizedBox(height: 8),
                        Text(
                          'Apenas eleitores recenseados podem submeter voto.',
                          style: GoogleFonts.atkinsonHyperlegible(
                            fontSize: 13.5, color: AppColors.inkMuted, height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 28),
                        if (_errorMessage != null) ...[
                          _ErrorBanner(message: _errorMessage!),
                          const SizedBox(height: 16),
                        ],
                        _EditorialField(
                          controller: _civilIdCtrl,
                          label: 'Número de Identificação Civil',
                          icon: Icons.badge_outlined,
                          validator: (v) => (v == null || v.trim().length < 8)
                              ? 'Mínimo 8 caracteres' : null,
                        ),
                        const SizedBox(height: 14),
                        _EditorialField(
                          controller: _passwordCtrl,
                          label: 'Palavra-passe',
                          icon: Icons.lock_outline_rounded,
                          obscure: _obscure,
                          onToggleObscure: () => setState(() => _obscure = !_obscure),
                          validator: (v) => (v == null || v.length < 8)
                              ? 'Mínimo 8 caracteres' : null,
                        ),
                        const SizedBox(height: 28),
                        FilledButton(
                          onPressed: _isLoading ? null : _submit,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 18, width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                                )
                              : Text('ENTRAR', style: GoogleFonts.ibmPlexSans(
                                  fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 2,
                                )),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            border: Border(left: BorderSide(color: AppColors.gold, width: 3)),
                          ),
                          child: Text(
                            'Ao entrar, aceita os termos da Comissão Eleitoral. '
                            'O seu endereço IP não é associado ao boletim.',
                            style: GoogleFonts.atkinsonHyperlegible(
                              fontSize: 12, color: AppColors.inkMuted, height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Não tem conta?', style: GoogleFonts.ibmPlexSans(
                              fontSize: 13, color: AppColors.inkMuted,
                            )),
                            TextButton(
                              onPressed: () => Navigator.pushNamed(context, '/auth/register'),
                              child: Text('Registar', style: GoogleFonts.ibmPlexSans(
                                fontSize: 13, fontWeight: FontWeight.w600,
                                color: AppColors.oxblood,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.oxblood,
                              )),
                            ),
                          ],
                        ),
                      ],
                    ),
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

// ── Register screen ───────────────────────────────────────────────────────────

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

// NUT3 regions — code must match backend Nut3Region enum codes
const _nut3Regions = [
  ('alto-minho',            'Alto Minho'),
  ('cavado',                'Cávado'),
  ('ave',                   'Ave'),
  ('am-porto',              'Área Metropolitana do Porto'),
  ('alto-tamega',           'Alto Tâmega'),
  ('tamega-e-sousa',        'Tâmega e Sousa'),
  ('douro',                 'Douro'),
  ('terras-tras-os-montes', 'Terras de Trás-os-Montes'),
  ('oeste',                 'Oeste'),
  ('regiao-aveiro',         'Região de Aveiro'),
  ('regiao-coimbra',        'Região de Coimbra'),
  ('regiao-leiria',         'Região de Leiria'),
  ('viseu-dao-lafoes',      'Viseu Dão Lafões'),
  ('beira-baixa',           'Beira Baixa'),
  ('medio-tejo',            'Médio Tejo'),
  ('beiras-serra',          'Beiras e Serra da Estrela'),
  ('am-lisboa',             'Área Metropolitana de Lisboa'),
  ('alentejo-litoral',      'Alentejo Litoral'),
  ('baixo-alentejo',        'Baixo Alentejo'),
  ('lezira-do-tejo',        'Lezíria do Tejo'),
  ('alto-alentejo',         'Alto Alentejo'),
  ('alentejo-central',      'Alentejo Central'),
  ('algarve',               'Algarve'),
  ('acores',                'Região Autónoma dos Açores'),
  ('madeira',               'Região Autónoma da Madeira'),
];

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _civilIdCtrl  = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl  = TextEditingController();

  bool    _isLoading    = false;
  bool    _obscure      = true;
  String? _errorMessage;
  String? _selectedNut3;

  final _service = AuthService(
    GraphQLService(baseUrl: 'http://localhost:8080/graphql'),
  );

  @override
  void dispose() {
    _civilIdCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedNut3 == null) {
      setState(() => _errorMessage = 'Selecione a sua região NUT3.');
      return;
    }
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final result = await _service.register(
        civilId:    _civilIdCtrl.text.trim(),
        password:   _passwordCtrl.text,
        nut3Region: _selectedNut3!,
      );
      if (!mounted) return;
      switch (result) {
        case RegisterSuccess():  _showSuccess();
        case RegisterFailure(:final message):
          setState(() => _errorMessage = message);
      }
    } catch (_) {
      setState(() => _errorMessage = 'Erro de ligação ao servidor.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccess() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Novo eleitor', style: GoogleFonts.ibmPlexSans(
              fontSize: 10, fontWeight: FontWeight.w700,
              letterSpacing: 2, color: AppColors.oxblood,
            )),
            const SizedBox(height: 8),
            Text('Registo\nconcluído.', style: GoogleFonts.instrumentSerif(
              fontSize: 32, color: AppColors.ink, letterSpacing: -0.5, height: 1.1,
            )),
            const SizedBox(height: 12),
            Text(
              'A sua conta foi criada com sucesso. Pode agora autenticar-se com as suas credenciais.',
              style: GoogleFonts.atkinsonHyperlegible(
                fontSize: 14, color: AppColors.inkMuted, height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text('IR PARA O LOGIN', style: GoogleFonts.ibmPlexSans(
                fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 2,
              )),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _EditorialHeader(
            kicker: 'Novo eleitor',
            headline: 'Crie a sua\nconta.',
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Necessitamos do seu número de identificação civil. '
                          'A verificação é instantânea.',
                          style: GoogleFonts.atkinsonHyperlegible(
                            fontSize: 13.5, color: AppColors.inkMuted, height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_errorMessage != null) ...[
                          _ErrorBanner(message: _errorMessage!),
                          const SizedBox(height: 16),
                        ],
                        _EditorialField(
                          controller: _civilIdCtrl,
                          label: 'Número de Identificação Civil',
                          icon: Icons.badge_outlined,
                          validator: (v) => (v == null || v.trim().length < 8)
                              ? 'Mínimo 8 caracteres' : null,
                        ),
                        const SizedBox(height: 14),
                        _EditorialField(
                          controller: _passwordCtrl,
                          label: 'Palavra-passe',
                          icon: Icons.lock_outline_rounded,
                          obscure: _obscure,
                          onToggleObscure: () => setState(() => _obscure = !_obscure),
                          validator: (v) => (v == null || v.length < 8)
                              ? 'Mínimo 8 caracteres' : null,
                        ),
                        const SizedBox(height: 14),
                        _EditorialField(
                          controller: _confirmCtrl,
                          label: 'Confirmar palavra-passe',
                          icon: Icons.lock_outline_rounded,
                          obscure: _obscure,
                          validator: (v) => v != _passwordCtrl.text
                              ? 'As palavras-passe não coincidem' : null,
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedNut3,
                          decoration: InputDecoration(
                            labelText: 'Região NUT3',
                            prefixIcon: const Icon(Icons.location_on_outlined, size: 18, color: AppColors.inkMuted),
                          ),
                          style: GoogleFonts.ibmPlexSans(fontSize: 14, color: AppColors.ink),
                          isExpanded: true,
                          items: _nut3Regions.map((r) => DropdownMenuItem(
                            value: r.$1,
                            child: Text(r.$2),
                          )).toList(),
                          onChanged: (v) => setState(() { _selectedNut3 = v; _errorMessage = null; }),
                          validator: (v) => v == null ? 'Selecione a sua região NUT3.' : null,
                        ),
                        const SizedBox(height: 28),
                        FilledButton(
                          onPressed: _isLoading ? null : _submit,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 18, width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                                )
                              : Text('REGISTAR', style: GoogleFonts.ibmPlexSans(
                                  fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 2,
                                )),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Já tem conta?', style: GoogleFonts.ibmPlexSans(
                              fontSize: 13, color: AppColors.inkMuted,
                            )),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Entrar', style: GoogleFonts.ibmPlexSans(
                                fontSize: 13, fontWeight: FontWeight.w600,
                                color: AppColors.oxblood,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.oxblood,
                              )),
                            ),
                          ],
                        ),
                      ],
                    ),
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

// ── Shared widgets ────────────────────────────────────────────────────────────

class _EditorialHeader extends StatelessWidget {
  const _EditorialHeader({required this.kicker, required this.headline});
  final String kicker;
  final String headline;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(32, 36, 32, 32),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.oxblood, width: 3),
          bottom: BorderSide(color: AppColors.ink, width: 2),
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('VotoSeguro — $kicker', style: GoogleFonts.ibmPlexMono(
            fontSize: 10, letterSpacing: 1.8, color: AppColors.inkMuted,
          )),
          const SizedBox(height: 14),
          Text(headline, style: GoogleFonts.instrumentSerif(
            fontSize: 36, color: AppColors.ink,
            letterSpacing: -0.8, height: 1.05,
          )),
        ]),
      ),
    );
  }
}

class _EditorialField extends StatelessWidget {
  const _EditorialField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.onToggleObscure,
    this.validator,
  });
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: GoogleFonts.ibmPlexSans(fontSize: 14, color: AppColors.ink),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: AppColors.inkMuted),
        suffixIcon: onToggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 18, color: AppColors.inkMuted,
                ),
                onPressed: onToggleObscure,
              )
            : null,
      ),
      validator: validator,
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        border: Border(left: BorderSide(color: AppColors.error, width: 3)),
      ),
      child: Row(children: [
        Icon(Icons.error_outline_rounded, color: AppColors.error, size: 16),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: GoogleFonts.atkinsonHyperlegible(
          fontSize: 13, color: AppColors.onOxbloodContainer,
        ))),
      ]),
    );
  }
}
