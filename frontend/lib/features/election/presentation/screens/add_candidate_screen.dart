import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sistema_eleitoral_frontend/core/services/graphql_service.dart';
import 'package:sistema_eleitoral_frontend/core/theme/app_colors.dart';
import 'package:sistema_eleitoral_frontend/features/election/data/candidate_service.dart';

class AddCandidateScreen extends StatefulWidget {
  const AddCandidateScreen({super.key});

  @override
  State<AddCandidateScreen> createState() => _AddCandidateScreenState();
}

class _AddCandidateScreenState extends State<AddCandidateScreen> {
  final _formKey        = GlobalKey<FormState>();
  final _electionIdCtrl = TextEditingController();
  final _nameCtrl       = TextEditingController();
  final _partyCtrl      = TextEditingController();
  final _photoUrlCtrl   = TextEditingController();
  final _numberCtrl     = TextEditingController();

  bool    _isLoading    = false;
  bool    _prefilled    = false;
  String? _errorMessage;
  String  _photoPreview = '';

  final _service = CandidateService(
    GraphQLService(baseUrl: 'http://localhost:8080/graphql'),
  );

  @override
  void initState() {
    super.initState();
    _photoUrlCtrl.addListener(() {
      setState(() => _photoPreview = _photoUrlCtrl.text.trim());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_prefilled) {
      _prefilled = true;
      final arg = ModalRoute.of(context)?.settings.arguments;
      if (arg is String && arg.isNotEmpty) {
        _electionIdCtrl.text = arg;
      }
    }
  }

  @override
  void dispose() {
    _electionIdCtrl.dispose();
    _nameCtrl.dispose();
    _partyCtrl.dispose();
    _photoUrlCtrl.dispose();
    _numberCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    final number = int.tryParse(_numberCtrl.text.trim());
    if (number == null || number < 1) {
      setState(() => _errorMessage = 'O número de candidatura deve ser um inteiro positivo.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await _service.addCandidate(
        electionId: _electionIdCtrl.text.trim(),
        name:       _nameCtrl.text.trim(),
        number:     number,
        party:      _partyCtrl.text.trim().isEmpty ? null : _partyCtrl.text.trim(),
        photoUrl:   _photoUrlCtrl.text.trim().isEmpty ? null : _photoUrlCtrl.text.trim(),
      );
      if (!mounted) return;
      switch (result) {
        case AddCandidateSuccess():
          _showSuccessDialog(result);
        case AddCandidateFailure():
          setState(() => _errorMessage = result.message);
      }
    } catch (_) {
      setState(() => _errorMessage = 'Não foi possível ligar ao servidor. Verifique a ligação.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(AddCandidateSuccess candidate) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppColors.hairline),
        ),
        contentPadding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CandidateAvatar(photoUrl: candidate.photoUrl, size: 72),
            const SizedBox(height: 20),
            Text(
              'Candidato registado.',
              style: GoogleFonts.instrumentSerif(
                fontSize: 24, color: AppColors.ink, letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainerLow,
                border: Border(left: BorderSide(color: AppColors.gold, width: 3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(label: 'Nome',    value: candidate.name),
                  if (candidate.party != null) ...[
                    const SizedBox(height: 6),
                    _InfoRow(label: 'Partido', value: candidate.party!),
                  ],
                  const SizedBox(height: 6),
                  _InfoRow(label: 'Número',  value: '#${candidate.number}'),
                  const SizedBox(height: 6),
                  _InfoRow(label: 'ID',      value: candidate.id, mono: true),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _clearForm();
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    side: const BorderSide(color: AppColors.hairlineStrong),
                    foregroundColor: AppColors.ink,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: Text(
                    'Adicionar outro',
                    style: GoogleFonts.ibmPlexSans(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: Text(
                    'CONCLUÍDO',
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
  }

  void _clearForm() {
    _nameCtrl.clear();
    _partyCtrl.clear();
    _photoUrlCtrl.clear();
    _numberCtrl.clear();
    setState(() => _errorMessage = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildEditorialHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: _buildFormCard(),
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
          padding: const EdgeInsets.fromLTRB(8, 12, 16, 20),
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
                      'VotoSeguro — Administração',
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 10, letterSpacing: 1.8, color: AppColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    RichText(
                      text: TextSpan(children: [
                        TextSpan(
                          text: 'Registar ',
                          style: GoogleFonts.instrumentSerif(
                            fontSize: 28, color: AppColors.ink,
                            letterSpacing: -0.5, height: 1.05,
                          ),
                        ),
                        TextSpan(
                          text: 'candidato.',
                          style: GoogleFonts.instrumentSerif(
                            fontSize: 28, color: AppColors.oxblood,
                            fontStyle: FontStyle.italic,
                            letterSpacing: -0.5, height: 1.05,
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

  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.hairline),
      ),
      padding: const EdgeInsets.all(32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionLabel(numeral: 'I', text: 'ELEIÇÃO'),
            const SizedBox(height: 16),
            _FieldLabel(text: 'ID da Eleição'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _electionIdCtrl,
              style: GoogleFonts.ibmPlexMono(fontSize: 13, color: AppColors.ink),
              decoration: const InputDecoration(
                hintText: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
                prefixIcon: Icon(Icons.tag_rounded),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'O ID da eleição é obrigatório.';
                final uuidRegex = RegExp(
                  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
                  caseSensitive: false,
                );
                if (!uuidRegex.hasMatch(v.trim())) return 'Formato inválido. Use o UUID da eleição.';
                return null;
              },
            ),
            const SizedBox(height: 36),
            _SectionLabel(numeral: 'II', text: 'CANDIDATO'),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LivePhotoPreview(url: _photoPreview),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _FieldLabel(text: 'Número de Candidatura'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _numberCtrl,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.ibmPlexSans(fontSize: 15, color: AppColors.ink),
                        decoration: const InputDecoration(
                          hintText: '1',
                          prefixIcon: Icon(Icons.format_list_numbered_rounded),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Obrigatório.';
                          if (int.tryParse(v.trim()) == null) return 'Deve ser um número.';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _FieldLabel(text: 'Nome do Candidato'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameCtrl,
              maxLength: 255,
              style: GoogleFonts.ibmPlexSans(fontSize: 15, color: AppColors.ink),
              decoration: const InputDecoration(
                hintText: 'Nome completo',
                prefixIcon: Icon(Icons.person_rounded),
                counterText: '',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'O nome é obrigatório.';
                if (v.trim().length < 2) return 'Mínimo 2 caracteres.';
                return null;
              },
            ),
            const SizedBox(height: 20),
            _OptionalFieldLabel(text: 'Partido'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _partyCtrl,
              maxLength: 255,
              style: GoogleFonts.ibmPlexSans(fontSize: 15, color: AppColors.ink),
              decoration: const InputDecoration(
                hintText: 'Nome do partido ou movimento',
                prefixIcon: Icon(Icons.flag_rounded),
                counterText: '',
              ),
            ),
            const SizedBox(height: 20),
            _OptionalFieldLabel(text: 'URL da Fotografia'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _photoUrlCtrl,
              style: GoogleFonts.ibmPlexSans(fontSize: 15, color: AppColors.ink),
              decoration: const InputDecoration(
                hintText: 'https://...',
                prefixIcon: Icon(Icons.image_rounded),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 20),
              _ErrorBanner(message: _errorMessage!),
            ],
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _isLoading ? null : _submit,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.onPrimary),
                    )
                  : const Icon(Icons.person_add_rounded),
              label: Text(
                _isLoading ? 'A adicionar...' : 'Adicionar Candidato',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5,
                ),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.numeral, required this.text});
  final String numeral;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$numeral. $text',
          style: GoogleFonts.ibmPlexSans(
            fontSize: 10, fontWeight: FontWeight.w700,
            letterSpacing: 2, color: AppColors.inkMuted,
          ),
        ),
        const SizedBox(height: 8),
        const Divider(color: AppColors.hairline, height: 1, thickness: 1),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.ibmPlexSans(
          fontSize: 12, fontWeight: FontWeight.w600,
          letterSpacing: 0.3, color: AppColors.inkMuted,
        ),
      );
}

class _OptionalFieldLabel extends StatelessWidget {
  const _OptionalFieldLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text,
          style: GoogleFonts.ibmPlexSans(
            fontSize: 12, fontWeight: FontWeight.w600,
            letterSpacing: 0.3, color: AppColors.inkMuted,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            'opcional',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 10, color: AppColors.inkDim, letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _LivePhotoPreview extends StatelessWidget {
  const _LivePhotoPreview({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    final hasUrl = url.startsWith('http');
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: hasUrl ? AppColors.gold.withValues(alpha: 0.5) : AppColors.hairline,
              width: hasUrl ? 2 : 1,
            ),
            color: AppColors.surfaceContainerLow,
          ),
          child: ClipOval(
            child: hasUrl
                ? Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image_rounded,
                      color: AppColors.inkDim,
                      size: 28,
                    ),
                  )
                : const Icon(Icons.person_rounded, color: AppColors.inkDim, size: 32),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Pré-visualização',
          style: GoogleFonts.ibmPlexSans(fontSize: 10, color: AppColors.inkDim),
        ),
      ],
    );
  }
}

class _CandidateAvatar extends StatelessWidget {
  const _CandidateAvatar({required this.photoUrl, required this.size});
  final String? photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.startsWith('http');
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.hairlineStrong, width: 2),
        color: AppColors.surfaceContainerLow,
      ),
      child: ClipOval(
        child: hasPhoto
            ? Image.network(
                photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.person_rounded, color: AppColors.inkDim),
              )
            : const Icon(Icons.person_rounded, color: AppColors.inkDim, size: 36),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.mono = false});
  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 62,
          child: Text(
            label,
            style: GoogleFonts.ibmPlexSans(fontSize: 11, color: AppColors.inkMuted),
          ),
        ),
        Expanded(
          child: mono
              ? Text(
                  value,
                  style: GoogleFonts.ibmPlexMono(fontSize: 11, color: AppColors.inkMuted),
                )
              : Text(
                  value,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink,
                  ),
                ),
        ),
      ],
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
      decoration: const BoxDecoration(
        color: AppColors.errorContainer,
        border: Border(left: BorderSide(color: AppColors.error, width: 3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.atkinsonHyperlegible(
                fontSize: 13, color: AppColors.onOxbloodContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
