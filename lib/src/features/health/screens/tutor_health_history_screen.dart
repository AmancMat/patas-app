import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/src/common_widgets/patas_essencial_app_bar.dart';
import 'package:intl/intl.dart';

import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/features/pets/active_pet_provider.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';
import '../models/medical_record_model.dart';
import '../services/patas_saude_service.dart';
import '../services/pet_health_pdf_report_service.dart';

class TutorHealthHistoryScreen extends StatefulWidget {
  final int initialIndex;
  const TutorHealthHistoryScreen({super.key, this.initialIndex = 0});

  @override
  State<TutorHealthHistoryScreen> createState() => _TutorHealthHistoryScreenState();
}

class _TutorHealthHistoryScreenState extends State<TutorHealthHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _saudeService = PatasSaudeService();

  List<MedicalRecord> _records = [];
  List<Prescription> _prescriptions = [];
  bool _isLoading = true;

  String? _loadedPetId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final activePet = Provider.of<ActivePetProvider>(context).activePet;
    if (activePet?.id != _loadedPetId) {
      _loadedPetId = activePet?.id;
      _loadData();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final activePet = Provider.of<ActivePetProvider>(context, listen: false).activePet;
    
    List<MedicalRecord> recs = [];
    List<Prescription> prescs = [];

    if (activePet != null) {
      recs = await _saudeService.getPetMedicalRecords(activePet.id);
      prescs = await _saudeService.getPetPrescriptions(activePet.id);
    }

    if (mounted) {
      setState(() {
        _records = recs;
        _prescriptions = prescs;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;
    final isDesktop = context.isDesktop;
    final activePet = Provider.of<ActivePetProvider>(context).activePet;
    final scaffoldBg = isDark ? AppColors.bodygray : const Color(0xFFF5F7FA);

    final mainContent = Scaffold(
      backgroundColor: scaffoldBg,
      appBar: PatasEssencialAppBar(
        title: 'Prontuários & Receitas',
        subtitle: activePet != null ? 'Histórico clínico do pet ${activePet.name}' : 'Histórico clínico do pet',
        actions: [
          if (activePet != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.patasColor),
                tooltip: 'Exportar Relatório PDF',
                onPressed: () {
                  PetHealthPdfReportService().generateAndExportPdfReport(activePet);
                },
              ),
            ),
        ],
        bottomHeight: 50.0,
        bottomWidget: Center(
          child: SizedBox(
            width: 450,
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE8EDF2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.patasColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(
                    fontFamily: 'Fredoka', fontSize: 13, fontWeight: FontWeight.bold),
                unselectedLabelStyle:
                    const TextStyle(fontFamily: 'Fredoka', fontSize: 13),
                labelColor: Colors.white,
                unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
                tabs: const [
                  Tab(text: 'Prontuários'),
                  Tab(text: 'Receitas Digitais'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.patasColor))
          : isDesktop
              ? Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildRecordsTab(isDark),
                        _buildPrescriptionsTab(isDark),
                      ],
                    ),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRecordsTab(isDark),
                    _buildPrescriptionsTab(isDark),
                  ],
                ),
    );

    return mainContent;
  }

  Widget _buildRecordsTab(bool isDark) {
    if (_records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.folder_shared_rounded, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('Nenhum prontuário registrado para este pet.', style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _records.length,
      itemBuilder: (context, index) {
        final rec = _records[index];
        final vetName = rec.vet?.fullName ?? 'Veterinário';
        final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(rec.createdAt);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ExpansionTile(
            title: Text(
              'Consulta • $dateStr',
              style: TextStyle(fontFamily: 'Fredoka', fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.darkBG),
            ),
            subtitle: Text('Atendido por $vetName', style: const TextStyle(fontSize: 12, color: AppColors.patasColor)),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (rec.anamnesisSubjective != null && rec.anamnesisSubjective!.isNotEmpty) ...[
                      const Text('S: Anamnese & Sintomas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(rec.anamnesisSubjective!, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87)),
                      const SizedBox(height: 12),
                    ],

                    if (rec.vitalSignsObjective.isNotEmpty) ...[
                      const Text('O: Parâmetros Vitais', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(
                        'Peso: ${rec.vitalSignsObjective['weight_kg'] ?? '--'} kg  |  Temp: ${rec.vitalSignsObjective['temp_c'] ?? '--'} °C  |  FC: ${rec.vitalSignsObjective['bpm'] ?? '--'} bpm',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.darkBG),
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (rec.diagnosisAssessment != null && rec.diagnosisAssessment!.isNotEmpty) ...[
                      const Text('A: Diagnóstico & Avaliação', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(rec.diagnosisAssessment!, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87)),
                      const SizedBox(height: 12),
                    ],

                    if (rec.treatmentPlan != null && rec.treatmentPlan!.isNotEmpty) ...[
                      const Text('P: Plano Terapêutico', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(rec.treatmentPlan!, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87)),
                    ],

                    if (rec.examRequests != null && rec.examRequests!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('🔬 Exames Solicitados', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 6),
                      ...rec.examRequests!.map((ex) {
                        final isCompleted = ex.status.toLowerCase() == 'completed';
                        final statusLabel = isCompleted ? 'Concluído' : 'Pendente';
                        final statusColor = isCompleted ? Colors.green : Colors.orange;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.biotech_rounded, size: 16, color: AppColors.patasColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  ex.examType,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPrescriptionsTab(bool isDark) {
    if (_prescriptions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.receipt_long_rounded, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('Nenhuma receita digital emitida ainda.', style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _prescriptions.length,
      itemBuilder: (context, index) {
        final presc = _prescriptions[index];
        final vetName = presc.vet?.fullName ?? 'Veterinário';
        final dateStr = DateFormat('dd/MM/yyyy').format(presc.createdAt);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.receipt_rounded, color: AppColors.patasColor, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Receita Digital • $dateStr',
                          style: TextStyle(fontFamily: 'Fredoka', fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.darkBG),
                        ),
                      ],
                    ),
                    if (presc.qrCodeHash != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.patasColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          presc.qrCodeHash!,
                          style: const TextStyle(fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.bold, color: AppColors.patasColor),
                        ),
                      ),
                  ],
                ),
                Text('Prescrito por $vetName', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const Divider(height: 20),

                ...presc.medications.map((m) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.medication_rounded, size: 16, color: AppColors.patasColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${m.name} (${m.dosageMg} mg)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : AppColors.darkBG),
                              ),
                              Text(
                                '${m.frequency} por ${m.durationDays} dias. ${m.instructions}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                if (presc.generalInstructions != null && presc.generalInstructions!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Instruções Gerais: ${presc.generalInstructions}',
                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
