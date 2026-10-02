import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/features/family/models/family_member_model.dart';
import 'package:patas_web_app/src/features/family/services/family_service.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';
import 'package:provider/provider.dart';
import '../../../../main.dart';

class EditFamilyMemberPage extends StatefulWidget {
  final FamilyMember member;

  const EditFamilyMemberPage({super.key, required this.member});

  @override
  State<EditFamilyMemberPage> createState() => _EditFamilyMemberPageState();
}

class _EditFamilyMemberPageState extends State<EditFamilyMemberPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  String? _selectedRelationship;

  File? _image;
  final ImagePicker _picker = ImagePicker();
  final FamilyService _familyService = FamilyService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member.name);
    _selectedRelationship = widget.member.relationship;
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _showImageSourceActionSheet() {
    if (context.isWide) {
      _pickImage(ImageSource.gallery);
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
                _pickImage(ImageSource.gallery);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Câmera'),
              onTap: () {
                _pickImage(ImageSource.camera);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _submitForm() async {
    final hasExistingImage = widget.member.photoUrl != null && widget.member.photoUrl!.isNotEmpty;
    if (_image == null && !hasExistingImage) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Campos Obrigatórios'),
          content: const Text('Por favor, adicione uma foto do membro da família para continuar.'),
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
    
    if (_nameController.text.isEmpty || _selectedRelationship == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Campos Obrigatórios'),
          content: const Text('Por favor, preencha o nome e a relação do membro da família para continuar.'),
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

      final user = supabase.auth.currentUser;
      if (user == null) {
        // Handle user not logged in
        setState(() => _isLoading = false);
        return;
      }

      String? photoUrl = widget.member.photoUrl;
      if (_image != null) {
        try {
          photoUrl = await _familyService.uploadFamilyMemberImage(_image!, user.id);
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro no upload da imagem: $e')));
          setState(() => _isLoading = false);
          return;
        }
      }

      final updatedMember = FamilyMember(
        id: widget.member.id,
        userId: user.id,
        name: _nameController.text,
        relationship: _selectedRelationship!,
        photoUrl: photoUrl,
        createdAt: widget.member.createdAt,
      );

      try {
        await _familyService.updateFamilyMember(updatedMember);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Membro da família atualizado com sucesso!')));
        Navigator.of(context).pop(true);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao atualizar membro: $e')));
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Helper para determinar o ImageProvider de forma segura
  ImageProvider? _getImageProvider() {
    if (_image != null) {
      return FileImage(_image!);
    }
    if (widget.member.photoUrl != null && widget.member.photoUrl!.isNotEmpty) {
      return NetworkImage(widget.member.photoUrl!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final inputBorder = UnderlineInputBorder(
      borderSide: BorderSide(color: thmode.darkMode ? Colors.white54 : Colors.black54),
    );
    final labelStyle = TextStyle(color: thmode.darkMode ? Colors.white70 : Colors.black87);

    return Scaffold(
      backgroundColor: thmode.darkMode ? AppColors.darkBG : AppColors.bodyLight,
      appBar: AppBar(
        title: const Text('Editar Membro da Família'),
        backgroundColor: thmode.darkMode ? AppColors.darkBG : AppColors.bodyLight,
        elevation: 0,
        foregroundColor: thmode.darkMode ? Colors.white : Colors.black,
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
              Center(
                child: GestureDetector(
                  onTap: _showImageSourceActionSheet,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: thmode.darkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                    backgroundImage: _getImageProvider(),
                    child: _getImageProvider() == null ? Icon(Icons.person, size: 50, color: thmode.darkMode ? Colors.grey.shade400 : Colors.grey.shade600) : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                style: TextStyle(color: thmode.darkMode ? Colors.white : Colors.black),
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nome*',
                  labelStyle: labelStyle,
                  enabledBorder: inputBorder,
                  focusedBorder: inputBorder,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira um nome.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedRelationship, // Usar 'initialValue' para pré-selecionar
                decoration: InputDecoration(
                  labelText: 'Relação/Título*',
                  labelStyle: labelStyle,
                  enabledBorder: inputBorder,
                  focusedBorder: inputBorder,
                ),
                dropdownColor: thmode.darkMode ? AppColors.darkBG : AppColors.bodyLight,
                style: TextStyle(color: thmode.darkMode ? Colors.white : Colors.black),
                items: ['Pai', 'Mãe', 'Irmão', 'Irmã', 'Amigo', 'Amiga', 'Tio', 'Tia', 'Avô', 'Avó', 'Primo', 'Prima', 'Outro']
                    .map((String value) => DropdownMenuItem<String>(value: value, child: Text(value)))
                    .toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedRelationship = newValue;
                  });
                },
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.patasColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _submitForm,
                      child: const Text('Salvar Alterações', style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
