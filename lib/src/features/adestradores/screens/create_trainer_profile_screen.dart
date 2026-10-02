import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/common_widgets/patas_essencial_app_bar.dart';
import 'package:patas_web_app/src/common_widgets/mobile_scroll_padding.dart';
import '../models/trainer_profile_model.dart';
import '../services/adestradores_service.dart';

class CreateTrainerProfileScreen extends StatefulWidget {
  final TrainerProfile? existingProfile;

  const CreateTrainerProfileScreen({
    super.key,
    this.existingProfile,
  });

  @override
  State<CreateTrainerProfileScreen> createState() =>
      _CreateTrainerProfileScreenState();
}

class _CreateTrainerProfileScreenState
    extends State<CreateTrainerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final AdestradoresService _service = AdestradoresService();

  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _whatsappController;
  late TextEditingController _instagramController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _centerAddressController;

  // Primeiro serviço opcional
  final TextEditingController _serviceNameController = TextEditingController();
  final TextEditingController _servicePriceController = TextEditingController();

  File? _pickedImage;
  String? _currentPhotoUrl;

  int _serviceRadiusKm = 15;
  bool _attendsHome = true;
  bool _attendsOnline = false;
  bool _attendsCenter = false;

  final List<String> _availableSpecialties = [
    'Obediência Básica',
    'Reatividade',
    'Filhotes',
    'Ansiedade',
    'Passeio',
    'Gatos',
    'Adestramento Positivo',
    'Truques & Agility',
    'Xixi e Cocô no Lugar Certo',
  ];

  late Set<String> _selectedSpecialties;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.existingProfile;

    _nameController = TextEditingController(text: p?.fullName ?? '');
    _bioController = TextEditingController(text: p?.bio ?? '');
    _whatsappController = TextEditingController(text: p?.whatsapp ?? '');
    _instagramController = TextEditingController(text: p?.instagram ?? '');
    _cityController = TextEditingController(text: p?.city ?? 'São Paulo');
    _stateController = TextEditingController(text: p?.state ?? 'SP');
    _centerAddressController =
        TextEditingController(text: p?.trainingCenterAddress ?? '');

    _serviceRadiusKm = p?.serviceRadiusKm ?? 15;
    _attendsHome = p?.attendsHome ?? true;
    _attendsOnline = p?.attendsOnline ?? false;
    _attendsCenter = p?.attendsCenter ?? false;
    _currentPhotoUrl = p?.profilePhoto;

    _selectedSpecialties = p != null
        ? p.specialties.toSet()
        : {'Obediência Básica', 'Filhotes'};

    if (p == null) {
      _checkExistingProfile();
    }
  }

  Future<void> _checkExistingProfile() async {
    final existing = await _service.getCurrentUserTrainerProfile();
    if (existing != null && mounted) {
      setState(() {
        _nameController.text = existing.fullName;
        _bioController.text = existing.bio ?? '';
        _whatsappController.text = existing.whatsapp ?? '';
        _instagramController.text = existing.instagram ?? '';
        _cityController.text = existing.city ?? 'São Paulo';
        _stateController.text = existing.state ?? 'SP';
        _centerAddressController.text = existing.trainingCenterAddress ?? '';
        _serviceRadiusKm = existing.serviceRadiusKm;
        _attendsHome = existing.attendsHome;
        _attendsOnline = existing.attendsOnline;
        _attendsCenter = existing.attendsCenter;
        _currentPhotoUrl = existing.profilePhoto;
        _selectedSpecialties = existing.specialties.toSet();
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _whatsappController.dispose();
    _instagramController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _centerAddressController.dispose();
    _serviceNameController.dispose();
    _servicePriceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      setState(() {
        _pickedImage = File(picked.path);
      });
    }
  }

  void _showImagePickerModal(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Escolha a foto do perfil',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.darkBG,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded,
                      color: AppColors.patasColor),
                  title: Text(
                    'Galeria',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded,
                      color: AppColors.patasColor),
                  title: Text(
                    'Câmera',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSpecialties.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione ao menos 1 especialidade.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('Faça login para cadastrar seu perfil de adestrador.');
      }

      String? photoUrl = _currentPhotoUrl;
      if (_pickedImage != null) {
        final uploaded =
            await _service.uploadTrainerPhoto(_pickedImage!, user.id);
        if (uploaded != null) {
          photoUrl = uploaded;
        }
      }

      // Serviços iniciais se preenchido
      final List<Map<String, dynamic>> initialServices = [];
      if (_serviceNameController.text.trim().isNotEmpty) {
        final cleanPrice = _servicePriceController.text
            .replaceAll('R\$', '')
            .replaceAll('.', '')
            .replaceAll(',', '.')
            .trim();
        final price = double.tryParse(cleanPrice) ?? 150.0;

        initialServices.add({
          'name': _serviceNameController.text.trim(),
          'price': price,
          'duration_minutes': 60,
          'modality': _attendsHome ? 'domicilio' : 'online',
        });
      }

      await _service.createOrUpdateTrainerProfile(
        fullName: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        profilePhoto: photoUrl,
        whatsapp: _whatsappController.text.trim(),
        instagram: _instagramController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim().toUpperCase(),
        serviceRadiusKm: _serviceRadiusKm,
        attendsHome: _attendsHome,
        attendsOnline: _attendsOnline,
        attendsCenter: _attendsCenter,
        trainingCenterAddress: _centerAddressController.text.trim(),
        specialties: _selectedSpecialties.toList(),
        initialServices: initialServices,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil de adestrador salvo com sucesso! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar perfil: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.bodygray : const Color(0xFFF5F7FA),
      appBar: PatasEssencialAppBar(
        title: widget.existingProfile != null
            ? 'Editar Perfil'
            : 'Cadastrar como Adestrador',
        subtitle: 'Divulgue seus serviços para tutores da sua região',
        leadingIcon: const Icon(
          Icons.sports_score_rounded,
          color: AppColors.patasColor,
          size: 22,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Avatar e Foto de Perfil
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 54,
                        backgroundColor:
                            AppColors.patasColor.withValues(alpha: 0.15),
                        backgroundImage: _pickedImage != null
                            ? FileImage(_pickedImage!)
                            : (_currentPhotoUrl != null &&
                                    _currentPhotoUrl!.isNotEmpty
                                ? NetworkImage(_currentPhotoUrl!)
                                    as ImageProvider
                                : null),
                        child: (_pickedImage == null &&
                                (_currentPhotoUrl == null ||
                                    _currentPhotoUrl!.isEmpty))
                            ? const Icon(
                                Icons.person,
                                size: 52,
                                color: AppColors.patasColor,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: () => _showImagePickerModal(isDark),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.patasColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Toque para alterar sua foto profissional',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 2. Dados Pessoais / Profissionais
                _buildSectionCard(
                  isDark: isDark,
                  title: 'Informações Básicas',
                  icon: Icons.badge_outlined,
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      label: 'Nome Completo ou Nome Profissional *',
                      hint: 'Ex: Carlos Silva | Especialista Canino',
                      isDark: isDark,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Informe seu nome' : null,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _bioController,
                      label: 'Biografia / Apresentação',
                      hint:
                          'Fale sobre sua metodologia, experiência com cães e gatos e histórico profissional...',
                      maxLines: 4,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _whatsappController,
                            label: 'WhatsApp com DDD *',
                            hint: 'Ex: 11999998888',
                            keyboardType: TextInputType.phone,
                            isDark: isDark,
                            prefixIcon: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 18,
                              color: Colors.green,
                            ),
                            validator: (v) =>
                                v == null || v.trim().isEmpty ? 'Obrigatório' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _instagramController,
                            label: 'Instagram (Opcional)',
                            hint: '@seu.adestramento',
                            isDark: isDark,
                            prefixIcon: const Icon(
                              Icons.camera_alt_outlined,
                              size: 18,
                              color: Colors.pinkAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // 3. Região e Modalidades de Atendimento
                _buildSectionCard(
                  isDark: isDark,
                  title: 'Região & Modalidades',
                  icon: Icons.location_on_outlined,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _buildTextField(
                            controller: _cityController,
                            label: 'Cidade *',
                            hint: 'Ex: São Paulo',
                            isDark: isDark,
                            validator: (v) =>
                                v == null || v.trim().isEmpty ? 'Informe a cidade' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: _buildTextField(
                            controller: _stateController,
                            label: 'UF *',
                            hint: 'SP',
                            isDark: isDark,
                            maxLength: 2,
                            validator: (v) =>
                                v == null || v.trim().isEmpty ? 'UF' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Raio de atendimento:',
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 14,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        Text(
                          'Até $_serviceRadiusKm km',
                          style: const TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.patasColor,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _serviceRadiusKm.toDouble(),
                      min: 5,
                      max: 80,
                      divisions: 15,
                      activeColor: AppColors.patasColor,
                      onChanged: (val) {
                        setState(() => _serviceRadiusKm = val.round());
                      },
                    ),
                    const Divider(height: 24),
                    Text(
                      'Modalidades aceitas:',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Atendimento a Domicílio',
                          style: TextStyle(fontSize: 14)),
                      subtitle: const Text('Vou até a residência do tutor',
                          style: TextStyle(fontSize: 11)),
                      value: _attendsHome,
                      activeTrackColor: AppColors.patasColor,
                      onChanged: (val) => setState(() => _attendsHome = val),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Consultoria Online',
                          style: TextStyle(fontSize: 14)),
                      subtitle: const Text(
                          'Sessões remotas por chamada de vídeo',
                          style: TextStyle(fontSize: 11)),
                      value: _attendsOnline,
                      activeTrackColor: AppColors.patasColor,
                      onChanged: (val) => setState(() => _attendsOnline = val),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Espaço / Centro de Treino Próprio',
                          style: TextStyle(fontSize: 14)),
                      subtitle: const Text('O tutor leva o pet até o meu local',
                          style: TextStyle(fontSize: 11)),
                      value: _attendsCenter,
                      activeTrackColor: AppColors.patasColor,
                      onChanged: (val) => setState(() => _attendsCenter = val),
                    ),
                    if (_attendsCenter) ...[
                      const SizedBox(height: 10),
                      _buildTextField(
                        controller: _centerAddressController,
                        label: 'Endereço do Centro de Treinamento',
                        hint: 'Rua, número, bairro',
                        isDark: isDark,
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 18),

                // 4. Especialidades
                _buildSectionCard(
                  isDark: isDark,
                  title: 'Especialidades & Foco',
                  icon: Icons.checklist_rounded,
                  children: [
                    Text(
                      'Selecione as áreas em que você atua com maior frequência:',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableSpecialties.map((spec) {
                        final isSelected = _selectedSpecialties.contains(spec);
                        return FilterChip(
                          label: Text(spec),
                          selected: isSelected,
                          selectedColor: AppColors.patasColor,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 12,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white70 : Colors.black87),
                          ),
                          backgroundColor: isDark
                              ? const Color(0xFF334155)
                              : Colors.grey.shade100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.patasColor
                                  : Colors.transparent,
                            ),
                          ),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedSpecialties.add(spec);
                              } else {
                                _selectedSpecialties.remove(spec);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // 5. Serviço Principal de Apresentação
                _buildSectionCard(
                  isDark: isDark,
                  title: 'Serviço em Destaque (Opcional)',
                  icon: Icons.sell_outlined,
                  children: [
                    Text(
                      'Cadastre seu serviço de entrada para os tutores verem o valor de referência:',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _buildTextField(
                            controller: _serviceNameController,
                            label: 'Nome do Serviço',
                            hint: 'Ex: Consulta Comportamental',
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _buildTextField(
                            controller: _servicePriceController,
                            label: 'Valor (R\$)',
                            hint: 'Ex: 150,00',
                            keyboardType: TextInputType.number,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Botão de Ação
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.patasColor,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            widget.existingProfile != null
                                ? 'Salvar Alterações'
                                : 'Publicar Perfil de Adestrador',
                            style: const TextStyle(
                              fontFamily: 'Fredoka',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),
                const MobileScrollPadding(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required bool isDark,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.patasColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.darkBG,
                ),
              ),
            ],
          ),
          const Divider(height: 22),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    Widget? prefixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white30 : Colors.grey.shade400,
            ),
            prefixIcon: prefixIcon,
            counterText: '',
            filled: true,
            fillColor:
                isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.white12 : Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.white12 : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.patasColor,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
