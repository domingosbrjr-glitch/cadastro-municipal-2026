import 'package:flutter/material.dart';
import '../local_db.dart';
import 'person_detail.dart';

class PendingCpfScreen extends StatefulWidget {
  const PendingCpfScreen({super.key});
  @override
  State<PendingCpfScreen> createState() => _PendingCpfScreenState();
}

class _PendingCpfScreenState extends State<PendingCpfScreen> {
  final LocalDb db = LocalDb();
  List<Map<String,dynamic>> rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    rows = await db.listPendingCpf();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pendentes CPF")),
      body: ListView.builder(
        itemCount: rows.length,
        itemBuilder: (context, idx) {
          final p = rows[idx];
          return ListTile(
            title: Text(p["full_name"] ?? ""),
            subtitle: Text("Motivo: ${p["pending_reason"] ?? ""} | Tel: ${p["phone"] ?? ""}"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => PersonDetailScreen(personUuid: p["uuid"] as String)));
              await _load();
            },
          );
        },
      ),
    );
  }
}
