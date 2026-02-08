import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'config.dart';
import 'local_db.dart';
import 'auth_store.dart';
import 'api.dart';
import 'models.dart';

class SyncService {
  final LocalDb _db = LocalDb();
  final AuthStore _auth = AuthStore();
  final Api _api = Api();

  Future<Map<String,dynamic>> syncAll({String deviceId = "android"}) async {
    final token = await _auth.token();
    if (token.isEmpty) return {"ok": false, "error": "no_token"};

    final pushRes = await _push(token: token, deviceId: deviceId);
    final pullRes = await _pull(token: token);

    return {"ok": true, "push": pushRes, "pull": pullRes};
  }

  Future<Map<String,dynamic>> _push({required String token, required String deviceId}) async {
    final items = await _db.fetchOutbox(limit: 50);
    int accepted = 0, conflict = 0, rejected = 0;

    if (items.isNotEmpty) {
      final body = {
        "device_id": deviceId,
        "items": items.map((i) => {
          "client_item_id": i.clientItemId,
          "entity_type": i.entityType,
          "entity_uuid": i.entityUuid,
          "op": i.op,
          "payload": jsonDecode(i.payloadJson),
          "base_version": i.baseVersion,
        }).toList()
      };

      final resp = await http.post(
        Uri.parse("$gatewayBaseUrl/sync/push"),
        headers: {"Content-Type":"application/json", "Authorization":"Bearer $token"},
        body: jsonEncode(body),
      );

      if (resp.statusCode >= 300) return {"ok": false, "error": "push_http_${resp.statusCode}"};

      final data = jsonDecode(resp.body) as Map<String,dynamic>;
      final results = (data["results"] as List).cast<Map<String,dynamic>>();
      for (final r in results) {
        final id = r["client_item_id"] as String;
        final status = r["status"] as String;
        if (status == "accepted") { await _db.deleteOutboxItem(id); accepted++; }
        else if (status == "conflict") { await _db.markConflict(id); conflict++; }
        else { await _db.deleteOutboxItem(id); rejected++; }
      }
    }

    int attSent = 0;
    final atts = await _db.pendingAttachments(limit: 10);
    for (final a in atts) {
      try {
        final file = File(a.filePath);
        if (!await file.exists()) { await _db.markAttachmentSent(a.uuid); continue; }
        final req = http.MultipartRequest("POST", Uri.parse("$gatewayBaseUrl/attachments/upload"));
        req.headers["Authorization"] = "Bearer $token";
        req.fields["uuid"] = a.uuid;
        req.fields["entity_type"] = a.entityType;
        req.fields["entity_uuid"] = a.entityUuid;
        req.fields["purpose"] = a.purpose;
        req.files.add(await http.MultipartFile.fromPath("file", a.filePath));
        final streamed = await req.send();
        if (streamed.statusCode < 300) { await _db.markAttachmentSent(a.uuid); attSent++; }
      } catch (_) {}
    }

    return {"accepted": accepted, "conflict": conflict, "rejected": rejected, "attachments_sent": attSent};
  }

  Future<Map<String,dynamic>> _pull({required String token}) async {
    final since = await _auth.lastSyncIso();
    final data = await _api.pull(token, sinceIso: since);

    final households = (data["households"] as List).cast<Map<String,dynamic>>();
    final people = (data["people"] as List).cast<Map<String,dynamic>>();
    int appliedHouseholds = 0, appliedPeople = 0, skipped = 0;

    for (final h in households) {
      final uuid = h["uuid"] as String;
      if (await _db.hasOutboxForEntity("household", uuid) == 1) { skipped++; continue; }
      await _db.upsertHousehold(Household(
        uuid: uuid,
        territory: (h["territory"] ?? "") as String,
        bairro: (h["bairro"] ?? "") as String,
        logradouro: (h["logradouro"] ?? "") as String,
        numero: (h["numero"] ?? "") as String,
        referencia: (h["referencia"] ?? "") as String,
        version: (h["version"] ?? 0) as int,
        updatedAt: (h["updated_at"] ?? "") as String,
      ));
      appliedHouseholds++;
    }

    for (final p in people) {
      final uuid = p["uuid"] as String;
      if (await _db.hasOutboxForEntity("person", uuid) == 1) { skipped++; continue; }
      await _db.upsertPerson(Person(
        uuid: uuid,
        householdUuid: (p["household_uuid"] ?? "") as String,
        cpf: (p["cpf"] ?? "") as String,
        ipm: (p["ipm"] ?? "") as String,
        pendingCpf: (p["pending_cpf"] ?? false) as bool,
        pendingReason: (p["pending_reason"] ?? "") as String,
        fullName: (p["full_name"] ?? "") as String,
        motherName: (p["mother_name"] ?? "") as String,
        birthDate: (p["birth_date"] ?? "") as String,
        phone: (p["phone"] ?? "") as String,
        bairro: (p["bairro"] ?? "") as String,
        referencia: (p["referencia"] ?? "") as String,
        general: (p["general"] as Map?)?.cast<String,dynamic>() ?? {},
        assistance: (p["assistance"] as Map?)?.cast<String,dynamic>() ?? {},
        version: (p["version"] ?? 0) as int,
        updatedAt: (p["updated_at"] ?? "") as String,
      ));
      appliedPeople++;
    }

    final serverTime = (data["server_time"] ?? "") as String;
    if (serverTime.isNotEmpty) await _auth.setLastSyncIso(serverTime);

    return {"since": since, "server_time": serverTime, "households": appliedHouseholds, "people": appliedPeople, "skipped": skipped};
  }
}
