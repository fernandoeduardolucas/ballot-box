import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sistema_eleitoral_frontend/core/theme/app_colors.dart';
import 'package:sistema_eleitoral_frontend/core/services/graphql_service.dart';
import 'package:sistema_eleitoral_frontend/features/election/data/election_service.dart';

const _nationalScope = '__national__';
const _scopeOptions = [
  (_nationalScope, 'Nacional'),
  ('alto-minho', 'Alto Minho'),
  ('cavado', 'Cavado'),
  ('ave', 'Ave'),
  ('am-porto', 'Porto'),
  ('alto-tamega', 'Alto Tamega'),
  ('tamega-e-sousa', 'Tamega e Sousa'),
  ('douro', 'Douro'),
  ('terras-tras-os-montes', 'Terras de Tras-os-Montes'),
  ('oeste', 'Oeste'),
  ('regiao-aveiro', 'Regiao de Aveiro'),
  ('regiao-coimbra', 'Regiao de Coimbra'),
  ('regiao-leiria', 'Regiao de Leiria'),
  ('viseu-dao-lafoes', 'Viseu Dao Lafoes'),
  ('beira-baixa', 'Beira Baixa'),
  ('medio-tejo', 'Medio Tejo'),
  ('beiras-serra', 'Beiras e Serra da Estrela'),
  ('am-lisboa', 'Lisboa'),
  ('alentejo-litoral', 'Alentejo Litoral'),
  ('baixo-alentejo', 'Baixo Alentejo'),
  ('lezira-do-tejo', 'Leziria do Tejo'),
  ('alto-alentejo', 'Alto Alentejo'),
  ('alentejo-central', 'Alentejo Central'),
  ('algarve', 'Algarve'),
  ('acores', 'Acores'),
  ('madeira', 'Madeira'),
];

class CreateElectionScreen extends StatefulWidget {
  const CreateElectionScreen({super.key});

  @override
  State<CreateElectionScreen> createState() => _CreateElectionScreenState();
}

class _CreateElectionScreenState extends State<CreateElectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  DateTime? _startDateTime;
  DateTime? _endDateTime;
  String _selectedScope = _nationalScope;
  bool _isLoading = false;
  String? _errorMessage;

  final _service = ElectionService(
    GraphQLService(baseUrl: 'http://localhost:8080/graphql'),
  );

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart
        ? (_startDateTime ?? now)
        : (_endDateTime ?? _startDateTime ?? now);

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 10)),
      helpText: isStart ? 'DATA DE ABERTURA' : 'DATA DE ENCERRAMENTO',
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      helpText: isStart ? 'HORA DE ABERTURA' : 'HORA DE ENCERRAMENTO',
    );
    if (time == null || !mounted) return;

    final dt =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _startDateTime = dt;
        if (_endDateTime != null && !_endDateTime!.isAfter(dt)) {
          _endDateTime = null;
        }
      } else {
        _endDateTime = dt;
      }
      _errorMessage = null;
    });
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;
    if (_startDateTime == null) {
      setState(() => _errorMessage = 'Selecione a data e hora de abertura.');
      return;
    }
    if (_endDateTime == null) {
      setState(
          () => _errorMessage = 'Selecione a data e hora de encerramento.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await _service.createElection(
        title: _titleController.text.trim(),
        startDate: _startDateTime!,
        endDate: _endDateTime!,
        scopeRegion: _selectedScope == _nationalScope ? null : _selectedScope,
      );
      if (!mounted) return;
      switch (result) {
        case CreateElectionSuccess():
          _showSuccessDialog(result);
        case CreateElectionFailure():
          setState(() => _errorMessage = result.message);
      }
    } catch (_) {
      setState(
        () => _errorMessage =
            'Não foi possível ligar ao servidor. Verifique a ligação.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(CreateElectionSuccess election) {
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.successContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.check_rounded,
                  size: 48, color: AppColors.success),
            ),
            const SizedBox(height: 20),
            Text(
              'Eleição criada.',
              style: GoogleFonts.instrumentSerif(
                fontSize: 26,
                color: AppColors.ink,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainerLow,
                border:
                    Border(left: BorderSide(color: AppColors.gold, width: 3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    election.title,
                    style: GoogleFonts.ibmPlexSans(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    election.scopeLabel,
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 11,
                      color: AppColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    election.id,
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 11,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
            ),
            child: Text(
              'CONCLUÍDO',
              style: GoogleFonts.ibmPlexSans(
                  fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 2),
            ),
          ),
        ],
      ),
    );
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
                icon:
                    const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
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
                        fontSize: 10,
                        letterSpacing: 1.8,
                        color: AppColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    RichText(
                      text: TextSpan(children: [
                        TextSpan(
                          text: 'Novo processo ',
                          style: GoogleFonts.instrumentSerif(
                            fontSize: 28,
                            color: AppColors.ink,
                            letterSpacing: -0.5,
                            height: 1.05,
                          ),
                        ),
                        TextSpan(
                          text: 'eleitoral.',
                          style: GoogleFonts.instrumentSerif(
                            fontSize: 28,
                            color: AppColors.oxblood,
                            fontStyle: FontStyle.italic,
                            letterSpacing: -0.5,
                            height: 1.05,
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
            _SectionLabel(numeral: 'I', text: 'IDENTIFICAÇÃO'),
            const SizedBox(height: 16),
            _FieldLabel(text: 'Título da Eleição'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              maxLength: 255,
              style:
                  GoogleFonts.ibmPlexSans(fontSize: 15, color: AppColors.ink),
              decoration: const InputDecoration(
                hintText: 'Ex: Eleições Presidenciais 2026',
                prefixIcon: Icon(Icons.title_rounded),
                counterText: '',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'O título é obrigatório.';
                }
                if (v.trim().length < 3) {
                  return 'O título deve ter pelo menos 3 caracteres.';
                }
                return null;
              },
            ),
            const SizedBox(height: 36),
            _SectionLabel(numeral: 'II', text: 'PERÍODO'),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _DatePickerField(
                    label: 'Abertura',
                    icon: Icons.play_circle_outline_rounded,
                    dateTime: _startDateTime,
                    accentColor: AppColors.success,
                    accentBg: AppColors.successContainer,
                    onTap: () => _pickDateTime(isStart: true),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                  child: Icon(Icons.arrow_forward_rounded,
                      color: AppColors.hairlineStrong, size: 18),
                ),
                Expanded(
                  child: _DatePickerField(
                    label: 'Encerramento',
                    icon: Icons.stop_circle_outlined,
                    dateTime: _endDateTime,
                    accentColor: AppColors.oxblood,
                    accentBg: AppColors.oxbloodContainer,
                    onTap: () => _pickDateTime(isStart: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _FieldLabel(text: 'Elegibilidade geografica'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedScope,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              isExpanded: true,
              items: _scopeOptions
                  .map((option) => DropdownMenuItem(
                        value: option.$1,
                        child: Text(option.$2),
                      ))
                  .toList(),
              onChanged: (value) => setState(() {
                _selectedScope = value ?? _nationalScope;
                _errorMessage = null;
              }),
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
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.onPrimary,
                      ),
                    )
                  : const Icon(Icons.how_to_vote_rounded),
              label: Text(
                _isLoading ? 'A criar eleição...' : 'Criar Eleição',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
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
        Row(
          children: [
            Text(
              '$numeral. $text',
              style: GoogleFonts.ibmPlexSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: AppColors.inkMuted,
              ),
            ),
          ],
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
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.ibmPlexSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: AppColors.inkMuted,
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.icon,
    required this.dateTime,
    required this.accentColor,
    required this.accentBg,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final DateTime? dateTime;
  final Color accentColor;
  final Color accentBg;
  final VoidCallback onTap;

  static const _months = [
    'Jan',
    'Fev',
    'Mar',
    'Abr',
    'Mai',
    'Jun',
    'Jul',
    'Ago',
    'Set',
    'Out',
    'Nov',
    'Dez',
  ];

  String _formatDate(DateTime dt) =>
      '${dt.day} ${_months[dt.month - 1]} ${dt.year}';
  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final hasValue = dateTime != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: hasValue
                ? accentColor.withValues(alpha: 0.6)
                : AppColors.hairline,
            width: hasValue ? 1.5 : 1.0,
          ),
          color: hasValue
              ? accentBg.withValues(alpha: 0.5)
              : AppColors.surfaceContainerLow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon,
                    size: 12, color: hasValue ? accentColor : AppColors.inkDim),
                const SizedBox(width: 5),
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: hasValue ? accentColor : AppColors.inkDim,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            hasValue
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(dateTime!),
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatTime(dateTime!),
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 12,
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 13, color: AppColors.inkDim),
                      const SizedBox(width: 6),
                      Text(
                        'Selecionar',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 13,
                          color: AppColors.inkDim,
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
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
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.atkinsonHyperlegible(
                fontSize: 13,
                color: AppColors.onOxbloodContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
