import 'package:flutter/material.dart';
import '../auth_store.dart';
import '../local_db.dart';
import '../sync_service.dart';
import 'new_household.dart';
import 'household_detail.dart';
import 'pending_cpf.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocalDb db = LocalDb();
  final SyncService sync = SyncService();
  final AuthStore auth = AuthStore();

  List<Map<String,dynamic>> households = [];
  int pendingOutbox = 0;
  int conflictOutbox = 0;
  int pendingCpfCount = 0;
  String userEmail = "";
  String role = "";
  String lastSync = "";

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    households = await db.listHouseholds();
    pendingOutbox = await db.outboxCount(status: "pending");
    conflictOutbox = await db.outboxCount(status: "conflict");
    pendingCpfCount = (await db.listPendingCpf()).length;
    userEmail = await auth.email();
    role = await auth.role();
    lastSync = await auth.lastSyncIso();
    setState(() {});
  }

  Future<void> _sync() async {
    final r = await sync.syncAll(deviceId: "android");
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r.toString())));
    await _reload();
  }

  Future<void> _logout() async {
    await auth.clear();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed("/login");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cadastro Municipal Offline"),
        actions: [
          IconButton(onPressed: _sync, icon: const Icon(Icons.sync)),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const NewHouseholdScreen()));
          await _reload();
        },
        child: const Icon(Icons.add_home),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Usuário: $userEmail ($role)"),
            Text("Último pull: ${lastSync.isEmpty ? "nunca" : lastSync}"),
            const SizedBox(height: 6),
            Text("Fila pendente: $pendingOutbox | Conflitos: $conflictOutbox | Pendentes CPF: $pendingCpfCount"),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                title: const Text("Pendentes CPF"),
                subtitle: const Text("Abrir lista para regularizar CPF"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const PendingCpfScreen()));
                  await _reload();
                },
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: households.length,
                itemBuilder: (context, idx) {
                  final h = households[idx];
                  return Card(
                    child: ListTile(
                      title: Text("${h["bairro"] ?? ""} — ${h["referencia"] ?? ""}"),
                      subtitle: Text("Atualizado: ${h["updated_at"] ?? ""}"),
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => HouseholdDetailScreen(household: h)));
                        await _reload();
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
