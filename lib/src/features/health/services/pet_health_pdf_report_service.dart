import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:patas_web_app/src/features/pets/models/pet_model.dart';
import 'package:patas_web_app/src/features/health/models/vaccine_model.dart';
import 'package:patas_web_app/src/features/health/services/health_service.dart';
import '../models/medical_record_model.dart';
import 'patas_saude_service.dart';

class PetHealthPdfReportService {
  final PatasSaudeService _saudeService = PatasSaudeService();
  final HealthService _healthService = HealthService();

  /// Tenta fazer o download dos bytes da foto do pet a partir da URL.
  /// Retorna null em caso de falha (sem internet, URL inválida, etc.).
  Future<Uint8List?> _fetchPetPhotoBytes(String? photoUrl) async {
    if (photoUrl == null || photoUrl.isEmpty) return null;
    try {
      final response = await http.get(Uri.parse(photoUrl));
      if (response.statusCode == 200) return response.bodyBytes;
    } catch (e) {
      debugPrint('PDF: falha ao carregar foto do pet: $e');
    }
    return null;
  }

  Future<void> generateAndExportPdfReport(Pet activePet) async {
    final pdf = pw.Document();

    // Buscar dados do Supabase e foto do pet em paralelo
    List<PetVaccine> vaccines = [];
    List<MedicalRecord> records = [];
    List<Prescription> prescriptions = [];
    Uint8List? petPhotoBytes;

    try {
      final results = await Future.wait([
        _healthService.getVaccines(activePet.id),
        _saudeService.getPetMedicalRecords(activePet.id),
        _saudeService.getPetPrescriptions(activePet.id),
        _fetchPetPhotoBytes(activePet.photoUrl),
      ]);
      vaccines = results[0] as List<PetVaccine>;
      records = results[1] as List<MedicalRecord>;
      prescriptions = results[2] as List<Prescription>;
      petPhotoBytes = results[3] as Uint8List?;
    } catch (e) {
      debugPrint('Erro ao buscar dados para o PDF de saúde: $e');
    }

    final dateFormat = DateFormat('dd/MM/yyyy');
    final nowStr = dateFormat.format(DateTime.now());

    // Tema visual do PDF
    final primaryColor = PdfColor.fromHex('#FF6B00'); // AppColors.patasColor
    final darkColor = PdfColor.fromHex('#1E293B');
    final lightBg = PdfColor.fromHex('#F8FAFC');
    final borderColor = PdfColor.fromHex('#E2E8F0');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: pw.BoxDecoration(
                          color: primaryColor,
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Text(
                          'PATAS SAUDE',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 10),
                      pw.Text(
                        'Relatorio Consolidado de Saude',
                        style: pw.TextStyle(
                          color: darkColor,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  pw.Text(
                    'Emissao: $nowStr',
                    style: const pw.TextStyle(
                      color: PdfColors.grey700,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(color: borderColor, thickness: 1),
              pw.SizedBox(height: 12),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Divider(color: borderColor, thickness: 1),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Patas App - Plataforma de Gestao de Saude Pet',
                    style: const pw.TextStyle(
                        color: PdfColors.grey600, fontSize: 9),
                  ),
                  pw.Text(
                    'Pagina ${context.pageNumber} de ${context.pagesCount}',
                    style: const pw.TextStyle(
                        color: PdfColors.grey600, fontSize: 9),
                  ),
                ],
              ),
            ],
          );
        },
        build: (pw.Context context) => [
          // Header / Pet Overview Card
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: lightBg,
              borderRadius: pw.BorderRadius.circular(10),
              border: pw.Border.all(color: borderColor),
            ),
            child: pw.Row(
              children: [
                // Avatar: foto real ou fallback com inicial
                if (petPhotoBytes != null)
                  pw.Container(
                    width: 60,
                    height: 60,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      border: pw.Border.all(color: primaryColor, width: 2),
                    ),
                    child: pw.ClipOval(
                      child: pw.Image(
                        pw.MemoryImage(petPhotoBytes),
                        fit: pw.BoxFit.cover,
                        width: 60,
                        height: 60,
                      ),
                    ),
                  )
                else
                  pw.Container(
                    width: 60,
                    height: 60,
                    decoration: pw.BoxDecoration(
                      color: primaryColor,
                      shape: pw.BoxShape.circle,
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        activePet.name.isNotEmpty
                            ? activePet.name[0].toUpperCase()
                            : 'P',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        activePet.name,
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: darkColor,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Especie: ${activePet.species.toUpperCase()}  |  Raca: ${activePet.breed ?? "Nao informada"}  |  Sexo: ${activePet.gender?.toUpperCase() ?? "N/A"}',
                        style: const pw.TextStyle(
                          color: PdfColors.grey800,
                          fontSize: 11,
                        ),
                      ),
                      if (activePet.weight != null && activePet.weight! > 0)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 2),
                          child: pw.Text(
                            'Peso Cadastrado: ${activePet.weight!.toStringAsFixed(1)} kg',
                            style: pw.TextStyle(
                              color: primaryColor,
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Seção 1: Vacinas
          _pdfSectionTitle('Carteira de Vacinas', primaryColor, darkColor),
          pw.SizedBox(height: 8),

          if (vaccines.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: lightBg,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text(
                'Nenhuma vacina registrada ate o momento.',
                style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 10),
              ),
            )
          else
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: borderColor, width: 0.5),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 10,
              ),
              headerDecoration: pw.BoxDecoration(color: primaryColor),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellPadding:
                  const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              headers: ['Vacina', 'Data Aplicacao', 'Status'],
              data: vaccines.map((v) {
                final appDate = dateFormat.format(v.applicationDate);
                return [
                  v.name,
                  appDate,
                  'Aplicada',
                ];
              }).toList(),
            ),

          pw.SizedBox(height: 20),

          // Seção 2: Prontuários & Consultas SOAP
          _pdfSectionTitle('Historico Clinico & Prontuarios SOAP', primaryColor, darkColor),
          pw.SizedBox(height: 8),

          if (records.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: lightBg,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text(
                'Nenhum prontuario clinico registrado ate o momento.',
                style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 10),
              ),
            )
          else
            pw.Column(
              children: records.map((record) {
                final dateStr = dateFormat.format(record.createdAt);
                final weightStr = record.weight != null ? '${record.weight} kg' : '-';
                final vetStr = record.vetName ?? 'Veterinario Registrado';

                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 10),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: borderColor),
                    borderRadius: pw.BorderRadius.circular(6),
                    color: lightBg,
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Atendimento: $dateStr',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                              color: primaryColor,
                            ),
                          ),
                          pw.Text(
                            'Vet: $vetStr  |  Peso: $weightStr',
                            style: const pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.grey800,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      if (record.subjective != null && record.subjective!.isNotEmpty)
                        pw.Text('Subjetivo: ${record.subjective}',
                            style: const pw.TextStyle(fontSize: 9)),
                      if (record.objective != null && record.objective!.isNotEmpty)
                        pw.Text('Objetivo (Sinais/Exame): ${record.objective}',
                            style: const pw.TextStyle(fontSize: 9)),
                      if (record.assessment != null && record.assessment!.isNotEmpty)
                        pw.Text('Avaliacao / Diagnostico: ${record.assessment}',
                            style: pw.TextStyle(
                                fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      if (record.plan != null && record.plan!.isNotEmpty)
                        pw.Text('Plano Terapeutico: ${record.plan}',
                            style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                );
              }).toList(),
            ),

          pw.SizedBox(height: 20),

          // Seção 3: Receitas Emitidas
          _pdfSectionTitle('Prescricoes & Receitas Medicas', primaryColor, darkColor),
          pw.SizedBox(height: 8),

          if (prescriptions.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: lightBg,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text(
                'Nenhuma prescricao medica cadastrada.',
                style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 10),
              ),
            )
          else
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: borderColor, width: 0.5),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 10,
              ),
              headerDecoration: pw.BoxDecoration(color: darkColor),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellPadding:
                  const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              headers: ['Data', 'Veterinario', 'Medicacao & Posologia'],
              data: prescriptions.map((p) {
                final dateStr = dateFormat.format(p.createdAt);
                return [
                  dateStr,
                  p.vetName,
                  p.content,
                ];
              }).toList(),
            ),
        ],
      ),
    );

    // Layout para impressão / compartilhamento / download
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Relatorio_Saude_${activePet.name.replaceAll(' ', '_')}.pdf',
    );
  }

  /// Widget auxiliar para títulos de seção no PDF.
  /// A biblioteca pdf não suporta emojis, então usamos um prefixo colorido + texto.
  static pw.Widget _pdfSectionTitle(
    String title,
    PdfColor accentColor,
    PdfColor textColor,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          width: 4,
          height: 16,
          decoration: pw.BoxDecoration(
            color: accentColor,
            borderRadius: pw.BorderRadius.circular(2),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
