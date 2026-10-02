import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/features/health/consultas/clinic_search_page.dart';
import 'package:patas_web_app/src/features/health/models/consultation_model.dart';
import 'package:patas_web_app/src/features/health/services/health_service.dart';
import 'package:patas_web_app/src/features/pets/active_pet_provider.dart';
import 'package:patas_web_app/src/common_widgets/patas_essencial_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../app.dart';

class ConsultationFormPage extends StatefulWidget {
  final String? clinicId;
  final String? clinicName;

  const ConsultationFormPage({
    super.key,
    this.clinicId,
    this.clinicName,
  });

  @override
  State<ConsultationFormPage> createState() => _ConsultationFormPageState();
}

class _ConsultationFormPageState extends State<ConsultationFormPage> {
  final _formKey = GlobalKey<FormState>();
  final HealthService _healthService = HealthService();

  // Controllers - Apenas o que o tutor preenche
  final _symptomsController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = false;

  String? _currentClinicId;
  String? _currentClinicName;

  @override
  void initState() {
    super.initState();
    _currentClinicId = widget.clinicId;
    _currentClinicName = widget.clinicName;
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final activePet =
        Provider.of<ActivePetProvider>(context, listen: false).activePet;
    final user = Supabase.instance.client.auth.currentUser;

    if (activePet == null || user == null) return;

    if (_currentClinicId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Por favor, selecione uma clínica ou profissional antes de agendar.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Combina data e hora
      final finalDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final consultation = PetConsultation(
        id: '',
        petId: activePet.id,
        userId: user.id,
        date: finalDateTime,
        symptoms: _symptomsController.text,
        status: 'aguardando',
        clinicId: _currentClinicId,
        clinicName: _currentClinicName,
        // Campos técnicos ficam nulos no agendamento pelo tutor
        weight: null,
        temperature: null,
        heartRate: null,
        respiratoryRate: null,
        tpc: null,
        diagnosis: null,
        treatment: null,
      );

      await _healthService.addConsultation(consultation);
      if (!context.mounted) return;
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Agendamento solicitado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao solicitar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);

    return Scaffold(
      backgroundColor: thmode.darkMode ? AppColors.darkBG : Colors.white,
      appBar: const PatasEssencialAppBar(
        title: 'Solicitar Consulta',
        subtitle: 'Agende uma consulta veterinária',
        leadingIcon: Icon(
          Icons.medical_services_rounded,
          color: AppColors.patasColor,
          size: 22,
        ),
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_currentClinicName != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.patasColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color:
                                  AppColors.patasColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on,
                                color: AppColors.patasColor, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Clínica selecionada:',
                                    style: TextStyle(
                                        fontSize: 10, color: Colors.grey),
                                  ),
                                  Text(
                                    _currentClinicName!,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: thmode.darkMode
                                          ? Colors.white
                                          : AppColors.darkBG,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const ClinicSearchPage()),
                                );
                                // Se o fluxo de busca for alterado para retornar dados
                                if (result != null &&
                                    result is Map<String, String>) {
                                  setState(() {
                                    _currentClinicId = result['id'];
                                    _currentClinicName = result['name'];
                                  });
                                }
                              },
                              child: const Text('Alterar',
                                  style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ] else ...[
                      OutlinedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const ClinicSearchPage()),
                          );
                          if (result != null && result is Map<String, String>) {
                            setState(() {
                              _currentClinicId = result['id'];
                              _currentClinicName = result['name'];
                            });
                          }
                        },
                        icon: const Icon(Icons.add_location_alt),
                        label: const Text('SELECIONAR CLÍNICA / PROFISSIONAL'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.patasColor,
                          side: const BorderSide(color: AppColors.patasColor),
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    Text(
                      'O que seu pet está sentindo?',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 18,
                        color: thmode.darkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      _symptomsController,
                      'Descreva os sintomas ou motivo da consulta...',
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, descreva o que o pet está sentindo';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Quando deseja a consulta?',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 18,
                        color: thmode.darkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      color: thmode.darkMode
                          ? const Color(0xFF1E1E1E)
                          : Colors.grey[100],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.calendar_today,
                                color: AppColors.patasColor),
                            title: Text(
                              'Data',
                              style: TextStyle(
                                  color: thmode.darkMode
                                      ? Colors.white
                                      : AppColors.darkBG),
                            ),
                            subtitle: Text(
                              DateFormat('dd/MM/yyyy').format(_selectedDate),
                              style: TextStyle(
                                  color: thmode.darkMode
                                      ? Colors.white70
                                      : Colors.black54),
                            ),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 90)),
                                builder: (context, child) {
                                  return Theme(
                                    data: thmode.darkMode
                                        ? ThemeData.dark().copyWith(
                                            colorScheme: const ColorScheme.dark(
                                              primary: AppColors.patasColor,
                                              onPrimary: Colors.white,
                                              surface: Color(0xFF1E1E1E),
                                              onSurface: Colors.white,
                                            ),
                                          )
                                        : ThemeData.light().copyWith(
                                            colorScheme:
                                                const ColorScheme.light(
                                              primary: AppColors.patasColor,
                                              onPrimary: Colors.white,
                                              surface: Colors.white,
                                              onSurface: AppColors.darkBG,
                                            ),
                                          ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setState(() => _selectedDate = picked);
                              }
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.access_time,
                                color: AppColors.patasColor),
                            title: Text(
                              'Horário Estimado',
                              style: TextStyle(
                                  color: thmode.darkMode
                                      ? Colors.white
                                      : AppColors.darkBG),
                            ),
                            subtitle: Text(
                              _selectedTime.format(context),
                              style: TextStyle(
                                  color: thmode.darkMode
                                      ? Colors.white70
                                      : Colors.black54),
                            ),
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: _selectedTime,
                                builder: (context, child) {
                                  return Theme(
                                    data: thmode.darkMode
                                        ? ThemeData.dark().copyWith(
                                            colorScheme: const ColorScheme.dark(
                                              primary: AppColors.patasColor,
                                              onPrimary: Colors.white,
                                              surface: Color(0xFF1E1E1E),
                                              onSurface: Colors.white,
                                            ),
                                          )
                                        : ThemeData.light().copyWith(
                                            colorScheme:
                                                const ColorScheme.light(
                                              primary: AppColors.patasColor,
                                              onPrimary: Colors.white,
                                              surface: Colors.white,
                                              onSurface: AppColors.darkBG,
                                            ),
                                          ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setState(() => _selectedTime = picked);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.patasColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                        ),
                        child: const Text(
                          'SOLICITAR AGENDAMENTO',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final thmode = Provider.of<DarkMode>(context, listen: false);
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style:
          TextStyle(color: thmode.darkMode ? Colors.white : AppColors.darkBG),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        filled: true,
        fillColor: thmode.darkMode ? const Color(0xFF1E1E1E) : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.patasColor),
        ),
      ),
    );
  }
}
