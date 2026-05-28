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

  final _service = const AuditStreamService();
  final _scrollController = ScrollController();
  final List<_AuditLine> _lines = [];

  AuditStreamConnection? _connection;
  StreamSubscription<AuditStreamEvent>? _subscription;
  String _status = 'a ligar';
  bool _connected = false;

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
          ),
          Expanded(
            child: _lines.isEmpty
                ? const _EmptyConsole()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                    itemCount: _lines.length,
                    itemBuilder: (context, index) => _ConsoleLine(line: _lines[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ConsoleHeader extends StatelessWidget {
  const _ConsoleHeader({
    required this.status,
    required this.connected,
    required this.onReconnect,
  });

  final String status;
  final bool connected;
  final VoidCallback onReconnect;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      padding: const EdgeInsets.only(left: 14, right: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF0B1912),
        border: Border(bottom: BorderSide(color: Color(0xFF20372C))),
      ),
      child: Row(
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
    );
  }
}

class _EmptyConsole extends StatelessWidget {
  const _EmptyConsole();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Align(
        alignment: Alignment.topLeft,
        child: Text(
          '> a aguardar eventos de seguranca...',
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
