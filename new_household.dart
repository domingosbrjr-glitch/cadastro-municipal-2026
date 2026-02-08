import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../local_db.dart';
import '../models.dart';

class NewHouseholdScreen extends StatefulWidget {
  const NewHouseholdScreen({super.key});
  @override
  State<NewHouseholdScreen> createState() => _NewHouseholdScreenState();
}

class _NewHouseholdScreenState extends State<NewHouseholdScreen> {
  final _territory = TextEditingController(text: "Bairro Centro - Quadra 01");
  final _bairro = TextEditingController(text: "Centro");
  final _logradouro = TextEditingController();
  final _numero = TextEditingController();
  final _ref = TextEditingController();

  final LocalDb db = LocalDb();
  final Uuid uuid = const Uuid();

  Future<void> _save() async {
    if (_bairro.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bairro é obrigatório")));
      return;
    }
    final h = Household(
      uuid: uuid.v4(),
      territory: _territory.text.trim(),
      bairro: _bairro.text.trim(),
      logradouro: _logradouro.text.trim(),
      numero: _numero.text.trim(),
      referencia: _ref.text.trim(),
      version: 0,
      updatedAt: DateTime.now().toIso8601String(),
    );
    await db.upsertHousehold(h);
    await db.addOutboxItem(OutboxItem(
      clientItemId: uuid.v4(),
      entityType: "household",
      entityUuid: h.uuid,
      op: "create",
      payloadJson: jsonEncode(h.toJson()),
      baseVersion: 0,
      status: "pending",
    ));
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Novo Domicílio")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(controller: _territory, decoration: const InputDecoration(labelText: "Território")),
            TextField(controller: _bairro, decoration: const InputDecoration(labelText: "Bairro *")),
            TextField(controller: _logradouro, decoration: const InputDecoration(labelText: "Logradouro")),
            TextField(controller: _numero, decoration: const InputDecoration(labelText: "Número")),
            TextField(controller: _ref, decoration: const InputDecoration(labelText: "Referência")),
            const SizedBox(height: 12),
            FilledButton(onPressed: _save, child: const Text("Salvar offline")),
          ],
        ),
      ),
    );
  }
}
