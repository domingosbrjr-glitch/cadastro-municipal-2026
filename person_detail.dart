import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../local_db.dart';
import '../models.dart';
import '../cpf.dart';
import 'attachments.dart';

class PersonDetailScreen extends StatefulWidget {
  final String personUuid;
  const PersonDetailScreen({super.key, required this.personUuid});

  @override
  State<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends State<PersonDetailScreen> {
  final LocalDb db = LocalDb();
  final Uuid uuid = const Uuid();
  Person? person;

  final _cpf = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    person = await db.getPerson(widget.personUuid);
    if (person != null) {
      _cpf.text = person!.cpf;
      _name.text = person!.fullName;
      _phone.text = person!.phone;
    }
    setState(() {});
  }

  Future<void> _saveBasic() async {
    if (person == null) return;
    person!.fullName = _name.text.trim();
    person!.phone = _phone.text.trim();
    person!.updatedAt = DateTime.now().toIso8601String();
    await db.upsertPerson(person!);

    await db.addOutboxItem(OutboxItem(
      clientItemId: uuid.v4(),
      entityType: "person",
      entityUuid: person!.uuid,
      op: "update",
      payloadJson: jsonEncode(person!.toJson()),
      baseVersion: 0,
      status: "pending",
    ));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Salvo offline e enfileirado")));
  }

  Future<void> _regularizeCpf() async {
    if (person == null) return;
    final cpf = normalizeCpf(_cpf.text);
    if (!isValidCpf(cpf)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("CPF inválido")));
      return;
    }
    person!.cpf = cpf;
    person!.pendingCpf = false;
    person!.pendingReason = "";
    person!.updatedAt = DateTime.now().toIso8601String();
    await db.upsertPerson(person!);

    await db.addOutboxItem(OutboxItem(
      clientItemId: uuid.v4(),
      entityType: "person",
      entityUuid: person!.uuid,
      op: "update",
      payloadJson: jsonEncode(person!.toJson()),
      baseVersion: 0,
      status: "pending",
    ));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("CPF regularizado (offline)")));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (person == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Pessoa")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: "Nome")),
            TextField(controller: _phone, decoration: const InputDecoration(labelText: "Telefone")),
            const SizedBox(height: 8),
            TextField(controller: _cpf, decoration: const InputDecoration(labelText: "CPF (para regularizar)")),
            if (person!.pendingCpf)
              FilledButton(onPressed: _regularizeCpf, child: const Text("Regularizar CPF")),
            const SizedBox(height: 8),
            FilledButton(onPressed: _saveBasic, child: const Text("Salvar alterações")),
            const Divider(),
            ListTile(
              title: const Text("Anexos (foto)"),
              subtitle: const Text("Adicionar comprovantes, documentos etc."),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AttachmentsScreen(entityType: "person", entityUuid: person!.uuid))),
            ),
            const Divider(),
            Text("Cadastro Geral: ${person!.general}"),
            const SizedBox(height: 6),
            Text("Assistência: ${person!.assistance}"),
          ],
        ),
      ),
    );
  }
}
