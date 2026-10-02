import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:patas_web_app/src/constants/routes.dart';
import 'package:patas_web_app/src/features/ongs_corp/models/ong_profile_model.dart';
import 'package:patas_web_app/src/features/ongs_corp/services/ong_service.dart';
import 'package:patas_web_app/src/common_widgets/cover_image_adjust_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../main.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';
import 'package:provider/provider.dart';

class CreateOngProfilePage extends StatefulWidget {
  const CreateOngProfilePage({super.key});

  @override
  CreateOngProfilePageState createState() => CreateOngProfilePageState();
}

class CreateOngProfilePageState extends State<CreateOngProfilePage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers para campos de texto
  final _nameController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _animalsUnderCareController = TextEditingController();
  final _yearsOfOperationController = TextEditingController();
  final _donationPixController = TextEditingController();
  final _bankDetailsController = TextEditingController();
  final _currentNeedsController = TextEditingController();
  final _aboutController = TextEditingController();

  // Áreas de atuação (multi-seleção)
  final List<String> _availableActivityAreas = [
    'Resgate',
    'Adoção',
    'Tratamento Veterinário',
    'Castração',
    'Educação e Conscientização',
    'Abrigo Temporário',
  ];
  final List<String> _selectedActivityAreas = [];

  File? _profileImage;
  File? _coverImage;
  Uint8List? _coverBytes;
  final ImagePicker _picker = ImagePicker();

  final OngService _ongService = OngService();
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source, bool isProfileImage) async {
    final pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      if (isProfileImage) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      } else {
        if (!mounted) return;
        final croppedBytes = await showDialog<Uint8List?>(
          context: context,
          builder: (ctx) => CoverImageAdjustDialog(xFile: pickedFile),
        );

        if (croppedBytes != null && mounted) {
          setState(() {
            _coverBytes = croppedBytes;
            _coverImage = File(pickedFile.path);
          });
        }
      }
    }
  }

  void _showImageSourceActionSheet(bool isProfileImage) {
    if (context.isWide) {
      _pickImage(ImageSource.gallery, isProfileImage);
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () {
                _pickImage(ImageSource.gallery, isProfileImage);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Câmera'),
              onTap: () {
                _pickImage(ImageSource.camera, isProfileImage);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _submitForm() async {
    // Validação de campos obrigatórios
    if (_profileImage == null ||
        _nameController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _selectedActivityAreas.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Campos Obrigatórios'),
          content: const Text(
              'Por favor, preencha todos os campos com * para continuar.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      User? user = supabase.auth.currentUser;
      if (user == null && supabase.auth.currentSession != null) {
        user = supabase.auth.currentSession!.user;
      }

      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Erro: Usuário não identificado. Tente fazer login novamente.')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      String? photoUrl;
      String? coverUrl;

      try {
        // Upload da foto de perfil
        if (_profileImage != null) {
          photoUrl = await _ongService.uploadOngImage(_profileImage!, user.id);
        }

        // Upload da foto de capa
        if (_coverBytes != null) {
          coverUrl =
              await _ongService.uploadOngCoverBytes(_coverBytes!, user.id);
        } else if (_coverImage != null) {
          coverUrl = await _ongService.uploadOngCover(_coverImage!, user.id);
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro no upload das imagens: $e')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final newOng = OngProfile(
        id: '',
        userId: user.id,
        name: _nameController.text,
        cnpj: _cnpjController.text.isEmpty ? null : _cnpjController.text,
        address: _addressController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        website:
            _websiteController.text.isEmpty ? null : _websiteController.text,
        activityAreas: _selectedActivityAreas,
        animalsUnderCare: int.tryParse(_animalsUnderCareController.text),
        yearsOfOperation: _yearsOfOperationController.text.isEmpty
            ? null
            : _yearsOfOperationController.text,
        donationPix: _donationPixController.text.isEmpty
            ? null
            : _donationPixController.text,
        bankDetails: _bankDetailsController.text.isEmpty
            ? null
            : _bankDetailsController.text,
        currentNeeds: _currentNeedsController.text.isEmpty
            ? null
            : _currentNeedsController.text,
        photoUrl: photoUrl,
        coverUrl: coverUrl,
        about: _aboutController.text.isEmpty ? null : _aboutController.text,
        createdAt: DateTime.now(),
      );

      try {
        await _ongService.createOngProfile(newOng);
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil de ONG criado com sucesso!')),
        );

        // Navega para a Home limpando todo o histórico
        Navigator.pushNamedAndRemoveUntil(
          context,
          NamedRoute.home,
          (route) => false,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar o perfil: $e')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cnpjController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _animalsUnderCareController.dispose();
    _yearsOfOperationController.dispose();
    _donationPixController.dispose();
    _bankDetailsController.dispose();
    _currentNeedsController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final cardColor =
        thmode.darkMode ? Colors.white.withValues(alpha: 0.05) : Colors.white;
    final textColor = thmode.darkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: thmode.darkMode ? AppColors.darkBG : AppColors.bodyLight,
      appBar: AppBar(
        title: const Text('Criar Perfil de ONG ou Abrigo'),
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.patasColor,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        centerTitle: true,
        backgroundColor:
            thmode.darkMode ? AppColors.darkBG : AppColors.bodyLight,
        elevation: 0,
        foregroundColor: thmode.darkMode ? Colors.white : Colors.black,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Foto de Capa
              _buildCoverImagePicker(thmode, cardColor, textColor),
              const SizedBox(height: 16),

              // Foto de Perfil
              Center(
                child: Semantics(
                  button: true,
                  label: 'Adicionar logo da instituição',
                  child: GestureDetector(
                    onTap: () => _showImageSourceActionSheet(true),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: thmode.darkMode
                        ? Colors.grey.shade800
                        : Colors.grey.shade300,
                    backgroundImage: _profileImage != null
                        ? (kIsWeb
                            ? NetworkImage(_profileImage!.path) as ImageProvider
                            : FileImage(_profileImage!) as ImageProvider)
                        : null,
                    child: _profileImage == null
                        ? Icon(Icons.camera_alt,
                            size: 50,
                            color: thmode.darkMode
                                ? Colors.grey.shade400
                                : Colors.grey.shade600)
                        : null,
                  ),
                ),
)
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Logo da Instituição*',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Seção: Informações Básicas
              _buildSectionHeader('Informações Básicas', textColor),
              const SizedBox(height: 16),

              _buildLabel('Nome da Instituição*', textColor),
              const SizedBox(height: 8),
              TextFormField(
                style: TextStyle(color: textColor),
                controller: _nameController,
                decoration: _buildInputDecoration(
                  hint: 'Nome da ONG ou Abrigo',
                  cardColor: cardColor,
                  textColor: textColor,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o nome da instituição.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildLabel('CNPJ (opcional)', textColor),
              const SizedBox(height: 8),
              TextFormField(
                style: TextStyle(color: textColor),
                controller: _cnpjController,
                keyboardType: TextInputType.number,
                decoration: _buildInputDecoration(
                  hint: '00.000.000/0000-00',
                  cardColor: cardColor,
                  textColor: textColor,
                ),
              ),
              const SizedBox(height: 16),

              _buildLabel('Endereço Completo*', textColor),
              const SizedBox(height: 8),
              TextFormField(
                style: TextStyle(color: textColor),
                controller: _addressController,
                maxLines: 2,
                decoration: _buildInputDecoration(
                  hint: 'Rua, número, bairro, cidade, estado',
                  cardColor: cardColor,
                  textColor: textColor,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Telefone*', textColor),
                        const SizedBox(height: 8),
                        TextFormField(
                          style: TextStyle(color: textColor),
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: _buildInputDecoration(
                            hint: '(00) 00000-0000',
                            cardColor: cardColor,
                            textColor: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Email*', textColor),
                        const SizedBox(height: 8),
                        TextFormField(
                          style: TextStyle(color: textColor),
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _buildInputDecoration(
                            hint: 'contato@ong.org',
                            cardColor: cardColor,
                            textColor: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildLabel('Site ou Rede Social', textColor),
              const SizedBox(height: 8),
              TextFormField(
                style: TextStyle(color: textColor),
                controller: _websiteController,
                keyboardType: TextInputType.url,
                decoration: _buildInputDecoration(
                  hint: 'www.exemplo.com ou @instagram',
                  cardColor: cardColor,
                  textColor: textColor,
                ),
              ),
              const SizedBox(height: 32),

              // Seção: Atuação
              _buildSectionHeader('Área de Atuação', textColor),
              const SizedBox(height: 16),

              _buildLabel('Selecione as áreas de atuação*', textColor),
              const SizedBox(height: 8),
              _buildActivityAreasSelector(cardColor, textColor),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Animais sob cuidado', textColor),
                        const SizedBox(height: 8),
                        TextFormField(
                          style: TextStyle(color: textColor),
                          controller: _animalsUnderCareController,
                          keyboardType: TextInputType.number,
                          decoration: _buildInputDecoration(
                            hint: 'Quantidade',
                            cardColor: cardColor,
                            textColor: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Anos de atuação', textColor),
                        const SizedBox(height: 8),
                        TextFormField(
                          style: TextStyle(color: textColor),
                          controller: _yearsOfOperationController,
                          decoration: _buildInputDecoration(
                            hint: 'Ex: 5 anos',
                            cardColor: cardColor,
                            textColor: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Seção: Doações
              _buildSectionHeader('Formas de Doação', textColor),
              const SizedBox(height: 16),

              _buildLabel('PIX', textColor),
              const SizedBox(height: 8),
              TextFormField(
                style: TextStyle(color: textColor),
                controller: _donationPixController,
                decoration: _buildInputDecoration(
                  hint: 'Chave PIX',
                  cardColor: cardColor,
                  textColor: textColor,
                ),
              ),
              const SizedBox(height: 16),

              _buildLabel('Dados Bancários', textColor),
              const SizedBox(height: 8),
              TextFormField(
                style: TextStyle(color: textColor),
                controller: _bankDetailsController,
                maxLines: 3,
                decoration: _buildInputDecoration(
                  hint: 'Banco, agência, conta',
                  cardColor: cardColor,
                  textColor: textColor,
                ),
              ),
              const SizedBox(height: 16),

              _buildLabel('Necessidades Atuais', textColor),
              const SizedBox(height: 8),
              TextFormField(
                style: TextStyle(color: textColor),
                controller: _currentNeedsController,
                maxLines: 3,
                decoration: _buildInputDecoration(
                  hint: 'Ração, medicamentos, voluntários, etc.',
                  cardColor: cardColor,
                  textColor: textColor,
                ),
              ),
              const SizedBox(height: 32),

              // Seção: Sobre
              _buildSectionHeader('Sobre a Instituição', textColor),
              const SizedBox(height: 16),

              _buildLabel('História e Missão', textColor),
              const SizedBox(height: 8),
              TextFormField(
                style: TextStyle(color: textColor),
                controller: _aboutController,
                maxLines: 5,
                decoration: _buildInputDecoration(
                  hint: 'Conte a história da sua instituição...',
                  cardColor: cardColor,
                  textColor: textColor,
                ),
              ),
              const SizedBox(height: 32),

              // Botão Salvar
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.patasColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _submitForm,
                      child: const Text('Salvar Perfil',
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
              const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildCoverImagePicker(
      DarkMode thmode, Color cardColor, Color textColor) {
    final hasCover = _coverBytes != null || _coverImage != null;

    return Semantics(
      button: true,
      label: 'Adicionar foto de capa da ONG',
      child: GestureDetector(
        onTap: () => _showImageSourceActionSheet(false),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: thmode.darkMode ? Colors.white12 : Colors.grey.shade300,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_coverBytes != null)
                  Image.memory(_coverBytes!, fit: BoxFit.cover)
                else if (_coverImage != null)
                  kIsWeb
                      ? Image.network(_coverImage!.path, fit: BoxFit.cover)
                      : Image.file(_coverImage!, fit: BoxFit.cover)
                else
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_rounded,
                          size: 42,
                          color: AppColors.patasColor,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Adicionar Foto de Capa (16:9)',
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Toque para escolher e enquadrar',
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Botão flutuante para alterar/ajustar se já tiver capa
                if (hasCover)
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.crop_rounded,
                              size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Ajustar Capa',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.patasColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityAreasSelector(Color cardColor, Color textColor) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availableActivityAreas.map((area) {
        final isSelected = _selectedActivityAreas.contains(area);
        return FilterChip(
          label: Text(area),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedActivityAreas.add(area);
              } else {
                _selectedActivityAreas.remove(area);
              }
            });
          },
          // CORES DE ALTO CONTRASTE
          selectedColor: AppColors.patasColor,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : textColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
          // Fundo do chip não selecionado
          backgroundColor: isDark
              ? const Color(0xFF353535) // Cinza escuro para texto branco
              : Colors.grey.shade200, // Cinza claro para texto preto
          side: BorderSide(
            color: isSelected
                ? AppColors.patasColor
                : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            width: isSelected ? 1.5 : 1,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          elevation: isSelected ? 2 : 0,
          pressElevation: 4,
          shadowColor: Colors.black.withValues(alpha: 0.3),
        );
      }).toList(),
    );
  }

  Widget _buildLabel(String label, Color textColor) {
    return Text(
      label,
      style: TextStyle(
          color: textColor.withValues(alpha: 0.6),
          fontSize: 13,
          fontWeight: FontWeight.bold),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required Color cardColor,
    required Color textColor,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: cardColor,
      hintText: hint,
      hintStyle: TextStyle(color: textColor.withValues(alpha: 0.3)),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}
