import 'dart:convert';

import 'package:sistema_eleitoral_frontend/core/auth/auth_store.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

class AuditStreamEvent {
  const AuditStreamEvent({
    required this.eventType,
    required this.ip,
    required this.success,
    this.civilId,
    this.reason,
  });

  final String eventType;
  final String? civilId;
  final String ip;
  final bool success;
  final String? reason;

  factory AuditStreamEvent.fromJson(Map<String, dynamic> json) {
    return AuditStreamEvent(
      eventType: json['eventType'] as String? ?? 'UNKNOWN',
      civilId: json['civilId'] as String?,
      ip: json['ip'] as String? ?? 'unknown',
      success: json['success'] as bool? ?? false,
      reason: json['reason'] as String?,
    );
  }
}

class AuditStreamConnection {
  AuditStreamConnection(this._channel);

  final WebSocketChannel _channel;

  Future<void> get ready => _channel.ready;

  Stream<AuditStreamEvent> get events => _channel.stream.map((raw) {
        final decoded = jsonDecode(raw.toString()) as Map<String, dynamic>;
        return AuditStreamEvent.fromJson(decoded);
      });

  Future<void> close() => _channel.sink.close(status.goingAway);
}

class AuditStreamService {
  const AuditStreamService({
    this.baseUrl = 'ws://localhost:8080/admin/audit/stream',
  });

  final String baseUrl;

  AuditStreamConnection connect() {
    final uri = Uri.parse(baseUrl);
    final token = AuthStore.instance.token;
    final wsUri = uri.replace(
      queryParameters: {
        ...uri.queryParameters,
        if (token != null) 'token': token,
      },
    );

    return AuditStreamConnection(WebSocketChannel.connect(wsUri));
  }
}
