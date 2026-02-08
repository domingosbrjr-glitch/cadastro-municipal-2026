import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../local_db.dart';
import '../models.dart';

class AttachmentsScreen extends StatefulWidget {
  final String entityType;
  final String entityUuid;
  const AttachmentsScreen({super.key, required this.entityType, required this.entityUuid});

  @override
  State<AttachmentsScreen> createState() => _AttachmentsScreenState();
}

class _AttachmentsScreenState extends State<AttachmentsScreen> {
  final LocalDb db = LocalDb();
  final picker = ImagePicker();
  final Uuid uuid = const Uuid();

  String purpose = "Comprovante de residência";

  Future<void> _pickAndSave() async {
    final x = await picker.pickImage(source: ImageSource.camera, imageQuality: 100);
    if (x == null) return;

    final dir = await getApplicationDocumentsDirectory();
    final outPath = "${dir.path}/${uuid.v4()}.jpg";

    final result = await FlutterImageCompress.compressAndGetFile(
      x.path,
      outPath,
      quality: 70,
      format: CompressFormat.jpeg,
    );
    if (result == null) return;

    final f = File(result.path);
    final size = await f.length();

    final att = Attachment(
      uuid: uuid.v4(),
      entityType: widget.entityType,
      entityUuid: widget.entityUuid,
      purpose: purpose,
      filePath: result.path,
      sizeBytes: size,
      mime: "image/jpeg",
      status: "pending",
    );

    await db.insertAttachment(att);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Anexo salvo e enfileirado para upload")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Anexos")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: purpose,
              items: const [
                DropdownMenuItem(value: "Comprovante de residência", child: Text("Comprovante de residência")),
                DropdownMenuItem(value: "Documento identificação", child: Text("Documento identificação")),
                DropdownMenuItem(value: "Outros", child: Text("Outros")),
              ],
              onChanged: (v) => setState(() => purpose = v ?? purpose),
              decoration: const InputDecoration(labelText: "Finalidade"),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _pickAndSave,
              icon: const Icon(Icons.camera_alt),
              label: const Text("Capturar foto e salvar offline"),
            ),
            const SizedBox(height: 12),
            const Text("Os anexos serão enviados quando você tocar em 'Sincronizar' na tela inicial."),
          ],
        ),
      ),
    );
  }
}
