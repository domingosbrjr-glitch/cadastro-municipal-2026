import 'package:flutter/material.dart';
import '../local_db.dart';
import 'new_person.dart';
import 'person_detail.dart';

class HouseholdDetailScreen extends StatefulWidget {
  final Map<String,dynamic> household;
  const HouseholdDetailScreen({super.key, required this.household});

  @override
  State<HouseholdDetailScreen> createState() => _HouseholdDetailScreenState();
}

class _HouseholdDetailScreenState extends State<HouseholdDetailScreen> {
  final LocalDb db = LocalDb();
  List<Map<String,dynamic>> people = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    people = await db.listPeopleByHousehold(widget.household["uuid"] as String);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.household;
    return Scaffold(
      appBar: AppBar(title: const Text("Domicílio")),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => NewPersonScreen(household: h)));
          await _reload();
        },
        child: const Icon(Icons.person_add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Bairro: ${h["bairro"]}"),
            Text("Referência: ${h["referencia"]}"),
            const Divider(),
            const Text("Moradores", style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: people.length,
                itemBuilder: (context, idx) {
                  final p = people[idx];
                  return ListTile(
                    title: Text(p["full_name"] ?? ""),
                    subtitle: Text("CPF: ${p["cpf"]} | Pendente: ${(p["pending_cpf"] ?? 0) == 1}"),
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => PersonDetailScreen(personUuid: p["uuid"] as String)));
                      await _reload();
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
