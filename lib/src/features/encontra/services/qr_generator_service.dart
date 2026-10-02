import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:archive/archive.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'web_download_helper.dart' if (dart.library.html) 'web_download_helper_web.dart';

class TagGenData {
  final String uuid;
  final String pin;
  Uint8List? pngBytes;

  TagGenData({required this.uuid, required this.pin});
}

class QrGeneratorService {
  final _supabase = Supabase.instance.client;

  // Gerador de UUID v4 nativo sem dependências externas
  String _generateUUIDv4() {
    final random = Random.secure();
    String hex(int val, int len) => val.toRadixString(16).padLeft(len, '0');

    final r1 = random.nextInt(0xFFFFFFFF);
    final r2 = random.nextInt(0xFFFFFFFF);
    final r3 = random.nextInt(0xFFFFFFFF);
    final r4 = random.nextInt(0xFFFFFFFF);

    final timeLow = hex(r1, 8);
    final timeMid = hex(r2 & 0xFFFF, 4);
    final timeHiAndVersion = hex((r2 >> 16 & 0x0FFF) | 0x4000, 4);
    final clockSeqHiAndReserved = hex((r3 & 0x3F) | 0x80, 2);
    final clockSeqLow = hex(r3 >> 8 & 0xFF, 2);
    final nodePart = hex(r4, 8) + hex(random.nextInt(0xFFFF), 4);

    return '$timeLow-$timeMid-$timeHiAndVersion-$clockSeqHiAndReserved$clockSeqLow-$nodePart';
  }

  // Gerador de PIN numérico de 6 dígitos
  String _generatePIN() {
    final random = Random.secure();
    return List.generate(6, (_) => random.nextInt(10).toString()).join();
  }

  // Gera imagens de QR Code em bytes PNG em memória
  Future<Uint8List> _generateQrBytes(String url) async {
    final qrValidationResult = QrValidator.validate(
      data: url,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.L,
    );
    if (qrValidationResult.status != QrValidationStatus.valid) {
      throw 'Erro ao validar QR Code para a URL: $url';
    }
    final painter = QrPainter.withQr(
      qr: qrValidationResult.qrCode!,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Color(0xFF000000),
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Color(0xFF000000),
      ),
      gapless: true,
    );
    final image = await painter.toImage(300);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw 'Erro ao converter QR Code para bytes PNG';
    }
    return byteData.buffer.asUint8List();
  }

  /// Gera lote de tags, registra no Supabase, compacta em ZIP e faz o download.
  /// O callback [onProgress] recebe (statusMessage, progressPercent).
  Future<bool> generateBatch({
    required int quantity,
    required void Function(String status, double progress) onProgress,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw 'Usuário não autenticado. Faça login novamente.';
      }

      // Passo 1: Geração local de chaves
      onProgress('Gerando chaves UUID e PIN...', 0.1);
      final List<TagGenData> tags = List.generate(quantity, (_) {
        return TagGenData(
          uuid: _generateUUIDv4(),
          pin: _generatePIN(),
        );
      });

      // Passo 2: Registro no Supabase
      onProgress('Registrando lote de tags no banco de dados...', 0.3);
      final dataToInsert = tags.map((t) => {
        'id': t.uuid,
        'pin_code': t.pin,
        'status': 'inactive',
        'pet_id': null,
        'activated_at': null,
      }).toList();

      await _supabase.from('tags').insert(dataToInsert);

      // Passo 3: Geração das imagens de QR Code
      onProgress('Gerando imagens de QR Code em lote...', 0.5);
      for (int i = 0; i < tags.length; i++) {
        final t = tags[i];
        final url = 'https://patas.online/encontra/t/${t.uuid}';
        t.pngBytes = await _generateQrBytes(url);

        // Atualiza progresso proporcionalmente
        final currentProgress = 0.5 + (0.3 * (i / tags.length));
        onProgress('Gerando QR Codes (${i + 1}/$quantity)...', currentProgress);
      }

      // Passo 4: Compactação do arquivo ZIP
      onProgress('Criando pacote compactado (ZIP)...', 0.85);
      final archive = Archive();

      // Adiciona cada arquivo de imagem no ZIP
      for (int i = 0; i < tags.length; i++) {
        final t = tags[i];
        final seq = (i + 1).toString().padLeft(4, '0');
        final filename = 'qrcodes/${seq}_QR_${t.pin}.png';
        archive.addFile(ArchiveFile(
          filename,
          t.pngBytes!.length,
          t.pngBytes!,
        ));
      }

      // Adiciona o arquivo CSV no ZIP
      final csvLines = tags.asMap().entries.map((e) {
            final seq = (e.key + 1).toString().padLeft(4, '0');
            return '$seq,${e.value.uuid},${e.value.pin},https://patas.online/encontra/t/${e.value.uuid}';
          }).join('\n');
      final csvContent = 'Sequencial,UUID,PIN,Link_Acesso\n$csvLines';

      final csvBytes = utf8.encode(csvContent);
      archive.addFile(ArchiveFile(
        'tags.csv',
        csvBytes.length,
        csvBytes,
      ));

      // Codifica o ZIP
      final zipEncoder = ZipEncoder();
      final zipBytes = zipEncoder.encode(archive);
      if (zipBytes == null) {
        throw 'Erro ao compactar arquivos de lote';
      }

      // Passo 5: Download no navegador
      onProgress('Iniciando download do lote...', 0.95);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      downloadBytes(
        Uint8List.fromList(zipBytes),
        'lote_patas_encontra_$timestamp.zip',
      );

      onProgress('Concluído!', 1.0);
      return true;
    } catch (e) {
      debugPrint('QrGeneratorService.generateBatch error: $e');
      rethrow;
    }
  }
}
