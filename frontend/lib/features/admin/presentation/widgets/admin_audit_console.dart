import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sistema_eleitoral_frontend/features/admin/data/audit_stream_service.dart';

class AdminAuditConsole extends StatefulWidget {
  const AdminAuditConsole({super.key});

  @override
  State<AdminAuditConsole> createState() => _AdminAuditConsoleState();
}

class _AdminAuditConsoleState extends State<AdminAuditConsole> {
  static const _maxLines = 200;
  static const _filterAll = 'TODOS';
  static const _defaultTypes = ['LOGIN', 'VOTE_CAST', 'DOUBLE_VOTE_ATTEMPT'];

  final _service = const AuditStreamService();
  final _scrollController = ScrollController();
  final List<_AuditLine> _lines = [];

  AuditStreamConnection? _connection;
  StreamSubscription<AuditStreamEvent>? _subscription;
  String _status = 'a ligar';
  bool _connected = false;
  String _selectedEventType = _filterAll;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    unawaited(_connection?.close());
    _scrollController.dispose();
    super.dispose();
  }

  void _connect() {
    unawaited(_subscription?.cancel());
    unawaited(_connection?.close());

    setState(() {
      _status = 'a ligar';
      _connected = false;
    });

    final connection = _service.connect();
    _connection = connection;

    connection.ready.then((_) {
      if (!mounted || _connection != connection) return;
      setState(() {
        _status = 'online';
        _connected = true;
      });
    }).catchError((Object _) {
      if (!mounted || _connection != connection) return;
      setState(() {
        _status = 'sem ligacao';
        _connected = false;
      });
    });

    _subscription = connection.events.listen(
      (event) {
        setState(() {
          _lines.add(_AuditLine(event: event, receivedAt: DateTime.now()));
          if (_lines.length > _maxLines) {
            _lines.removeRange(0, _lines.length - _maxLines);
          }
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      },
      onError: (Object _) {
        if (!mounted) return;
        setState(() {
          _status = 'erro';
          _connected = false;
        });
      },
      onDone: () {
        if (!mounted) return;
        setState(() {
          _status = 'desligado';
          _connected = false;
        });
      },
    );
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredLines = _selectedEventType == _filterAll
        ? _lines
        : _lines.where((line) => line.event.eventType == _selectedEventType).toList();

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF07110D),
        border: Border(left: BorderSide(color: Color(0xFF20372C))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ConsoleHeader(
            status: _status,
            connected: _connected,
            onReconnect: _connect,
            filterOptions: _eventTypeOptions(),
            selectedFilter: _selectedEventType,
            onFilterChanged: (value) {
              setState(() => _selectedEventType = value);
            },
          ),
          Expanded(
            child: filteredLines.isEmpty
                ? _EmptyConsole(hasFilter: _lines.isNotEmpty)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                    itemCount: filteredLines.length,
                    itemBuilder: (context, index) => _ConsoleLine(line: filteredLines[index]),
                  ),
          ),
        ],
      ),
    );
  }

  List<String> _eventTypeOptions() {
    final seenTypes = _lines.map((line) => line.event.eventType).toSet().toList()..sort();
    final options = <String>{
      _filterAll,
      ..._defaultTypes,
      ...seenTypes,
    };
    return options.toList();
  }
}

class _ConsoleHeader extends StatelessWidget {
  const _ConsoleHeader({
    required this.status,
    required this.connected,
    required this.onReconnect,
    required this.filterOptions,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final String status;
  final bool connected;
  final VoidCallback onReconnect;
  final List<String> filterOptions;
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 10),
      decoration: const BoxDecoration(
        color: Color(0xFF0B1912),
        border: Border(bottom: BorderSide(color: Color(0xFF20372C))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: connected ? const Color(0xFF57D68D) : const Color(0xFFE3A13B),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'AUDITORIA / STREAM',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.ibmPlexMono(
                    color: const Color(0xFFE4F3E9),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Text(
                status.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.ibmPlexMono(
                  color: connected ? const Color(0xFF57D68D) : const Color(0xFFE3A13B),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              IconButton(
                onPressed: onReconnect,
                tooltip: 'Reconectar',
                icon: const Icon(Icons.refresh_rounded, size: 17),
                color: const Color(0xFFE4F3E9),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 24,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: filterOptions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final option = filterOptions[index];
                final selected = option == selectedFilter;
                return _TypeChip(
                  label: option,
                  selected: selected,
                  onTap: () => onFilterChanged(option),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(2),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1D3A2C) : const Color(0xFF0E2118),
          border: Border.all(
            color: selected ? const Color(0xFF57D68D) : const Color(0xFF2E4F3F),
          ),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          label,
          style: GoogleFonts.ibmPlexMono(
            color: selected ? const Color(0xFFB8E7C8) : const Color(0xFF87A891),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}

class _EmptyConsole extends StatelessWidget {
  const _EmptyConsole({required this.hasFilter});

  final bool hasFilter;

  @override
  Widget build(BuildContext context) {
    final message = hasFilter
        ? '> sem eventos para este tipo de filtro...'
        : '> a aguardar eventos de seguranca...';

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Align(
        alignment: Alignment.topLeft,
        child: Text(
          message,
          style: GoogleFonts.ibmPlexMono(
            color: const Color(0xFF87A891),
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

class _ConsoleLine extends StatelessWidget {
  const _ConsoleLine({required this.line});

  final _AuditLine line;

  @override
  Widget build(BuildContext context) {
    final event = line.event;
    final color = _lineColor(event);

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        _formatLine(line),
        maxLines: 1,
        overflow: TextOverflow.fade,
        softWrap: false,
        style: GoogleFonts.ibmPlexMono(
          color: color,
          fontSize: 11.5,
          height: 1.35,
        ),
      ),
    );
  }

  Color _lineColor(AuditStreamEvent event) {
    if (event.eventType == 'DOUBLE_VOTE_ATTEMPT') return const Color(0xFFFF7A7A);
    if (!event.success) return const Color(0xFFE3A13B);
    return const Color(0xFFB8E7C8);
  }

  String _formatLine(_AuditLine line) {
    final event = line.event;
    final time = _formatTime(line.receivedAt);
    final status = event.success ? 'OK' : 'FAIL';
    final actor = event.civilId ?? 'anon';
    final reason = event.reason == null ? '' : ' ref=${event.reason}';
    return '[$time] ${event.eventType} $status id=$actor ip=${event.ip}$reason';
  }

  String _formatTime(DateTime value) {
    final h = value.hour.toString().padLeft(2, '0');
    final m = value.minute.toString().padLeft(2, '0');
    final s = value.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

class _AuditLine {
  const _AuditLine({
    required this.event,
    required this.receivedAt,
  });

  final AuditStreamEvent event;
  final DateTime receivedAt;
}
