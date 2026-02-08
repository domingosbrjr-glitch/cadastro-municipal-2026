class Household {
  final String uuid;
  String territory;
  String bairro;
  String logradouro;
  String numero;
  String referencia;
  int version;
  String updatedAt;

  Household({
    required this.uuid,
    this.territory = "",
    this.bairro = "",
    this.logradouro = "",
    this.numero = "",
    this.referencia = "",
    this.version = 0,
    this.updatedAt = "",
  });

  Map<String, dynamic> toJson() => {
    "uuid": uuid,
    "territory": territory,
    "bairro": bairro,
    "logradouro": logradouro,
    "numero": numero,
    "referencia": referencia,
    "version": version,
  };
}

class Person {
  final String uuid;
  String householdUuid;

  String cpf;
  String ipm;
  bool pendingCpf;
  String pendingReason;

  String fullName;
  String motherName;
  String birthDate;
  String phone;
  String bairro;
  String referencia;

  Map<String,dynamic> general;
  Map<String,dynamic> assistance;

  int version;
  String updatedAt;

  Person({
    required this.uuid,
    required this.householdUuid,
    this.cpf = "",
    this.ipm = "",
    this.pendingCpf = false,
    this.pendingReason = "",
    this.fullName = "",
    this.motherName = "",
    this.birthDate = "",
    this.phone = "",
    this.bairro = "",
    this.referencia = "",
    Map<String,dynamic>? general,
    Map<String,dynamic>? assistance,
    this.version = 0,
    this.updatedAt = "",
  }) : general = general ?? {},
       assistance = assistance ?? {};

  Map<String, dynamic> toJson() => {
    "uuid": uuid,
    "household_uuid": householdUuid,
    "cpf": cpf,
    "ipm": ipm,
    "pending_cpf": pendingCpf,
    "pending_reason": pendingReason,
    "full_name": fullName,
    "mother_name": motherName,
    "birth_date": birthDate,
    "phone": phone,
    "bairro": bairro,
    "referencia": referencia,
    "general": general,
    "assistance": assistance,
  };
}

class Attachment {
  final String uuid;
  final String entityType;
  final String entityUuid;
  final String purpose;
  final String filePath;
  final int sizeBytes;
  final String mime;
  final String status;

  Attachment({
    required this.uuid,
    required this.entityType,
    required this.entityUuid,
    required this.purpose,
    required this.filePath,
    required this.sizeBytes,
    required this.mime,
    required this.status,
  });
}

class OutboxItem {
  final String clientItemId;
  final String entityType;
  final String entityUuid;
  final String op;
  final String payloadJson;
  final int baseVersion;
  final String status;

  OutboxItem({
    required this.clientItemId,
    required this.entityType,
    required this.entityUuid,
    required this.op,
    required this.payloadJson,
    required this.baseVersion,
    required this.status,
  });
}
