import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../app.dart';
import '../../../constants/app_colors.dart';
import '../models/shelter_event_model.dart';
import '../models/shelter_animal_model.dart';
import '../services/shelter_service.dart';

class CreateShelterEventSheet extends StatefulWidget {
  final String ongId;
  final ShelterEvent? eventToEdit;
  final VoidCallback onSaved;

  const CreateShelterEventSheet({
    super.key,
    required this.ongId,
    this.eventToEdit,
    required this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    required String ongId,
    ShelterEvent? eventToEdit,
    required VoidCallback onSaved,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateShelterEventSheet(
        ongId: ongId,
        eventToEdit: eventToEdit,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<CreateShelterEventSheet> createState() => _CreateShelterEventSheetState();
}

class _CreateShelterEventSheetState extends State<CreateShelterEventSheet> {
  final _formKey = GlobalKey<FormState>();
  final _shelterService = ShelterService();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationNameController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _whatsappController;

  late ShelterEventType _eventType;
  late DateTime _startDate;
  TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 0);
  DateTime? _endDate;
  TimeOfDay? _endTime = const TimeOfDay(hour: 17, minute: 0);
  bool _isPublishedFeed = true;

  XFile? _selectedBanner;
  String? _existingBannerUrl;

  List<ShelterAnimal> _ongAnimals = [];
  List<String> _selectedAnimalIds = [];
  bool _isLoadingAnimals = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.eventToEdit;

    _titleController = TextEditingController(text: e?.title ?? '');
    _descriptionController = TextEditingController(text: e?.description ?? '');
    _locationNameController = TextEditingController(text: e?.locationName ?? '');
    _addressController = TextEditingController(text: e?.address ?? '');
    _cityController = TextEditingController(text: e?.city ?? '');
    _whatsappController = TextEditingController(text: e?.contactWhatsapp ?? '');

    _eventType = e?.eventType ?? ShelterEventType.adocao;
    _startDate = e?.startDate ?? DateTime.now().add(const Duration(days: 3));
    if (e != null) {
      _startTime = TimeOfDay(hour: e.startDate.hour, minute: e.startDate.minute);
      if (e.endDate != null) {
        _endDate = e.endDate;
        _endTime = TimeOfDay(hour: e.endDate!.hour, minute: e.endDate!.minute);
      }
    }
    _existingBannerUrl = e?.bannerUrl;
    _isPublishedFeed = e?.isPublishedFeed ?? true;
    _selectedAnimalIds = List.from(e?.participatingAnimalsIds ?? []);

    _loadAnimals();
  }

  Future<void> _loadAnimals() async {
    setState(() => _isLoadingAnimals = true);
    try {
      final animals = await _shelterService.getShelterAnimals(widget.ongId);
      if (mounted) {
        setState(() {
          _ongAnimals = animals;
          _isLoadingAnimals = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingAnimals = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  Future<void> _pickBanner() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _selectedBanner = picked);
    }
  }

  Future<void> _pickStartDate(bool isDark) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: isDark
              ? const ColorScheme.dark(
                  primary: Colors.blueAccent,
                  surface: Color(0xFF1E293B),
                )
              : const ColorScheme.light(primary: Colors.blueAccent),
        ),
        child: child!,
      ),
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: _startTime,
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Colors.blueAccent,
                    surface: Color(0xFF1E293B),
                  )
                : const ColorScheme.light(primary: Colors.blueAccent),
          ),
          child: child!,
        ),
      );

      setState(() {
        _startDate = pickedDate;
        if (pickedTime != null) _startTime = pickedTime;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      String? bannerUrl = _existingBannerUrl;
      if (_selectedBanner != null) {
        bannerUrl = await _shelterService.uploadEventBanner(
          _selectedBanner!,
          widget.ongId,
        );
      }

      final startDateTime = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      DateTime? endDateTime;
      if (_endDate != null && _endTime != null) {
        endDateTime = DateTime(
          _endDate!.year,
          _endDate!.month,
          _endDate!.day,
          _endTime!.hour,
          _endTime!.minute,
        );
      }

      final event = ShelterEvent(
        id: widget.eventToEdit?.id ?? '',
        ongId: widget.ongId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        eventType: _eventType,
        bannerUrl: bannerUrl,
        locationName: _locationNameController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        startDate: startDateTime,
        endDate: endDateTime,
        contactWhatsapp: _whatsappController.text.trim().isEmpty
            ? null
            : _whatsappController.text.trim(),
        attendeesCount: widget.eventToEdit?.attendeesCount ?? 0,
        isPublishedFeed: _isPublishedFeed,
        status: widget.eventToEdit?.status ?? ShelterEventStatus.agendado,
        participatingAnimalsIds: _selectedAnimalIds,
        createdAt: widget.eventToEdit?.createdAt ?? DateTime.now(),
      );

      if (widget.eventToEdit == null) {
        await _shelterService.createEvent(event);
      } else {
        await _shelterService.updateEvent(event);
      }

      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao salvar evento: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required bool isDark,
    String? hint,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        fontSize: 13,
        color: isDark ? Colors.white70 : Colors.black87,
      ),
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: 12,
        color: isDark ? Colors.white38 : Colors.black38,
      ),
      prefixIcon: prefixIcon != null
          ? Icon(
              prefixIcon,
              size: 20,
              color: isDark ? Colors.white60 : Colors.black54,
            )
          : null,
      filled: true,
      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? Colors.white12 : Colors.grey.shade300,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? Colors.white12 : Colors.grey.shade300,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;
    final isEditing = widget.eventToEdit != null;
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade300,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          brightness: isDark ? Brightness.dark : Brightness.light,
          textTheme: Theme.of(context).textTheme.apply(
                bodyColor: isDark ? Colors.white : AppColors.darkBG,
                displayColor: isDark ? Colors.white : AppColors.darkBG,
              ),
          unselectedWidgetColor: isDark ? Colors.white60 : Colors.black54,
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header com título e fechar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.deepPurpleAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.campaign_rounded,
                      color: Colors.deepPurpleAccent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Editar Evento' : 'Novo Evento / Feira',
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.darkBG,
                          ),
                        ),
                        Text(
                          'Divulgue feiras e bazares no feed do Patas',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Formulário com Scroll
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Banner Promocional
                      Text(
                        'BANNER DO EVENTO (OPCIONAL)',
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: isDark
                              ? const Color(0xFF93C5FD)
                              : const Color(0xFF1D4ED8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickBanner,
                        child: Container(
                          height: 140,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF0F172A)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? Colors.white12 : Colors.grey.shade300,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: _selectedBanner != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.network(
                                    _selectedBanner!.path,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Icon(Icons.check_circle_rounded,
                                          color: Colors.green),
                                    ),
                                  ),
                                )
                              : (_existingBannerUrl != null &&
                                      _existingBannerUrl!.isNotEmpty)
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: Image.network(
                                        _existingBannerUrl!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate_rounded,
                                          size: 36,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.black45,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Toque para adicionar um banner (16:9)',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark
                                                ? Colors.white60
                                                : Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Tipo de Evento
                      Text(
                        'TIPO DE EVENTO *',
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: isDark
                              ? const Color(0xFF93C5FD)
                              : const Color(0xFF1D4ED8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<ShelterEventType>(
                        initialValue: _eventType,
                        dropdownColor: isDark
                            ? const Color(0xFF1E293B)
                            : Colors.white,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: isDark ? Colors.white : AppColors.darkBG,
                        ),
                        iconEnabledColor:
                            isDark ? Colors.white70 : Colors.black54,
                        decoration: _buildInputDecoration(
                          label: 'Categoria',
                          isDark: isDark,
                          prefixIcon: Icons.category_rounded,
                        ),
                        items: ShelterEventType.values.map((type) {
                          final dummy = ShelterEvent(
                            id: '',
                            ongId: '',
                            title: '',
                            description: '',
                            eventType: type,
                            locationName: '',
                            address: '',
                            startDate: DateTime.now(),
                            createdAt: DateTime.now(),
                          );
                          return DropdownMenuItem(
                            value: type,
                            child: Row(
                              children: [
                                Icon(dummy.eventTypeIcon,
                                    size: 18, color: dummy.eventTypeColor),
                                const SizedBox(width: 8),
                                Text(
                                  dummy.eventTypeLabel,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.darkBG,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _eventType = val);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Título do Evento
                      TextFormField(
                        controller: _titleController,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: isDark ? Colors.white : AppColors.darkBG,
                        ),
                        decoration: _buildInputDecoration(
                          label: 'Título do Evento *',
                          hint: 'Ex: Feira de Adoção de Filhotes & Bazar',
                          isDark: isDark,
                          prefixIcon: Icons.title_rounded,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Informe o título do evento'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Data e Horário
                      Text(
                        'DATA & HORÁRIO *',
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: isDark
                              ? const Color(0xFF93C5FD)
                              : const Color(0xFF1D4ED8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _pickStartDate(isDark),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF0F172A)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white12
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 20,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${dateFormat.format(_startDate)} às ${_startTime.format(context)}',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.darkBG,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down_rounded,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Local e Endereço
                      TextFormField(
                        controller: _locationNameController,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: isDark ? Colors.white : AppColors.darkBG,
                        ),
                        decoration: _buildInputDecoration(
                          label: 'Nome do Local / Ponto de Referência *',
                          hint: 'Ex: Shopping Morumbi - Piso Térreo',
                          isDark: isDark,
                          prefixIcon: Icons.place_rounded,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Informe o local do evento'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _addressController,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: isDark ? Colors.white : AppColors.darkBG,
                        ),
                        decoration: _buildInputDecoration(
                          label: 'Endereço Completo *',
                          hint: 'Ex: Av. Roque Petroni Júnior, 1089 - Brooklin',
                          isDark: isDark,
                          prefixIcon: Icons.location_on_outlined,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Informe o endereço'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cityController,
                              style: TextStyle(
                                fontSize: 13.5,
                                color: isDark ? Colors.white : AppColors.darkBG,
                              ),
                              decoration: _buildInputDecoration(
                                label: 'Cidade',
                                hint: 'São Paulo - SP',
                                isDark: isDark,
                                prefixIcon: Icons.location_city_rounded,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _whatsappController,
                              keyboardType: TextInputType.phone,
                              style: TextStyle(
                                fontSize: 13.5,
                                color: isDark ? Colors.white : AppColors.darkBG,
                              ),
                              decoration: _buildInputDecoration(
                                label: 'WhatsApp de Dúvidas',
                                hint: '(11) 99999-9999',
                                isDark: isDark,
                                prefixIcon: Icons.chat_rounded,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Descrição
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: isDark ? Colors.white : AppColors.darkBG,
                        ),
                        decoration: _buildInputDecoration(
                          label: 'Descrição & Instruções *',
                          hint:
                              'Conte sobre o evento, requisitos para adotar, atrações e parceiros...',
                          isDark: isDark,
                          prefixIcon: Icons.description_rounded,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Adicione uma breve descrição'
                            : null,
                      ),
                      const SizedBox(height: 20),

                      // Acolhidos participantes (Se houver animais)
                      if (_isLoadingAnimals) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.deepPurpleAccent,
                              ),
                            ),
                          ),
                        ),
                      ] else if (_ongAnimals.isNotEmpty) ...[
                        Text(
                          'ACOLHIDOS PARTICIPANTES NA FEIRA',
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: isDark
                                ? const Color(0xFF93C5FD)
                                : const Color(0xFF1D4ED8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Selecione os pets que estarão presentes no evento:',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _ongAnimals.map((animal) {
                            final isSelected =
                                _selectedAnimalIds.contains(animal.id);
                            return FilterChip(
                              label: Text(
                                animal.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark
                                          ? Colors.white70
                                          : Colors.black87),
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: Colors.deepPurpleAccent,
                              backgroundColor: isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFF1F5F9),
                              checkmarkColor: Colors.white,
                              onSelected: (val) {
                                setState(() {
                                  if (val) {
                                    _selectedAnimalIds.add(animal.id);
                                  } else {
                                    _selectedAnimalIds.remove(animal.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Toggle de Publicação no Feed
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Publicar automaticamente no Feed Social',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.darkBG,
                          ),
                        ),
                        subtitle: Text(
                          'O evento será divulgado para todos os tutores e seguidores da ONG',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                        value: _isPublishedFeed,
                        activeThumbColor: Colors.deepPurpleAccent,
                        onChanged: (val) => setState(() => _isPublishedFeed = val),
                      ),
                      const SizedBox(height: 24),

                      // Botão Salvar
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurpleAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  isEditing
                                      ? 'Salvar Alterações'
                                      : 'Publicar Evento',
                                  style: const TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
