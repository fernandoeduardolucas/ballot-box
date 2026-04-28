import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

/// Arranque da app Flutter.
void main() => runApp(const ElectionApp());

/// Widget raiz da aplicação.
class ElectionApp extends StatelessWidget {
  const ElectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema Eleitoral',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// Base URL da API backend.
  static const api = 'http://localhost:8080';
  /// Eleição demo usada na interface.
  static const electionId = '11111111-1111-1111-1111-111111111111';
  final voterController = TextEditingController(text: '12345678');
  String status = 'Pronto';
  Map<String, dynamic>? election;
  Map<String, dynamic> results = {};
  late final WebSocketChannel auditChannel;

  @override
  void initState() {
    super.initState();
    // Abre canal WebSocket para monitorização de auditoria.
    auditChannel = WebSocketChannel.connect(Uri.parse('ws://localhost:8080/audit/stream'));
    loadElection();
    loadResults();
  }

  Future<Map<String, dynamic>> graphQl(String query, Map<String, dynamic> variables) async {
    final response = await http.post(
      Uri.parse('$api/graphql'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'query': query, 'variables': variables}),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> loadElection() async {
    final payload = await graphQl(
      'query Election(\$id: String!) { election(id: \$id) { id title candidates { id name manifesto } } }',
      {'id': electionId},
    );
    setState(() => election = payload['data']?['election'] as Map<String, dynamic>?);
  }

  Future<void> registerVoter() async {
    final payload = await graphQl(
      'mutation RegisterVoter(\$id: String!, \$fullName: String!, \$electionId: String!) { registerVoter(id: \$id, fullName: \$fullName, electionId: \$electionId) { ok } }',
      {'id': voterController.text, 'fullName': 'Eleitor Demo', 'electionId': electionId},
    );
    final errors = payload['errors'] as List<dynamic>?;
    setState(() => status = errors == null ? 'Eleitor registado' : errors.first['message'].toString());
  }

  Future<void> vote(String candidateId) async {
    final payload = await graphQl(
      'mutation Vote(\$voterId: String!, \$electionId: String!, \$candidateId: String!) { vote(voterId: \$voterId, electionId: \$electionId, candidateId: \$candidateId) { accepted } }',
      {'voterId': voterController.text, 'electionId': electionId, 'candidateId': candidateId},
    );
    final errors = payload['errors'] as List<dynamic>?;
    setState(() => status = errors == null ? 'Voto registado com sucesso' : errors.first['message'].toString());
    await loadResults();
  }

  Future<void> loadResults() async {
    final payload = await graphQl(
      'query Results(\$electionId: String!) { results(electionId: \$electionId) }',
      {'electionId': electionId},
    );
    setState(() => results = (payload['data']?['results'] as Map<String, dynamic>?) ?? {});
  }

  @override
  void dispose() {
    auditChannel.sink.close();
    voterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final candidates = (election?['candidates'] as List<dynamic>? ?? []);
    return Scaffold(
      appBar: AppBar(title: const Text('Gestão de Sistema Eleitoral')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(election?['title']?.toString() ?? 'A carregar...', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            TextField(controller: voterController, decoration: const InputDecoration(labelText: 'Identificador do eleitor')),
            const SizedBox(height: 8),
            FilledButton(onPressed: registerVoter, child: const Text('Registar eleitor demo')),
            const Divider(height: 32),
            for (final c in candidates)
              Card(
                child: ListTile(
                  title: Text(c['name']),
                  subtitle: Text('${c['manifesto']} · votos: ${results[c['id']] ?? 0}'),
                  trailing: FilledButton(onPressed: () => vote(c['id']), child: const Text('Votar')),
                ),
              ),
            const Divider(height: 32),
            Text('Estado: $status'),
            const SizedBox(height: 16),
            Text('Auditoria em tempo real', style: Theme.of(context).textTheme.titleMedium),
            StreamBuilder(
              stream: auditChannel.stream,
              builder: (context, snapshot) => Text(snapshot.data?.toString() ?? 'Sem eventos ainda'),
            ),
          ],
        ),
      ),
    );
  }
}
