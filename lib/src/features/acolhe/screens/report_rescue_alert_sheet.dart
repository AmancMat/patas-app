import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../app.dart';
import '../../../constants/app_colors.dart';
import '../models/rescue_alert_model.dart';
import '../services/shelter_service.dart';

class ReportRescueAlertSheet extends StatefulWidget {
  final VoidCallback onSaved;

  const ReportRescueAlertSheet({super.key, required this.onSaved});

  static Future<void> show(BuildContext context, {required VoidCallback onSaved}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReportRescueAlertSheet(onSaved: onSaved),
    );
  }

  @override
  State<ReportRescueAlertSheet> createState() => _ReportRescueAlertSheetState();
}

class _ReportRescueAlertSheetState extends State<ReportRescueAlertSheet> {
  final _formKey = GlobalKey<FormState>();
  final _shelterService = ShelterService();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _referencePointController = TextEditingController();
  final _cityController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _reporterNameController = TextEditingController();
  final _reporterPhoneController = TextEditingController();

  RescueUrgency _urgency = RescueUrgency.alta;
  RescueAlertType _alertType = RescueAlertType.ferido;
  final List<XFile> _selectedPhotos = [];
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _referencePointController.dispose();
    _cityController.dispose();
    _neighborhoodController.dispose();
    _reporterNameController.dispose();
    _reporterPhoneController.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked.isNotEmpty) {
      setState(() => _selectedPhotos.addAll(picked));
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _selectedPhotos.add(picked));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Adicione pelo menos 1 foto do animal para apoiar o resgate.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final alert = RescueAlert(
        id: '',
        reporterName: _reporterNameController.text.trim(),
        reporterPhone: _reporterPhoneController.text.trim(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        urgency: _urgency,
        alertType: _alertType,
        address: _addressController.text.trim(),
        neighborhood: _neighborhoodController.text.trim().isEmpty
            ? null
            : _neighborhoodController.text.trim(),
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        referencePoint: _referencePointController.text.trim().isEmpty
            ? null
            : _referencePointController.text.trim(),
        createdAt: DateTime.now(),
      );

      await _shelterService.createRescueAlert(
        alert,
        photoFiles: _selectedPhotos,
      );

      widget.onSaved();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '🚨 Chamado de socorro enviado com sucesso! As ONGs da região foram notificadas.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar chamado: $e'),
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
        borderSide: const BorderSide(color: Colors.amber, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;

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
            // Drag handle (padrão único sem botão redundante)
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header limpo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.amber,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reportar Animal em Risco',
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.darkBG,
                          ),
                        ),
                        Text(
                          'Acione ONGs e protetores da sua região para resgate',
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
                      // Seletor de Urgência
                      Text(
                        'NÍVEL DE URGÊNCIA *',
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
                      Row(
                        children: [
                          Expanded(
                            child: _buildUrgencyChip(
                              urgency: RescueUrgency.critico,
                              label: 'Crítico / Ferido',
                              color: const Color(0xFFDC2626),
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildUrgencyChip(
                              urgency: RescueUrgency.alta,
                              label: 'Alta Prioridade',
                              color: const Color(0xFFEA580C),
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildUrgencyChip(
                              urgency: RescueUrgency.media,
                              label: 'Média Urgência',
                              color: const Color(0xFFD97706),
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildUrgencyChip(
                              urgency: RescueUrgency.baixa,
                              label: 'Baixa Urgência',
                              color: const Color(0xFF2563EB),
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Tipo de Ocorrência
                      Text(
                        'TIPO DE OCORRÊNCIA *',
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
                      DropdownButtonFormField<RescueAlertType>(
                        initialValue: _alertType,
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
                          label: 'Classificação',
                          isDark: isDark,
                          prefixIcon: Icons.pets_rounded,
                        ),
                        items: RescueAlertType.values.map((type) {
                          final dummy = RescueAlert(
                            id: '',
                            reporterName: '',
                            reporterPhone: '',
                            title: '',
                            description: '',
                            urgency: RescueUrgency.media,
                            alertType: type,
                            address: '',
                            createdAt: DateTime.now(),
                          );
                          return DropdownMenuItem(
                            value: type,
                            child: Row(
                              children: [
                                Icon(dummy.typeIcon, size: 18, color: Colors.amber),
                                const SizedBox(width: 8),
                                Text(
                                  dummy.typeLabel,
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
                          if (val != null) setState(() => _alertType = val);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Fotos da Ocorrência
                      Text(
                        'FOTOS DO ANIMAL NO LOCAL *',
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
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _takePhoto,
                            icon: const Icon(Icons.camera_alt_rounded, size: 18),
                            label: const Text('Tirar Foto'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade800,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            onPressed: _pickPhotos,
                            icon: const Icon(Icons.photo_library_rounded, size: 18),
                            label: const Text('Galeria'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark ? Colors.white : AppColors.darkBG,
                              side: BorderSide(
                                color: isDark ? Colors.white24 : Colors.grey.shade300,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_selectedPhotos.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 80,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedPhotos.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, idx) {
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      _selectedPhotos[idx].path,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey.shade300,
                                        child: const Icon(Icons.image),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 2,
                                    right: 2,
                                    child: GestureDetector(
                                      onTap: () => setState(() => _selectedPhotos.removeAt(idx)),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.redAccent,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Título
                      TextFormField(
                        controller: _titleController,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: isDark ? Colors.white : AppColors.darkBG,
                        ),
                        decoration: _buildInputDecoration(
                          label: 'Resumo do Alerta *',
                          hint: 'Ex: Cachorrinho machucado na calçada',
                          isDark: isDark,
                          prefixIcon: Icons.title_rounded,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Informe o título do alerta'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Endereço e Localização
                      TextFormField(
                        controller: _addressController,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: isDark ? Colors.white : AppColors.darkBG,
                        ),
                        decoration: _buildInputDecoration(
                          label: 'Endereço Completo / Rua e Número *',
                          hint: 'Ex: Rua das Flores, 240',
                          isDark: isDark,
                          prefixIcon: Icons.location_on_rounded,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Informe o endereço onde o animal se encontra'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _neighborhoodController,
                              style: TextStyle(
                                fontSize: 13.5,
                                color: isDark ? Colors.white : AppColors.darkBG,
                              ),
                              decoration: _buildInputDecoration(
                                label: 'Bairro',
                                hint: 'Brooklin',
                                isDark: isDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _cityController,
                              style: TextStyle(
                                fontSize: 13.5,
                                color: isDark ? Colors.white : AppColors.darkBG,
                              ),
                              decoration: _buildInputDecoration(
                                label: 'Cidade',
                                hint: 'São Paulo',
                                isDark: isDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _referencePointController,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: isDark ? Colors.white : AppColors.darkBG,
                        ),
                        decoration: _buildInputDecoration(
                          label: 'Ponto de Referência',
                          hint: 'Ex: Em frente à padaria, próximo ao poste',
                          isDark: isDark,
                          prefixIcon: Icons.explore_rounded,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Dados de Contato de quem está reportando
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _reporterNameController,
                              style: TextStyle(
                                fontSize: 13.5,
                                color: isDark ? Colors.white : AppColors.darkBG,
                              ),
                              decoration: _buildInputDecoration(
                                label: 'Seu Nome *',
                                hint: 'Como a ONG pode te chamar',
                                isDark: isDark,
                                prefixIcon: Icons.person_outline_rounded,
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Informe seu nome'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _reporterPhoneController,
                              keyboardType: TextInputType.phone,
                              style: TextStyle(
                                fontSize: 13.5,
                                color: isDark ? Colors.white : AppColors.darkBG,
                              ),
                              decoration: _buildInputDecoration(
                                label: 'Seu WhatsApp *',
                                hint: '(11) 99999-9999',
                                isDark: isDark,
                                prefixIcon: Icons.chat_rounded,
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Informe seu WhatsApp'
                                  : null,
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
                          label: 'Detalhes da Situação *',
                          hint:
                              'Descreva o estado do animal, se está assustado, agressivo, sangrando ou se há filhotes...',
                          isDark: isDark,
                          prefixIcon: Icons.description_rounded,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Informe detalhes da situação'
                            : null,
                      ),
                      const SizedBox(height: 24),

                      // Botão de Enviar
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
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
                              : const Text(
                                  '🚨 Enviar Chamado de Socorro',
                                  style: TextStyle(
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

  Widget _buildUrgencyChip({
    required RescueUrgency urgency,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    final isSelected = _urgency == urgency;
    return InkWell(
      onTap: () => setState(() => _urgency = urgency),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? color
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark ? Colors.white12 : Colors.grey.shade300),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 14,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
