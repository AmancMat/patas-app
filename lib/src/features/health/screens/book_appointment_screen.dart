import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/src/common_widgets/patas_essencial_app_bar.dart';
import 'package:intl/intl.dart';

import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/features/pets/active_pet_provider.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';
import '../models/vet_profile_model.dart';
import '../services/patas_saude_service.dart';

class BookAppointmentScreen extends StatefulWidget {
  final VetProfile vet;
  final String? rescheduleAppointmentId;

  const BookAppointmentScreen({
    super.key,
    required this.vet,
    this.rescheduleAppointmentId,
  });

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _saudeService = PatasSaudeService();
  final TextEditingController _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTime = '08:00';
  String _selectedModality = 'clinic'; // 'clinic' ou 'home'
  bool _isSaving = false;

  List<String> _dynamicTimes = [];
  Map<String, int> _occupiedSlots = {};
  bool _isLoadingSlots = false;

  @override
  void initState() {
    super.initState();
    if (widget.vet.acceptsClinicVisit) {
      _selectedModality = 'clinic';
    } else if (widget.vet.acceptsHomeVisit) {
      _selectedModality = 'home';
    }
    _generateDynamicTimes();
    _loadOccupiedSlots();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _generateDynamicTimes() {
    final duration = widget.vet.consultationDurationMinutes;
    final List<String> times = [];
    final startHour = 8;
    final endHour = 18;

    var current = DateTime(2020, 1, 1, startHour, 0);
    final limit = DateTime(2020, 1, 1, endHour, 0);

    while (current.isBefore(limit)) {
      final hourStr = current.hour.toString().padLeft(2, '0');
      final minuteStr = current.minute.toString().padLeft(2, '0');
      final timeStr = '$hourStr:$minuteStr';

      if (current.hour != 12) {
        times.add(timeStr);
      }
      current = current.add(Duration(minutes: duration));
    }

    setState(() {
      _dynamicTimes = times;
      if (_dynamicTimes.isNotEmpty) {
        _selectedTime = _dynamicTimes.first;
      }
    });
  }

  Future<void> _loadOccupiedSlots() async {
    setState(() => _isLoadingSlots = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final counts = await _saudeService.getOccupiedSlotsCount(widget.vet.id, dateStr);
    if (mounted) {
      setState(() {
        _occupiedSlots = counts;
        _isLoadingSlots = false;

        // Se o horário selecionado estiver ocupado, seleciona o primeiro livre
        if (_isTimeSlotFull(_selectedTime)) {
          final firstFree = _dynamicTimes.firstWhere(
            (t) => !_isTimeSlotFull(t),
            orElse: () => '',
          );
          if (firstFree.isNotEmpty) {
            _selectedTime = firstFree;
          }
        }
      });
    }
  }

  bool _isTimeSlotFull(String time) {
    final count = _occupiedSlots[time] ?? 0;
    return count >= widget.vet.maxAppointmentsPerSlot;
  }

  Future<void> _submitBooking() async {
    final activePet = Provider.of<ActivePetProvider>(context, listen: false).activePet;
    if (activePet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione ou cadastre um pet ativo primeiro.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedTime.isEmpty || _isTimeSlotFull(_selectedTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione um horário disponível.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    final success = widget.rescheduleAppointmentId != null
        ? await _saudeService.rescheduleAppointment(
            appointmentId: widget.rescheduleAppointmentId!,
            newDate: dateStr,
            newTime: _selectedTime,
          )
        : await _saudeService.bookAppointment(
            petId: activePet.id,
            vetId: widget.vet.id,
            appointmentDate: dateStr,
            appointmentTime: _selectedTime,
            modality: _selectedModality,
            notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
            totalPrice: widget.vet.consultationPrice,
          );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.rescheduleAppointmentId != null
                ? 'Consulta reagendada com sucesso!'
                : 'Consulta agendada com sucesso! O veterinário foi notificado.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao agendar consulta. Tente novamente.'),
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
    final activePet = Provider.of<ActivePetProvider>(context).activePet;

    // Componentes de Conteúdo
    final vetCard = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.patasColor.withValues(alpha: 0.2),
            backgroundImage: (widget.vet.photoUrl != null && widget.vet.photoUrl!.isNotEmpty)
                ? NetworkImage(widget.vet.photoUrl!)
                : null,
            child: (widget.vet.photoUrl == null || widget.vet.photoUrl!.isEmpty)
                ? const Icon(Icons.medical_services_rounded, color: AppColors.patasColor)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.vet.fullName,
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.darkBG,
                  ),
                ),
                Text(
                  'CRMV ${widget.vet.crmvUf} ${widget.vet.crmvNumber}',
                  style: const TextStyle(fontSize: 12, color: AppColors.patasColor, fontWeight: FontWeight.bold),
                ),
                if (widget.vet.clinicName != null && widget.vet.clinicName!.isNotEmpty)
                  Text(
                    widget.vet.clinicName!,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    final petCard = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paciente (Pet) *',
          style: TextStyle(fontFamily: 'Fredoka', fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.darkBG),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.patasColor.withValues(alpha: 0.2),
                backgroundImage: (activePet?.photoUrl != null && activePet!.photoUrl!.isNotEmpty)
                    ? NetworkImage(activePet.photoUrl!)
                    : null,
                child: (activePet?.photoUrl == null || activePet!.photoUrl!.isEmpty)
                    ? const Icon(Icons.pets_rounded, size: 20, color: AppColors.patasColor)
                    : null,
              ),
              const SizedBox(width: 12),
              Text(
                activePet != null ? activePet.name : 'Nenhum pet selecionado',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.darkBG),
              ),
            ],
          ),
        ),
      ],
    );

    final modalitySection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Modalidade *',
          style: TextStyle(fontFamily: 'Fredoka', fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.darkBG),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (widget.vet.acceptsClinicVisit)
              Expanded(
                child: ChoiceChip(
                  label: const Text('Na Clínica', style: TextStyle(fontFamily: 'Fredoka', fontSize: 13, fontWeight: FontWeight.bold)),
                  selected: _selectedModality == 'clinic',
                  selectedColor: AppColors.patasColor,
                  labelStyle: TextStyle(color: _selectedModality == 'clinic' ? Colors.white : (isDark ? Colors.white70 : AppColors.darkBG)),
                  backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  onSelected: (val) {
                    if (val) setState(() => _selectedModality = 'clinic');
                  },
                ),
              ),
            if (widget.vet.acceptsClinicVisit && widget.vet.acceptsHomeVisit)
              const SizedBox(width: 12),
            if (widget.vet.acceptsHomeVisit)
              Expanded(
                child: ChoiceChip(
                  label: const Text('A Domicílio', style: TextStyle(fontFamily: 'Fredoka', fontSize: 13, fontWeight: FontWeight.bold)),
                  selected: _selectedModality == 'home',
                  selectedColor: AppColors.patasColor,
                  labelStyle: TextStyle(color: _selectedModality == 'home' ? Colors.white : (isDark ? Colors.white70 : AppColors.darkBG)),
                  backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  onSelected: (val) {
                    if (val) setState(() => _selectedModality = 'home');
                  },
                ),
              ),
          ],
        ),
      ],
    );

    final dateSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Data da Consulta *',
              style: TextStyle(fontFamily: 'Fredoka', fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.darkBG),
            ),
            TextButton.icon(
              icon: const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.patasColor),
              label: Text(
                DateFormat('dd/MM/yyyy').format(_selectedDate),
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.patasColor),
              ),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 60)),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                  _loadOccupiedSlots();
                }
              },
            ),
          ],
        ),
      ],
    );

    final timeSlotsSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Horários Disponíveis *',
          style: TextStyle(fontFamily: 'Fredoka', fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.darkBG),
        ),
        const SizedBox(height: 8),
        _isLoadingSlots
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(color: AppColors.patasColor),
                ),
              )
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _dynamicTimes.map((t) {
                  final isSelected = _selectedTime == t;
                  final isFull = _isTimeSlotFull(t);

                  return ChoiceChip(
                    label: Text(
                      isFull ? '$t (Esgotado)' : t,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        decoration: isFull ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.patasColor,
                    disabledColor: isDark ? const Color(0xFF0F172A) : Colors.grey[300],
                    labelStyle: TextStyle(
                      color: isFull
                          ? Colors.grey
                          : (isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.darkBG)),
                    ),
                    backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    onSelected: isFull
                        ? null
                        : (val) {
                            if (val) setState(() => _selectedTime = t);
                          },
                  );
                }).toList(),
              ),
      ],
    );

    final notesSection = TextFormField(
      controller: _notesController,
      maxLines: 3,
      style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG),
      decoration: InputDecoration(
        labelText: 'Motivo da Consulta / Observações (Opcional)',
        hintText: 'Ex: Vacinação de rotina, tosse persistente, Check-up anual, etc.',
        filled: true,
        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );

    final submitButton = SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _submitBooking,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.patasColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isSaving
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                widget.rescheduleAppointmentId != null
                    ? 'Confirmar Reagendamento'
                    : 'Confirmar Agendamento (R\$ ${widget.vet.consultationPrice.toStringAsFixed(2)})',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );

    Widget content;
    if (isDesktop) {
      content = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Card(
              elevation: 0,
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Coluna 1: Vet, Pet e Modalidade
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          vetCard,
                          const SizedBox(height: 24),
                          petCard,
                          const SizedBox(height: 24),
                          modalitySection,
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),
                    // Coluna 2: Data, Horários, Obs e Botão
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          dateSection,
                          const SizedBox(height: 16),
                          timeSlotsSection,
                          const SizedBox(height: 24),
                          notesSection,
                          const SizedBox(height: 32),
                          submitButton,
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          vetCard,
          const SizedBox(height: 24),
          petCard,
          const SizedBox(height: 24),
          modalitySection,
          const SizedBox(height: 24),
          dateSection,
          const SizedBox(height: 12),
          timeSlotsSection,
          const SizedBox(height: 24),
          notesSection,
          const SizedBox(height: 32),
          submitButton,
        ],
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.bodygray : const Color(0xFFF5F7FA),
      appBar: PatasEssencialAppBar(
        title: widget.rescheduleAppointmentId != null ? 'Reagendar Consulta' : 'Agendar Consulta',
        subtitle: 'Com Dr(a). ${widget.vet.fullName}',
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 24 : 20,
          vertical: 10,
        ).copyWith(bottom: 100),
        child: content,
      ),
    );
  }
}
