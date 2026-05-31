import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:sistema_eleitoral_frontend/core/services/graphql_service.dart';
import 'package:sistema_eleitoral_frontend/core/theme/app_colors.dart';
import 'package:sistema_eleitoral_frontend/features/election/data/election_service.dart';

enum ResultsView { grid, detail }

class RealTimeResultsSection extends StatefulWidget {
  const RealTimeResultsSection({super.key});

  @override
  State<RealTimeResultsSection> createState() => _RealTimeResultsSectionState();
}

class _RealTimeResultsSectionState extends State<RealTimeResultsSection> {
  final _service = ElectionService(GraphQLService(baseUrl: 'http://localhost:8080/graphql'));
  
  ResultsView _currentView = ResultsView.grid;
  ElectionItem? _selectedElection;
  
  late Future<List<ElectionItem>> _electionsFuture;
  Future<List<VoteCountItem>>? _resultsFuture;
  
  WebSocketChannel? _channel;
  final Map<String, VoteCountItem> _counts = {};

  @override
  void initState() {
    super.initState();
    _electionsFuture = _service.listAllElections();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  void _openDetail(ElectionItem election) {
    setState(() {
      _selectedElection = election;
      _currentView = ResultsView.detail;
      _counts.clear();
      _resultsFuture = _service.getElectionResults(election.id).then((results) {
        for (final r in results) {
          _counts[r.candidateId] = r;
        }
        return results;
      });
      
      final now = DateTime.now();
      final isActive = now.isAfter(election.startDate) && now.isBefore(election.endDate);
      
      // OPTIMIZAÇÃO: Só abrir ligação WebSocket se a eleição estiver Em Curso.
      if (isActive) {
        _channel?.sink.close();
        _channel = WebSocketChannel.connect(Uri.parse('ws://localhost:8080/audit/stream'));
        
        _channel!.stream.listen((message) {
          try {
            final event = jsonDecode(message as String);
            final eventElectionId = event['electionId'] as String?;
            final candidateId = event['candidateId'] as String?;
            
            if (eventElectionId == election.id && candidateId != null) {
              if (mounted) {
                setState(() {
                  final current = _counts[candidateId];
                  if (current != null) {
                    _counts[candidateId] = VoteCountItem(
                      candidateId: current.candidateId,
                      candidateName: current.candidateName,
                      count: current.count + 1,
                    );
                  }
                });
              }
            }
          } catch (e) {
            debugPrint('Erro WebSocket: $e');
          }
        });
      } else {
        _channel?.sink.close();
        _channel = null;
      }
    });
  }

  void _goBack() {
    setState(() {
      _currentView = ResultsView.grid;
      _selectedElection = null;
      _channel?.sink.close();
      _channel = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _currentView == ResultsView.grid 
          ? _buildGrid(key: const ValueKey('grid'))
          : _buildDetail(key: const ValueKey('detail')),
    );
  }

  Widget _buildGrid({Key? key}) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Resultados Eleitorais', style: GoogleFonts.instrumentSerif(fontSize: 32, color: AppColors.ink)),
              const SizedBox(height: 8),
              Text('Selecione uma eleição para aceder aos resultados consolidados ou em tempo real.', 
                style: GoogleFonts.atkinsonHyperlegible(fontSize: 15, color: AppColors.inkMuted)),
              const SizedBox(height: 40),
              
              FutureBuilder<List<ElectionItem>>(
                future: _electionsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Erro: ${snapshot.error}', style: const TextStyle(color: AppColors.error)));
                  }
                  
                  final elections = snapshot.data ?? [];
                  if (elections.isEmpty) {
                    return const Center(child: Text('Sem eleições registadas.'));
                  }
                  
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 400,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 20,
                      mainAxisExtent: 160,
                    ),
                    itemCount: elections.length,
                    itemBuilder: (context, index) {
                      final e = elections[index];
                      final now = DateTime.now();
                      final isEnded = now.isAfter(e.endDate);
                      final isActive = now.isAfter(e.startDate) && !isEnded;
                      
                      return MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => _openDetail(e),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              border: Border.all(color: AppColors.hairline),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isEnded ? AppColors.surfaceContainerHigh : (isActive ? AppColors.goldContainer.withValues(alpha: 0.3) : AppColors.surfaceContainer),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: Text(
                                    isEnded ? 'ENCERRADA' : (isActive ? 'EM CURSO' : 'AGENDADA'),
                                    style: GoogleFonts.ibmPlexMono(fontSize: 10, fontWeight: FontWeight.w700, color: isEnded ? AppColors.inkDim : (isActive ? AppColors.inkSubtle : AppColors.inkMuted)),
                                  ),
                                ),
                                const Spacer(),
                                Text(e.title, style: GoogleFonts.instrumentSerif(fontSize: 22, color: AppColors.ink, height: 1.1), maxLines: 2, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text('Ver resultados', style: GoogleFonts.ibmPlexSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.oxblood)),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.oxblood),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetail({Key? key}) {
    final e = _selectedElection!;
    final now = DateTime.now();
    final isActive = now.isAfter(e.startDate) && now.isBefore(e.endDate);
    final isEnded = now.isAfter(e.endDate);

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Detail Header
        Container(
          padding: const EdgeInsets.fromLTRB(40, 24, 40, 24),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.hairline)),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: _goBack,
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.inkMuted),
                tooltip: 'Voltar à Grelha',
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Resultados', style: GoogleFonts.ibmPlexSans(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: AppColors.inkMuted)),
                    Text(e.title, style: GoogleFonts.instrumentSerif(fontSize: 28, color: AppColors.ink, letterSpacing: -0.5)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isEnded ? AppColors.surfaceContainerHigh : (isActive ? AppColors.goldContainer.withValues(alpha: 0.3) : AppColors.surfaceContainer),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    if (isActive) ...[
                      const SizedBox(
                        width: 8, height: 8,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      isEnded ? 'DADOS HISTÓRICOS' : (isActive ? 'EM TEMPO REAL' : 'AGUARDANDO ABERTURA'),
                      style: GoogleFonts.ibmPlexMono(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1, color: isEnded ? AppColors.inkDim : (isActive ? AppColors.inkSubtle : AppColors.inkMuted)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Chart Area
        Expanded(
          child: FutureBuilder<List<VoteCountItem>>(
            future: _resultsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }
              if (snapshot.hasError) {
                return Center(child: Text('Erro ao carregar dados históricos: ${snapshot.error}', style: const TextStyle(color: AppColors.error)));
              }
              
              if (_counts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bar_chart_rounded, size: 48, color: AppColors.inkDim),
                      const SizedBox(height: 16),
                      Text('Sem votos registados nesta eleição.', style: GoogleFonts.instrumentSerif(fontSize: 24, color: AppColors.inkMuted)),
                    ],
                  ),
                );
              }

              final sortedCounts = _counts.values.toList()..sort((a, b) => b.count.compareTo(a.count));
              final maxY = sortedCounts.first.count.toDouble() * 1.2;

              return Padding(
                padding: const EdgeInsets.fromLTRB(40, 60, 40, 40),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY == 0 ? 10 : maxY,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => AppColors.ink,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final c = sortedCounts[group.x];
                          return BarTooltipItem(
                            '${c.candidateName}\n',
                            GoogleFonts.ibmPlexSans(color: AppColors.surface, fontWeight: FontWeight.bold, fontSize: 14),
                            children: [
                              TextSpan(
                                text: '${c.count} Votos',
                                style: GoogleFonts.ibmPlexMono(color: AppColors.gold, fontWeight: FontWeight.w500, fontSize: 12),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() < 0 || value.toInt() >= sortedCounts.length) return const SizedBox.shrink();
                            final name = sortedCounts[value.toInt()].candidateName;
                            return Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Text(
                                name.length > 15 ? '${name.substring(0, 15)}...' : name,
                                style: GoogleFonts.ibmPlexSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink),
                                textAlign: TextAlign.center,
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            if (value == 0 || value == maxY) return const SizedBox.shrink();
                            return Text(
                              value.toInt().toString(),
                              style: GoogleFonts.ibmPlexMono(fontSize: 11, color: AppColors.inkMuted),
                              textAlign: TextAlign.right,
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: (maxY / 5) > 0 ? (maxY / 5) : 1,
                      getDrawingHorizontalLine: (value) => FlLine(color: AppColors.hairline, strokeWidth: 1),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: const Border(
                        bottom: BorderSide(color: AppColors.ink, width: 2),
                        left: BorderSide(color: AppColors.hairline, width: 1),
                      ),
                    ),
                    barGroups: List.generate(sortedCounts.length, (i) {
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: sortedCounts[i].count.toDouble(),
                            color: AppColors.oxblood,
                            width: 32,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          )
                        ],
                      );
                    }),
                  ),
                  swapAnimationDuration: const Duration(milliseconds: 300),
                  swapAnimationCurve: Curves.easeOutCubic,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
