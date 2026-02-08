import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'models.dart';

class LocalDb {
  static final LocalDb _i = LocalDb._();
  LocalDb._();
  factory LocalDb() => _i;

  Database? _db;

  Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'cadastro_offline.db');
    final d = await openDatabase(
      path,
      version: 4,
      onCreate: (db, v) async => _create(db),
      onUpgrade: (db, oldV, newV) async {
        await db.execute('DROP TABLE IF EXISTS attachments');
        await db.execute('DROP TABLE IF EXISTS outbox');
        await db.execute('DROP TABLE IF EXISTS households');
        await db.execute('DROP TABLE IF EXISTS people');
        await _create(db);
      },
    );
    return d;
  }

  Future<void> _create(Database db) async {
    await db.execute('''
      CREATE TABLE households(
        uuid TEXT PRIMARY KEY,
        territory TEXT,
        bairro TEXT,
        logradouro TEXT,
        numero TEXT,
        referencia TEXT,
        version INTEGER,
        updated_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE people(
        uuid TEXT PRIMARY KEY,
        household_uuid TEXT,
        cpf TEXT,
        ipm TEXT,
        pending_cpf INTEGER,
        pending_reason TEXT,
        full_name TEXT,
        mother_name TEXT,
        birth_date TEXT,
        phone TEXT,
        bairro TEXT,
        referencia TEXT,
        general_json TEXT,
        assistance_json TEXT,
        version INTEGER,
        updated_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE outbox(
        client_item_id TEXT PRIMARY KEY,
        entity_type TEXT,
        entity_uuid TEXT,
        op TEXT,
        payload_json TEXT,
        base_version INTEGER,
        status TEXT,
        created_at INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE attachments(
        uuid TEXT PRIMARY KEY,
        entity_type TEXT,
        entity_uuid TEXT,
        purpose TEXT,
        file_path TEXT,
        size_bytes INTEGER,
        mime TEXT,
        status TEXT,
        created_at INTEGER
      )
    ''');
  }

  Future<void> upsertHousehold(Household h) async {
    final d = await db;
    await d.insert('households', {
      "uuid": h.uuid,
      "territory": h.territory,
      "bairro": h.bairro,
      "logradouro": h.logradouro,
      "numero": h.numero,
      "referencia": h.referencia,
      "version": h.version,
      "updated_at": h.updatedAt,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> upsertPerson(Person p) async {
    final d = await db;
    await d.insert('people', {
      "uuid": p.uuid,
      "household_uuid": p.householdUuid,
      "cpf": p.cpf,
      "ipm": p.ipm,
      "pending_cpf": p.pendingCpf ? 1 : 0,
      "pending_reason": p.pendingReason,
      "full_name": p.fullName,
      "mother_name": p.motherName,
      "birth_date": p.birthDate,
      "phone": p.phone,
      "bairro": p.bairro,
      "referencia": p.referencia,
      "general_json": jsonEncode(p.general),
      "assistance_json": jsonEncode(p.assistance),
      "version": p.version,
      "updated_at": p.updatedAt,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Person?> getPerson(String uuid) async {
    final d = await db;
    final rows = await d.query('people', where: 'uuid=?', whereArgs: [uuid], limit: 1);
    if (rows.isEmpty) return null;
    final r = rows.first;
    return Person(
      uuid: r["uuid"] as String,
      householdUuid: r["household_uuid"] as String,
      cpf: (r["cpf"] as String?) ?? "",
      ipm: (r["ipm"] as String?) ?? "",
      pendingCpf: ((r["pending_cpf"] as int?) ?? 0) == 1,
      pendingReason: (r["pending_reason"] as String?) ?? "",
      fullName: (r["full_name"] as String?) ?? "",
      motherName: (r["mother_name"] as String?) ?? "",
      birthDate: (r["birth_date"] as String?) ?? "",
      phone: (r["phone"] as String?) ?? "",
      bairro: (r["bairro"] as String?) ?? "",
      referencia: (r["referencia"] as String?) ?? "",
      general: jsonDecode((r["general_json"] as String?) ?? "{}") as Map<String,dynamic>,
      assistance: jsonDecode((r["assistance_json"] as String?) ?? "{}") as Map<String,dynamic>,
      version: (r["version"] as int?) ?? 0,
      updatedAt: (r["updated_at"] as String?) ?? "",
    );
  }

  Future<List<Map<String,dynamic>>> listHouseholds() async {
    final d = await db;
    return d.query('households', orderBy: 'updated_at DESC, rowid DESC');
  }

  Future<List<Map<String,dynamic>>> listPeopleByHousehold(String householdUuid) async {
    final d = await db;
    return d.query('people', where: 'household_uuid=?', whereArgs: [householdUuid], orderBy: 'updated_at DESC, rowid DESC');
  }

  Future<List<Map<String,dynamic>>> listPendingCpf() async {
    final d = await db;
    return d.query('people', where: 'pending_cpf=1', orderBy: 'updated_at DESC, rowid DESC');
  }

  Future<void> addOutboxItem(OutboxItem item) async {
    final d = await db;
    await d.insert('outbox', {
      "client_item_id": item.clientItemId,
      "entity_type": item.entityType,
      "entity_uuid": item.entityUuid,
      "op": item.op,
      "payload_json": item.payloadJson,
      "base_version": item.baseVersion,
      "status": item.status,
      "created_at": DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<OutboxItem>> fetchOutbox({int limit = 50}) async {
    final d = await db;
    final rows = await d.query('outbox', where: "status='pending'", orderBy: 'created_at ASC', limit: limit);
    return rows.map((r) => OutboxItem(
      clientItemId: r["client_item_id"] as String,
      entityType: r["entity_type"] as String,
      entityUuid: r["entity_uuid"] as String,
      op: r["op"] as String,
      payloadJson: r["payload_json"] as String,
      baseVersion: (r["base_version"] as int?) ?? 0,
      status: r["status"] as String,
    )).toList();
  }

  Future<int> hasOutboxForEntity(String entityType, String entityUuid) async {
    final d = await db;
    final rows = await d.query(
      'outbox',
      where: "entity_type=? AND entity_uuid=? AND status IN ('pending','conflict')",
      whereArgs: [entityType, entityUuid],
      limit: 1,
    );
    return rows.isNotEmpty ? 1 : 0;
  }

  Future<void> markConflict(String clientItemId) async {
    final d = await db;
    await d.update('outbox', {"status":"conflict"}, where: "client_item_id=?", whereArgs: [clientItemId]);
  }

  Future<void> deleteOutboxItem(String clientItemId) async {
    final d = await db;
    await d.delete('outbox', where: 'client_item_id=?', whereArgs: [clientItemId]);
  }

  Future<int> outboxCount({String status = "pending"}) async {
    final d = await db;
    final r = Sqflite.firstIntValue(await d.rawQuery("SELECT COUNT(*) FROM outbox WHERE status=?", [status]));
    return r ?? 0;
  }

  Future<void> insertAttachment(Attachment a) async {
    final d = await db;
    await d.insert('attachments', {
      "uuid": a.uuid,
      "entity_type": a.entityType,
      "entity_uuid": a.entityUuid,
      "purpose": a.purpose,
      "file_path": a.filePath,
      "size_bytes": a.sizeBytes,
      "mime": a.mime,
      "status": a.status,
      "created_at": DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Attachment>> pendingAttachments({int limit = 20}) async {
    final d = await db;
    final rows = await d.query('attachments', where: "status='pending'", orderBy: 'created_at ASC', limit: limit);
    return rows.map((r) => Attachment(
      uuid: r["uuid"] as String,
      entityType: r["entity_type"] as String,
      entityUuid: r["entity_uuid"] as String,
      purpose: (r["purpose"] as String?) ?? "",
      filePath: r["file_path"] as String,
      sizeBytes: (r["size_bytes"] as int?) ?? 0,
      mime: (r["mime"] as String?) ?? "image/jpeg",
      status: r["status"] as String,
    )).toList();
  }

  Future<void> markAttachmentSent(String uuid) async {
    final d = await db;
    await d.update('attachments', {"status":"sent"}, where: "uuid=?", whereArgs: [uuid]);
  }
}
