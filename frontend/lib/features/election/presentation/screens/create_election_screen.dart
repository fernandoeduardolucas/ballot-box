import 'package:flutter/material.dart';
import 'package:sistema_eleitoral_frontend/core/theme/app_colors.dart';
import 'package:sistema_eleitoral_frontend/core/services/graphql_service.dart';
import 'package:sistema_eleitoral_frontend/features/election/data/election_service.dart';

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
    final initial =
        isStart ? (_startDateTime ?? now) : (_endDateTime ?? _startDateTime ?? now);

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

    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _startDateTime = dt;
        if (_endDateTime != null && !_endDateTime!.isAfter(dt)) _endDateTime = null;
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
      setState(() => _errorMessage = 'Selecione a data e hora de encerramento.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await _service.createElection(
        title: _titleController.text.trim(),
        startDate: _startDateTime!,
        endDate: _endDateTime!,
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
        () => _errorMessage = 'Não foi possível ligar ao servidor. Verifique a ligação.',
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
        backgroundColor: AppColors.navySurf,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.gold.withValues(alpha: 0.3)),
        ),
        contentPadding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: Color(0xFF1A3320),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, size: 52, color: Color(0xFF4CAF50)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Eleição criada!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.offWhite,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.navyLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E2D42)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    election.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.offWhite,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    election.id,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.subtle,
                      fontFamily: 'monospace',
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
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Concluído', style: TextStyle(fontSize: 15)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      appBar: _buildAppBar(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 36),
                _buildFormCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.navy,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.offWhite),
        tooltip: 'Voltar',
        onPressed: () => Navigator.pop(context),
      ),
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'COMISSÃO NACIONAL DE ELEIÇÕES',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.gold,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          Text(
            'Painel de Administração',
            style: TextStyle(fontSize: 15, color: AppColors.offWhite),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.gold.withValues(alpha: 0.3)),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
          ),
          child: const Icon(Icons.add_circle_outline_rounded, color: AppColors.gold, size: 28),
        ),
        const SizedBox(height: 20),
        const Text(
          'NOVO PROCESSO ELEITORAL',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.5,
            color: AppColors.gold,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Criar Eleição',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: AppColors.offWhite,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Defina o título e o período da eleição. A data de encerramento tem de ser posterior à data de abertura.',
          style: TextStyle(fontSize: 15, color: AppColors.subtle, height: 1.6),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navySurf,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E2D42)),
      ),
      padding: const EdgeInsets.all(32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _FieldLabel(text: 'Título da Eleição'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              maxLength: 255,
              style: const TextStyle(fontSize: 15, color: AppColors.offWhite),
              decoration: InputDecoration(
                hintText: 'Ex: Eleições Presidenciais 2026',
                prefixIcon: const Icon(Icons.title_rounded),
                counterText: '',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'O título é obrigatório.';
                if (v.trim().length < 3) return 'O título deve ter pelo menos 3 caracteres.';
                return null;
              },
            ),
            const SizedBox(height: 28),
            const _FieldLabel(text: 'Período da Eleição'),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _DatePickerField(
                    label: 'Abertura',
                    icon: Icons.play_circle_outline_rounded,
                    dateTime: _startDateTime,
                    accentColor: const Color(0xFF4CAF50),
                    onTap: () => _pickDateTime(isStart: true),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.subtle.withValues(alpha: 0.4),
                  ),
                ),
                Expanded(
                  child: _DatePickerField(
                    label: 'Encerramento',
                    icon: Icons.stop_circle_outlined,
                    dateTime: _endDateTime,
                    accentColor: const Color(0xFFEF5350),
                    onTap: () => _pickDateTime(isStart: false),
                  ),
                ),
              ],
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
                        color: AppColors.navy,
                      ),
                    )
                  : const Icon(Icons.how_to_vote_rounded),
              label: Text(
                _isLoading ? 'A criar eleição...' : 'Criar Eleição',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: AppColors.subtle,
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
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final DateTime? dateTime;
  final Color accentColor;
  final VoidCallback onTap;

  static const _months = [
    'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
    'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
  ];

  String _formatDate(DateTime dt) => '${dt.day} ${_months[dt.month - 1]} ${dt.year}';
  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final hasValue = dateTime != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue ? accentColor.withValues(alpha: 0.55) : const Color(0xFF2E3D54),
            width: hasValue ? 1.5 : 1.0,
          ),
          color: hasValue ? accentColor.withValues(alpha: 0.08) : AppColors.navyLight,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 13,
                  color: hasValue ? accentColor : AppColors.subtle,
                ),
                const SizedBox(width: 5),
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: hasValue ? accentColor : AppColors.subtle,
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
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.offWhite,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatTime(dateTime!),
                        style: const TextStyle(fontSize: 13, color: AppColors.subtle),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: AppColors.subtle.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Selecionar',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.subtle.withValues(alpha: 0.6),
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
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: cs.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: cs.onErrorContainer,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
