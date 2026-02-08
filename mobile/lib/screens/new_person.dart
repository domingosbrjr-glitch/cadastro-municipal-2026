import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../cpf.dart';
import '../local_db.dart';
import '../models.dart';

class NewPersonScreen extends StatefulWidget {
  final Map<String,dynamic> household;
  const NewPersonScreen({super.key, required this.household});
  @override
  State<NewPersonScreen> createState() => _NewPersonScreenState();
}

class _NewPersonScreenState extends State<NewPersonScreen> {
  final _cpf = TextEditingController();
  bool _noCpf = false;
  String _reason = "Sem documento no momento";

  final _name = TextEditingController();
  final _mother = TextEditingController();
  final _birth = TextEditingController();
  final _phone = TextEditingController();
  final _ref = TextEditingController();

  final _rg = TextEditingController();
  final _nis = TextEditingController();
  final _email = TextEditingController();

  String _renda = "Até 1 SM";
  bool _beneficio = false;

  final LocalDb db = LocalDb();
  final Uuid uuid = const Uuid();

  Future<void> _save() async {
    final bairro = (widget.household["bairro"] ?? "") as String;
    final referencia = _ref.text.trim().isEmpty ? (widget.household["referencia"] ?? "") as String : _ref.text.trim();

    String cpf = normalizeCpf(_cpf.text);
    if (!_noCpf) {
      if (cpf.isEmpty || !isValidCpf(cpf)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("CPF inválido")));
        return;
      }
      if (_name.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nome é obrigatório")));
        return;
      }
    } else {
      cpf = "";
      if (_name.text.trim().isEmpty || _birth.text.trim().isEmpty || _phone.text.trim().isEmpty || referencia.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pré-cadastro: preencha nome, nascimento, contato e referência")));
        return;
      }
    }

    final general = {"rg": _rg.text.trim(), "nis": _nis.text.trim(), "email": _email.text.trim()};
    final assistance = {"renda_faixa": _renda, "beneficio": _beneficio};

    final p = Person(
      uuid: uuid.v4(),
      householdUuid: widget.household["uuid"] as String,
      cpf: cpf,
      pendingCpf: _noCpf,
      pendingReason: _noCpf ? _reason : "",
      fullName: _name.text.trim(),
      motherName: _mother.text.trim(),
      birthDate: _birth.text.trim(),
      phone: _phone.text.trim(),
      bairro: bairro,
      referencia: referencia,
      general: general,
      assistance: assistance,
      version: 0,
      updatedAt: DateTime.now().toIso8601String(),
    );

    await db.upsertPerson(p);
    await db.addOutboxItem(OutboxItem(
      clientItemId: uuid.v4(),
      entityType: "person",
      entityUuid: p.uuid,
      op: "create",
      payloadJson: jsonEncode(p.toJson()),
      baseVersion: 0,
      status: "pending",
    ));

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Novo Morador")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            SwitchListTile(
              title: const Text("Sem CPF (pré-cadastro)"),
              value: _noCpf,
              onChanged: (v) => setState(() => _noCpf = v),
            ),
            if (!_noCpf) TextField(controller: _cpf, decoration: const InputDecoration(labelText: "CPF *")),
            if (_noCpf)
              DropdownButtonFormField<String>(
                value: _reason,
                items: const [
                  DropdownMenuItem(value: "Sem documento no momento", child: Text("Sem documento no momento")),
                  DropdownMenuItem(value: "Vulnerabilidade/urgência", child: Text("Vulnerabilidade/urgência")),
                  DropdownMenuItem(value: "Impossibilidade de coletar no ato", child: Text("Impossibilidade de coletar no ato")),
                ],
                onChanged: (v) => setState(() => _reason = v ?? _reason),
                decoration: const InputDecoration(labelText: "Motivo do pré-cadastro"),
              ),
            const SizedBox(height: 8),
            TextField(controller: _name, decoration: const InputDecoration(labelText: "Nome completo *")),
            TextField(controller: _mother, decoration: const InputDecoration(labelText: "Nome da mãe")),
            TextField(controller: _birth, decoration: const InputDecoration(labelText: "Nascimento (YYYY-MM-DD) *")),
            TextField(controller: _phone, decoration: const InputDecoration(labelText: "Telefone/Contato *")),
            TextField(controller: _ref, decoration: const InputDecoration(labelText: "Referência (se diferente do domicílio)")),
            const Divider(),
            const Text("Cadastro Geral (exemplo)", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: _rg, decoration: const InputDecoration(labelText: "RG")),
            TextField(controller: _nis, decoration: const InputDecoration(labelText: "NIS")),
            TextField(controller: _email, decoration: const InputDecoration(labelText: "E-mail")),
            const Divider(),
            const Text("Assistência (exemplo)", style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButtonFormField<String>(
              value: _renda,
              items: const [
                DropdownMenuItem(value: "Até 1 SM", child: Text("Até 1 SM")),
                DropdownMenuItem(value: "1 a 2 SM", child: Text("1 a 2 SM")),
                DropdownMenuItem(value: "Acima de 2 SM", child: Text("Acima de 2 SM")),
              ],
              onChanged: (v) => setState(() => _renda = v ?? _renda),
              decoration: const InputDecoration(labelText: "Renda familiar (faixa)"),
            ),
            SwitchListTile(
              title: const Text("Recebe benefício"),
              value: _beneficio,
              onChanged: (v) => setState(() => _beneficio = v),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: _save, child: const Text("Salvar offline")),
          ],
        ),
      ),
    );
  }
}
