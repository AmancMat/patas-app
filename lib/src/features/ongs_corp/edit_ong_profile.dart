import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:patas_web_app/src/features/ongs_corp/models/ong_profile_model.dart';
import 'package:patas_web_app/src/features/ongs_corp/services/ong_service.dart';
import '../../../../main.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';
import 'package:provider/provider.dart';

class EditOngProfilePage extends StatefulWidget {
  final OngProfile ong;
  const EditOngProfilePage({super.key, required this.ong});

  @override
  EditOngProfilePageState createState() => EditOngProfilePageState();
}

class EditOngProfilePageState extends State<EditOngProfilePage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers para campos de texto
  late TextEditingController _nameController;
  late TextEditingController _cnpjController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _websiteController;
  late TextEditingController _animalsUnderCareController;
  late TextEditingController _yearsOfOperationController;
  late TextEditingController _donationPixController;
  late TextEditingController _bankDetailsController;
  late TextEditingController _currentNeedsController;
  late TextEditingController _aboutController;

  // Áreas de atuação
  final List<String> _availableActivityAreas = [
    'Resgate',
    'Adoção',
    'Tratamento Veterinário',
    'Castração',
    'Educação e Conscientização',
    'Abrigo Temporário',
  ];
  late List<String> _selectedActivityAreas;

  File? _profileImage;
  File? _coverImage;
  final ImagePicker _picker = ImagePicker();

  final OngService _ongService = OngService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.ong.name);
    _cnpjController = TextEditingController(text: widget.ong.cnpj);
    _addressController = TextEditingController(text: widget.ong.address);
    _phoneController = TextEditingController(text: widget.ong.phone);
    _emailController = TextEditingController(text: widget.ong.email);
    _websiteController = TextEditingController(text: widget.ong.website);
    _animalsUnderCareController = TextEditingController(
        text: widget.ong.animalsUnderCare?.toString() ?? '');
    _yearsOfOperationController =
        TextEditingController(text: widget.ong.yearsOfOperation);
    _donationPixController =
        TextEditingController(text: widget.ong.donationPix);
    _bankDetailsController =
        TextEditingController(text: widget.ong.bankDetails);
    _currentNeedsController =
        TextEditingController(text: widget.ong.currentNeeds);
    _aboutController = TextEditingController(text: widget.ong.about);
    _selectedActivityAreas = List.from(widget.ong.activityAreas ?? []);
  }

  Future<void> _pickImage(ImageSource source, bool isProfileImage) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        if (isProfileImage) {
          _profileImage = File(pickedFile.path);
        } else {
          _coverImage = File(pickedFile.path);
        }
      });
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
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final user = supabase.auth.currentUser;
      if (user == null) return;

      String? photoUrl = widget.ong.photoUrl;
      String? coverUrl = widget.ong.coverUrl;

      try {
        if (_profileImage != null) {
          photoUrl = await _ongService.uploadOngImage(_profileImage!, user.id);
        }
        if (_coverImage != null) {
          coverUrl = await _ongService.uploadOngCover(_coverImage!, user.id);
        }

        final updatedOng = widget.ong.copyWith(
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
        );

        await _ongService.updateOngProfile(updatedOng);
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil atualizado com sucesso!')),
        );
        Navigator.pop(context, true);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar o perfil: $e')),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
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
        title: const Text('Editar Perfil de ONG'),
        backgroundColor:
            thmode.darkMode ? AppColors.darkBG : AppColors.bodyLight,
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildCoverImagePicker(thmode, cardColor, textColor),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: () => _showImageSourceActionSheet(true),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: thmode.darkMode
                        ? Colors.grey.shade800
                        : Colors.grey.shade300,
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : (widget.ong.photoUrl != null &&
                                widget.ong.photoUrl!.isNotEmpty
                            ? NetworkImage(widget.ong.photoUrl!)
                            : null) as ImageProvider?,
                    child: _profileImage == null &&
                            (widget.ong.photoUrl == null ||
                                widget.ong.photoUrl!.isEmpty)
                        ? Icon(Icons.camera_alt,
                            size: 50, color: Colors.grey.shade400)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _buildSectionHeader('Informações Básicas', textColor),
              const SizedBox(height: 16),
              _buildLabel('Nome da Instituição*', textColor),
              const SizedBox(height: 8),
              TextFormField(
                style: TextStyle(color: textColor),
                controller: _nameController,
                decoration: _buildInputDecoration(
                    hint: 'Nome da ONG',
                    cardColor: cardColor,
                    textColor: textColor),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              _buildLabel('Telefone*', textColor),
              const SizedBox(height: 8),
              TextFormField(
                style: TextStyle(color: textColor),
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: _buildInputDecoration(
                    hint: '(00) 00000-0000',
                    cardColor: cardColor,
                    textColor: textColor),
              ),
              const SizedBox(height: 32),
              _buildSectionHeader('Área de Atuação', textColor),
              const SizedBox(height: 16),
              _buildActivityAreasSelector(textColor),
              const SizedBox(height: 32),
              _buildSectionHeader('Sobre', textColor),
              const SizedBox(height: 16),
              TextFormField(
                style: TextStyle(color: textColor),
                controller: _aboutController,
                maxLines: 5,
                decoration: _buildInputDecoration(
                    hint: 'História e missão...',
                    cardColor: cardColor,
                    textColor: textColor),
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.patasColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _submitForm,
                      child: const Text('Salvar Alterações',
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverImagePicker(
      DarkMode thmode, Color cardColor, Color textColor) {
    return GestureDetector(
      onTap: () => _showImageSourceActionSheet(false),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(15),
          image: _coverImage != null
              ? DecorationImage(
                  image: FileImage(_coverImage!), fit: BoxFit.cover)
              : (widget.ong.coverUrl != null && widget.ong.coverUrl!.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(widget.ong.coverUrl!),
                      fit: BoxFit.cover)
                  : null),
        ),
        child: _coverImage == null &&
                (widget.ong.coverUrl == null || widget.ong.coverUrl!.isEmpty)
            ? Center(
                child: Icon(Icons.add_photo_alternate,
                    size: 40, color: Colors.grey.shade400))
            : null,
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
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(
                color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildActivityAreasSelector(Color textColor) {
    final thmode = Provider.of<DarkMode>(context);
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
              selected
                  ? _selectedActivityAreas.add(area)
                  : _selectedActivityAreas.remove(area);
            });
          },
          selectedColor: AppColors.patasColor,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
              color: isSelected ? Colors.white : textColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13),
          backgroundColor:
              thmode.darkMode ? const Color(0xFF353535) : Colors.grey.shade200,
          side: BorderSide(
            color: isSelected
                ? AppColors.patasColor
                : (thmode.darkMode
                    ? Colors.grey.shade700
                    : Colors.grey.shade300),
            width: isSelected ? 1.5 : 1,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLabel(String label, Color textColor) {
    return Text(label,
        style: TextStyle(
            color: textColor.withValues(alpha: 0.6),
            fontSize: 13,
            fontWeight: FontWeight.bold));
  }

  InputDecoration _buildInputDecoration(
      {required String hint,
      required Color cardColor,
      required Color textColor}) {
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
