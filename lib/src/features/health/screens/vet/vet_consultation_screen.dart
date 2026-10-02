import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/src/common_widgets/patas_essencial_app_bar.dart';

import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';
import '../../models/appointment_model.dart';
import '../../models/medical_record_model.dart';
import '../../services/patas_saude_service.dart';

class VetConsultationScreen extends StatefulWidget {
  final HealthAppointment? appointment;
  final String petId;
  final String vetId;
  final String petName;

  const VetConsultationScreen({
    super.key,
    this.appointment,
    required this.petId,
    required this.vetId,
    required this.petName,
  });

  @override
  State<VetConsultationScreen> createState() => _VetConsultationScreenState();
}

class _VetConsultationScreenState extends State<VetConsultationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _saudeService = PatasSaudeService();

  // SOAP Controllers
  final _subjectiveController = TextEditingController();
  final _weightController = TextEditingController(text: '5.0');
  final _tempController = TextEditingController(text: '38.5');
  final _bpmController = TextEditingController(text: '110');
  final _assessmentController = TextEditingController();
  final _planController = TextEditingController();

  // Calculadora de Doses & Prescrição
  final _medNameController = TextEditingController();
  final _medPosologyMgKgController = TextEditingController(text: '10.0');
  final _medCalculatedDosageController = TextEditingController();
  final _medFrequencyController = TextEditingController(
    text: 'De 12 em 12 horas',
  );
  final _medDurationController = TextEditingController(text: '7');
  final _medInstructionsController = TextEditingController(
    text: 'Administrar via oral após as refeições.',
  );
  final _generalPrescriptionInstructionsController = TextEditingController();

  final List<MedicationItem> _prescribedMedications = [];

  // Exames Solicitados
  final _examNameController = TextEditingController();
  final List<String> _requestedExams = [];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _calculateDose();
  }

  @override
  void dispose() {
    _subjectiveController.dispose();
    _weightController.dispose();
    _tempController.dispose();
    _bpmController.dispose();
    _assessmentController.dispose();
    _planController.dispose();
    _medNameController.dispose();
    _medPosologyMgKgController.dispose();
    _medCalculatedDosageController.dispose();
    _medFrequencyController.dispose();
    _medDurationController.dispose();
    _medInstructionsController.dispose();
    _generalPrescriptionInstructionsController.dispose();
    _examNameController.dispose();
    super.dispose();
  }

  void _calculateDose() {
    final weight =
        double.tryParse(_weightController.text.replaceAll(',', '.')) ?? 0.0;
    final posology =
        double.tryParse(_medPosologyMgKgController.text.replaceAll(',', '.')) ??
        0.0;
    final doseMg = weight * posology;
    setState(() {
      _medCalculatedDosageController.text = doseMg.toStringAsFixed(1);
    });
  }

  void _addMedicationToPrescription() {
    if (_medNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe o nome do medicamento.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final doseMg =
        double.tryParse(
          _medCalculatedDosageController.text.replaceAll(',', '.'),
        ) ??
        0.0;
    final duration = int.tryParse(_medDurationController.text) ?? 1;

    setState(() {
      _prescribedMedications.add(
        MedicationItem(
          name: _medNameController.text.trim(),
          dosageMg: doseMg,
          frequency: _medFrequencyController.text.trim(),
          durationDays: duration,
          instructions: _medInstructionsController.text.trim(),
        ),
      );
      _medNameController.clear();
    });
  }

  void _addExamRequest() {
    if (_examNameController.text.trim().isEmpty) return;
    setState(() {
      _requestedExams.add(_examNameController.text.trim());
      _examNameController.clear();
    });
  }

  Future<void> _submitConsultation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final weight =
        double.tryParse(_weightController.text.replaceAll(',', '.')) ?? 0.0;
    final temp =
        double.tryParse(_tempController.text.replaceAll(',', '.')) ?? 0.0;
    final bpm = int.tryParse(_bpmController.text) ?? 0;

    final vitalSigns = {'weight_kg': weight, 'temp_c': temp, 'bpm': bpm};

    final success = await _saudeService.createMedicalRecord(
      appointmentId: widget.appointment?.id,
      petId: widget.petId,
      vetId: widget.vetId,
      anamnesisSubjective: _subjectiveController.text.trim().isEmpty
          ? null
          : _subjectiveController.text.trim(),
      vitalSignsObjective: vitalSigns,
      diagnosisAssessment: _assessmentController.text.trim().isEmpty
          ? null
          : _assessmentController.text.trim(),
      treatmentPlan: _planController.text.trim().isEmpty
          ? null
          : _planController.text.trim(),
      medications: _prescribedMedications,
      generalInstructions:
          _generalPrescriptionInstructionsController.text.trim().isEmpty
          ? null
          : _generalPrescriptionInstructionsController.text.trim(),
      requestedExams: _requestedExams,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Atendimento e Prontuário salvos com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao salvar atendimento médico.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;
    final isDesktop = context.isDesktop;
    final scaffoldBg = isDark ? AppColors.bodygray : const Color(0xFFF5F7FA);

    Widget formContent = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner do Paciente
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.patasColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.patasColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.pets_rounded,
                  color: AppColors.patasColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Paciente: ${widget.petName}',
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.darkBG,
                        ),
                      ),
                      const Text(
                        'Prontuário Eletrônico Veterinário (SOAP)',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.patasColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // S: Subjetivo
          _buildSectionHeader(
            'S: Anamnese e Queixas do Tutor',
            Icons.psychology_rounded,
            isDark,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _subjectiveController,
            maxLines: 3,
            style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG),
            decoration: InputDecoration(
              hintText:
                  'Relato do tutor: sintomas, início das queixas, apetite, fezes, etc.',
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // O: Objetivo (Vitais)
          _buildSectionHeader(
            'O: Parâmetros Vitais (Exame Físico)',
            Icons.monitor_heart_rounded,
            isDark,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => _calculateDose(),
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.darkBG,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Peso (kg) *',
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _tempController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.darkBG,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Temp (°C)',
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _bpmController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.darkBG,
                  ),
                  decoration: InputDecoration(
                    labelText: 'FC (bpm)',
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // A: Avaliação
          _buildSectionHeader(
            'A: Avaliação & Diagnóstico',
            Icons.healing_rounded,
            isDark,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _assessmentController,
            maxLines: 2,
            style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG),
            decoration: InputDecoration(
              hintText:
                  'Suspeita clínica, diagnóstico presuntivo ou definitivo...',
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // P: Plano & Calculadora de Doses
          _buildSectionHeader(
            'P: Prescrição Digital & Calculadora de Dose (mg/kg)',
            Icons.calculate_rounded,
            isDark,
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.patasColor.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '➕ Adicionar Medicamento',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.patasColor,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _medNameController,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.darkBG,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Nome do Medicamento',
                    hintText: 'Ex: Amoxicilina + Clavulanato',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _medPosologyMgKgController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => _calculateDose(),
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.darkBG,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Posologia (mg/kg)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _medCalculatedDosageController,
                        readOnly: true,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.patasColor,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Dose Calculada (mg)',
                          filled: true,
                          fillColor: AppColors.patasColor.withValues(
                            alpha: 0.1,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _medFrequencyController,
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.darkBG,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Frequência',
                          hintText: 'De 12 em 12h',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _medDurationController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.darkBG,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Duração (dias)',
                          hintText: '7',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(
                      Icons.add_circle_outline_rounded,
                      color: AppColors.patasColor,
                    ),
                    label: const Text(
                      'Incluir na Receita',
                      style: TextStyle(
                        color: AppColors.patasColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: _addMedicationToPrescription,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppColors.patasColor,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lista de Medicamentos Prescritos
          if (_prescribedMedications.isNotEmpty) ...[
            const SizedBox(height: 12),
            ..._prescribedMedications.asMap().entries.map((entry) {
              final idx = entry.key;
              final m = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                child: ListTile(
                  leading: const Icon(
                    Icons.medication_rounded,
                    color: AppColors.patasColor,
                  ),
                  title: Text(
                    '${m.name} (${m.dosageMg} mg)',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    '${m.frequency} por ${m.durationDays} dias',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _prescribedMedications.removeAt(idx)),
                  ),
                ),
              );
            }),
          ],
          const SizedBox(height: 24),

          // Pedido de Exames
          _buildSectionHeader(
            'Solicitação de Exames Complementares',
            Icons.biotech_rounded,
            isDark,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _examNameController,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.darkBG,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Nome do Exame',
                    hintText: 'Ex: Hemograma, Ultrassom Abdominal',
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.patasColor,
                ),
                onPressed: _addExamRequest,
              ),
            ],
          ),
          if (_requestedExams.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _requestedExams.map((ex) {
                return Chip(
                  label: Text(ex),
                  onDeleted: () => setState(() => _requestedExams.remove(ex)),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 32),

          // Botão Concluir Atendimento
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
              label: const Text(
                'Finalizar Atendimento & Salvar Prontuário',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: _isSaving ? null : _submitConsultation,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.patasColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (isDesktop) {
      formContent = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Card(
              elevation: 0,
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: formContent,
              ),
            ),
          ),
        ),
      );
    }

    final mainScaffold = Scaffold(
      backgroundColor: scaffoldBg,
      appBar: PatasEssencialAppBar(
        title: 'Atendimento Clínico SOAP',
        subtitle: 'Paciente: ${widget.petName}',
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 24 : 20,
          vertical: 10,
        ).copyWith(bottom: 100),
        child: formContent,
      ),
    );

    return mainScaffold;
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, color: AppColors.patasColor, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.darkBG,
          ),
        ),
      ],
    );
  }
}
