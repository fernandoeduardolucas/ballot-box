import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:sistema_eleitoral_frontend/core/theme/app_colors.dart';

class RealTimeResultsScreen extends StatefulWidget {
  const RealTimeResultsScreen({super.key});

  @override
  State<RealTimeResultsScreen> createState() => _RealTimeResultsScreenState();
}

class _RealTimeResultsScreenState extends State<RealTimeResultsScreen> {
  late final WebSocketChannel channel;
  
  // Mapa local para armazenar a contagem por candidato (ID -> Total)
  final Map<String, int> _counts = {};

  @override
  void initState() {
    super.initState();
    // Liga ao endpoint criado no Scala (http4s WebSocket)
    channel = WebSocketChannel.connect(
      Uri.parse('ws://localhost:8080/audit/stream'),
    );
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  void _updateCounts(Map<String, dynamic> event) {
    // Exemplo do evento: { "electionId": "...", "candidateId": "..." }
    final candidateId = event['candidateId'] as String?;
    if (candidateId != null) {
      _counts[candidateId] = (_counts[candidateId] ?? 0) + 1;
    }
  }

  List<BarChartGroupData> _generateBarGroups() {
    int index = 0;
    return _counts.entries.map((entry) {
      final data = BarChartGroupData(
        x: index++,
        barRods: [
          BarChartRodData(
            toY: entry.value.toDouble(),
            color: AppColors.oxblood,
            width: 22,
            borderRadius: BorderRadius.circular(4),
          )
        ],
      );
      return data;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Resultados em Tempo Real', style: GoogleFonts.instrumentSerif()),
        backgroundColor: AppColors.surface,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'A contagem é atualizada automaticamente via WebSocket.',
                style: GoogleFonts.atkinsonHyperlegible(fontSize: 16, color: AppColors.inkMuted),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: StreamBuilder(
                  stream: channel.stream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Erro de ligação: ${snapshot.error}'));
                    }

                    if (snapshot.hasData) {
                      try {
                        final event = jsonDecode(snapshot.data as String);
                        _updateCounts(event);
                      } catch (e) {
                        debugPrint('Erro ao fazer parse do evento: $e');
                      }
                    }

                    if (_counts.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return BarChart(
                      BarChartData(
                        barGroups: _generateBarGroups(),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                // Idealmente mapeávamos o ID do candidato ao Nome
                                final candidateIds = _counts.keys.toList();
                                if (value.toInt() >= 0 && value.toInt() < candidateIds.length) {
                                  final id = candidateIds[value.toInt()];
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      id.substring(0, 4).toUpperCase(), // Nome abreviado (mock)
                                      style: GoogleFonts.ibmPlexMono(fontSize: 10, color: AppColors.inkMuted),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: const FlGridData(show: false),
                      ),
                      swapAnimationDuration: const Duration(milliseconds: 300),
                      swapAnimationCurve: Curves.linear,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
