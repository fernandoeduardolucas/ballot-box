import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

void main() => runApp(const ElectionApp());

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
  static const api = 'http://localhost:8080';
  static const electionId = '11111111-1111-1111-1111-111111111111';
  final voterController = TextEditingController(text: '12345678');
  String status = 'Pronto';
  Map<String, dynamic>? election;
  Map<String, dynamic> results = {};
  late final WebSocketChannel auditChannel;

  @override
  void initState() {
    super.initState();
    auditChannel = WebSocketChannel.connect(Uri.parse('ws://localhost:8080/audit/stream'));
    loadElection();
    loadResults();
  }

  Future<void> loadElection() async {
    final response = await http.get(Uri.parse('$api/elections/$electionId'));
    setState(() => election = jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> registerVoter() async {
    final response = await http.post(
      Uri.parse('$api/voters'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'id': voterController.text, 'fullName': 'Eleitor Demo', 'electionId': electionId}),
    );
    setState(() => status = response.statusCode == 201 ? 'Eleitor registado' : response.body);
  }

  Future<void> vote(String candidateId) async {
    final response = await http.post(
      Uri.parse('$api/votes'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'voterId': voterController.text, 'electionId': electionId, 'candidateId': candidateId}),
    );
    setState(() => status = response.body);
    await loadResults();
  }

  Future<void> loadResults() async {
    final response = await http.get(Uri.parse('$api/results/$electionId'));
    setState(() => results = jsonDecode(response.body) as Map<String, dynamic>);
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
