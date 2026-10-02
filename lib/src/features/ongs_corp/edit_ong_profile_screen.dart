import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/features/ongs_corp/models/ong_profile_model.dart';
import 'package:patas_web_app/src/features/ongs_corp/services/ong_service.dart';
import 'package:patas_web_app/src/providers/active_account_provider.dart';
import 'package:patas_web_app/src/common_widgets/cover_image_adjust_dialog.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../app.dart';

class EditOngProfileScreen extends StatefulWidget {
  final OngProfile ong;

  const EditOngProfileScreen({super.key, required this.ong});

  @override
  State<EditOngProfileScreen> createState() => _EditOngProfileScreenState();
}

class _EditOngProfileScreenState extends State<EditOngProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ongService = OngService();
  final _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _websiteController;
  late TextEditingController _aboutController;
  late TextEditingController _addressController;
  late TextEditingController _donationPixController;
  late TextEditingController _animalsUnderCareController;
  late TextEditingController _yearsOfOperationController;

  File? _newProfileImage;
  File? _newCoverImage;
  Uint8List? _newCoverBytes;
  String? _currentPhotoUrl;
  String? _currentCoverUrl;

  final List<String> _availableActivityAreas = [
    'Resgate',
    'Adoção',
    'Tratamento Veterinário',
    'Castração',
    'Educação e Conscientização',
    'Abrigo Temporário',
  ];
  late List<String> _selectedActivityAreas;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final ong = widget.ong;
    _nameController = TextEditingController(text: ong.name);
    _phoneController = TextEditingController(text: ong.phone ?? '');
    _emailController = TextEditingController(text: ong.email ?? '');
    _websiteController = TextEditingController(text: ong.website ?? '');
    _aboutController = TextEditingController(text: ong.about ?? '');
    _addressController = TextEditingController(text: ong.address ?? '');
    _donationPixController = TextEditingController(text: ong.donationPix ?? '');
    _animalsUnderCareController =
        TextEditingController(text: ong.animalsUnderCare?.toString() ?? '');
    _yearsOfOperationController =
        TextEditingController(text: ong.yearsOfOperation ?? '');

    _currentPhotoUrl = ong.photoUrl;
    _currentCoverUrl = ong.coverUrl;
    _selectedActivityAreas = List<String>.from(ong.activityAreas ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _aboutController.dispose();
    _addressController.dispose();
    _donationPixController.dispose();
    _animalsUnderCareController.dispose();
    _yearsOfOperationController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _newProfileImage = File(picked.path);
      });
    }
  }

  Future<void> _pickCoverImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (!mounted) return;
      final croppedBytes = await showDialog<Uint8List?>(
        context: context,
        builder: (ctx) => CoverImageAdjustDialog(xFile: picked),
      );

      if (croppedBytes != null && mounted) {
        setState(() {
          _newCoverBytes = croppedBytes;
          _newCoverImage = File(picked.path);
        });
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      String? photoUrl = _currentPhotoUrl;
      String? coverUrl = _currentCoverUrl;

      final userId = widget.ong.userId;

      // Upload da nova foto de perfil
      if (_newProfileImage != null) {
        photoUrl = await _ongService.uploadOngImage(_newProfileImage!, userId);
      }

      // Upload da nova foto de capa
      if (_newCoverBytes != null) {
        coverUrl = await _ongService.uploadOngCoverBytes(_newCoverBytes!, userId);
      } else if (_newCoverImage != null) {
        coverUrl = await _ongService.uploadOngCover(_newCoverImage!, userId);
      }

      final updatedOng = OngProfile(
        id: widget.ong.id,
        userId: widget.ong.userId,
        name: _nameController.text.trim(),
        cnpj: widget.ong.cnpj,
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        website: _websiteController.text.trim().isEmpty
            ? null
            : _websiteController.text.trim(),
        about: _aboutController.text.trim().isEmpty
            ? null
            : _aboutController.text.trim(),
        donationPix: _donationPixController.text.trim().isEmpty
            ? null
            : _donationPixController.text.trim(),
        animalsUnderCare: int.tryParse(_animalsUnderCareController.text.trim()),
        yearsOfOperation: _yearsOfOperationController.text.trim().isEmpty
            ? null
            : _yearsOfOperationController.text.trim(),
        bankDetails: widget.ong.bankDetails,
        currentNeeds: widget.ong.currentNeeds,
        activityAreas: _selectedActivityAreas,
        photoUrl: photoUrl,
        coverUrl: coverUrl,
        createdAt: widget.ong.createdAt,
      );

      await _ongService.updateOngProfile(updatedOng);

      // Atualiza o perfil ativo no ActiveAccountProvider se for a ONG ativa
      if (mounted) {
        final activeAccountProvider =
            Provider.of<ActiveAccountProvider>(context, listen: false);
        if (activeAccountProvider.activeAccount?.id == updatedOng.id) {
          activeAccountProvider.updateAccountDetails(
            id: updatedOng.id,
            name: updatedOng.name,
            photoUrl: updatedOng.photoUrl,
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Perfil da ONG atualizado com sucesso!',
                  style: TextStyle(fontFamily: 'Fredoka'),
                ),
              ],
            ),
            backgroundColor: AppColors.patasColor,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.of(context).pop(updatedOng);
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = 'Erro ao salvar alterações. Tente novamente.';
        if (e is PostgrestException) {
          if (e.code == '23502') {
            if (e.message.contains('phone')) {
              errorMsg =
                  'O campo WhatsApp ainda está configurado como obrigatório na tabela do Supabase. Para deixá-lo opcional, é necessário remover a restrição NOT NULL no banco.';
            } else if (e.message.contains('address')) {
              errorMsg = 'O endereço da instituição é obrigatório.';
            } else if (e.message.contains('name')) {
              errorMsg = 'O nome da instituição é obrigatório.';
            } else {
              errorMsg = 'Um campo obrigatório não foi preenchido: ${e.message}';
            }
          } else {
            errorMsg = e.message;
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMsg,
              style: const TextStyle(fontFamily: 'Fredoka'),
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;
    final cardColor = isDark ? const Color(0xFF1E1E24) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.darkBG;
    final subtextColor = isDark ? Colors.white60 : Colors.black54;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBG : AppColors.bodyLight,
      appBar: AppBar(
        title: const Text(
          'Editar Perfil da ONG',
          style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.darkBG : AppColors.bodyLight,
        elevation: 0,
        foregroundColor: textColor,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.patasColor,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _isSaving
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.patasColor,
                      ),
                    ),
                  )
                : TextButton(
                    onPressed: _saveChanges,
                    child: const Text(
                      'Salvar',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.patasColor,
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Capa e Foto de Perfil com Enquadramento
                    _buildCoverAndAvatarSection(isDark, cardColor, textColor),

                    const SizedBox(height: 28),

                    // Seção: Informações Básicas
                    _buildSectionHeader('Informações Principais', textColor),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: _nameController,
                      label: 'Nome da ONG / Abrigo*',
                      hint: 'Ex: Amigos de Quatro Patas',
                      cardColor: cardColor,
                      textColor: textColor,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'O nome é obrigatório'
                          : null,
                    ),

                    const SizedBox(height: 14),

                    _buildTextField(
                      controller: _addressController,
                      label: 'Endereço / Cidade / UF*',
                      hint: 'Ex: São Paulo, SP',
                      cardColor: cardColor,
                      textColor: textColor,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Informe o endereço ou cidade'
                          : null,
                    ),

                    const SizedBox(height: 24),

                    // Seção: Contatos da Instituição
                    _buildSectionHeader('Canais de Contato', textColor),
                    const SizedBox(height: 6),
                    Text(
                      'Preencha para que tutores possam entrar em contato com facilidade.',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 12,
                        color: subtextColor,
                      ),
                    ),
                    const SizedBox(height: 14),

                    _buildTextField(
                      controller: _phoneController,
                      label: 'WhatsApp / Telefone',
                      hint: 'Ex: (11) 98765-4321',
                      prefixIcon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                      cardColor: cardColor,
                      textColor: textColor,
                    ),

                    const SizedBox(height: 14),

                    _buildTextField(
                      controller: _emailController,
                      label: 'E-mail de Contato',
                      hint: 'Ex: contato@ong.org.br',
                      prefixIcon: Icons.mail_rounded,
                      keyboardType: TextInputType.emailAddress,
                      cardColor: cardColor,
                      textColor: textColor,
                    ),

                    const SizedBox(height: 14),

                    _buildTextField(
                      controller: _websiteController,
                      label: 'Website ou Link do Instagram',
                      hint: 'Ex: https://instagram.com/ongexemplo',
                      prefixIcon: Icons.language_rounded,
                      keyboardType: TextInputType.url,
                      cardColor: cardColor,
                      textColor: textColor,
                    ),

                    const SizedBox(height: 24),

                    // Seção: Apoio & PIX
                    _buildSectionHeader('Doações e Apoio', textColor),
                    const SizedBox(height: 14),

                    _buildTextField(
                      controller: _donationPixController,
                      label: 'Chave PIX para Doações',
                      hint: 'CNPJ, e-mail, telefone ou chave aleatória',
                      prefixIcon: Icons.pix_rounded,
                      cardColor: cardColor,
                      textColor: textColor,
                    ),

                    const SizedBox(height: 24),

                    // Seção: Sobre a Instituição
                    _buildSectionHeader('Sobre a Instituição', textColor),
                    const SizedBox(height: 14),

                    _buildTextField(
                      controller: _aboutController,
                      label: 'História e Missão',
                      hint: 'Conte aos tutores um pouco sobre o trabalho de resgate e acolhimento da sua ONG...',
                      maxLines: 4,
                      cardColor: cardColor,
                      textColor: textColor,
                    ),

                    const SizedBox(height: 24),

                    // Seção: Áreas de Atuação
                    _buildSectionHeader('Áreas de Atuação', textColor),
                    const SizedBox(height: 12),
                    _buildActivityAreasSelector(isDark, cardColor, textColor),

                    const SizedBox(height: 36),

                    // Botão Salvar
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.patasColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Salvar Alterações',
                              style: TextStyle(
                                fontFamily: 'Fredoka',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoverAndAvatarSection(
      bool isDark, Color cardColor, Color textColor) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Capa com proporção padronizada 16:9
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.grey.shade300,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_newCoverBytes != null)
                  Image.memory(_newCoverBytes!, fit: BoxFit.cover)
                else if (_newCoverImage != null)
                  kIsWeb
                      ? Image.network(_newCoverImage!.path, fit: BoxFit.cover)
                      : Image.file(_newCoverImage!, fit: BoxFit.cover)
                else if (_currentCoverUrl != null &&
                    _currentCoverUrl!.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: _currentCoverUrl!,
                    fit: BoxFit.cover,
                  )
                else
                  Image.asset(
                    'assets/image_capa.jpg',
                    fit: BoxFit.cover,
                  ),

                // Botão de alterar capa
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: ElevatedButton.icon(
                    onPressed: _pickCoverImage,
                    icon: const Icon(Icons.camera_alt_rounded, size: 16),
                    label: const Text(
                      'Alterar Capa',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.75),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Avatar / Logo sobreposto na margem inferior esquerda
        Positioned(
          bottom: -32,
          left: 16,
          child: GestureDetector(
            onTap: _pickProfileImage,
            child: Stack(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cardColor,
                    border: Border.all(
                      color: AppColors.patasColor,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _newProfileImage != null
                        ? (kIsWeb
                            ? Image.network(_newProfileImage!.path,
                                fit: BoxFit.cover)
                            : Image.file(_newProfileImage!, fit: BoxFit.cover))
                        : (_currentPhotoUrl != null &&
                                _currentPhotoUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: _currentPhotoUrl!,
                                fit: BoxFit.cover,
                              )
                            : Image.asset(
                                'assets/image_placeholder.png',
                                fit: BoxFit.cover,
                              )),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.patasColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.patasColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required Color cardColor,
    required Color textColor,
    IconData? prefixIcon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(fontFamily: 'Fredoka', color: textColor),
          decoration: InputDecoration(
            filled: true,
            fillColor: cardColor,
            hintText: hint,
            hintStyle: TextStyle(
              fontFamily: 'Fredoka',
              color: textColor.withValues(alpha: 0.35),
            ),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: AppColors.patasColor, size: 20)
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityAreasSelector(
      bool isDark, Color cardColor, Color textColor) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availableActivityAreas.map((area) {
        final isSelected = _selectedActivityAreas.contains(area);
        return FilterChip(
          label: Text(
            area,
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : textColor,
            ),
          ),
          selected: isSelected,
          selectedColor: AppColors.patasColor,
          checkmarkColor: Colors.white,
          backgroundColor: isDark
              ? const Color(0xFF353535)
              : Colors.grey.shade200,
          side: BorderSide(
            color: isSelected
                ? AppColors.patasColor
                : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
          ),
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedActivityAreas.add(area);
              } else {
                _selectedActivityAreas.remove(area);
              }
            });
          },
        );
      }).toList(),
    );
  }
}
