import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/features/family/models/family_member_model.dart';
import 'package:patas_web_app/src/features/family/services/family_service.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';
import 'package:patas_web_app/src/localization/localizations_ext.dart';
import 'package:provider/provider.dart';
import '../../../../main.dart';

class CreateFamilyMemberPage extends StatefulWidget {
  const CreateFamilyMemberPage({super.key});

  @override
  State<CreateFamilyMemberPage> createState() => _CreateFamilyMemberPageState();
}

class _CreateFamilyMemberPageState extends State<CreateFamilyMemberPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _selectedRelationship;

  File? _image;
  final ImagePicker _picker = ImagePicker();
  final FamilyService _familyService = FamilyService();
  bool _isLoading = false;

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
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(context.tr('family.gallery')),
              onTap: () {
                _pickImage(ImageSource.gallery);
                Navigator.of(ctx).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: Text(context.tr('family.camera')),
              onTap: () {
                _pickImage(ImageSource.camera);
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _submitForm() async {
    if (_image == null || _nameController.text.isEmpty || _selectedRelationship == null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(context.tr('family.required_fields_title')),
          content: Text(context.tr('family.required_fields_content')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
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
        setState(() => _isLoading = false);
        return;
      }

      String? photoUrl;
      if (_image != null) {
        try {
          photoUrl = await _familyService.uploadFamilyMemberImage(_image!, user.id);
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('family.upload_error', {'error': '$e'}))));
          setState(() => _isLoading = false);
          return;
        }
      }

      final newMember = FamilyMember(
        id: '',
        userId: user.id,
        name: _nameController.text,
        relationship: _selectedRelationship!,
        photoUrl: photoUrl,
        createdAt: DateTime.now(),
      );

      try {
        await _familyService.createFamilyMember(newMember);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('family.add_success'))));
        Navigator.of(context).pop(true);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('family.add_error', {'error': '$e'}))));
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

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;
    final inputBorder = UnderlineInputBorder(
      borderSide: BorderSide(color: isDark ? Colors.white54 : Colors.black54),
    );
    final labelStyle = TextStyle(color: isDark ? Colors.white70 : Colors.black87);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBG : AppColors.bodyLight,
      appBar: AppBar(
        title: Text(
          context.tr('family.add_member_title'),
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.darkBG,
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDark ? AppColors.darkBG : AppColors.bodyLight,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.patasColor,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 550),
          child: Padding(
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
                        backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                        backgroundImage: _image != null ? FileImage(_image!) : null,
                        child: _image == null ? Icon(Icons.person_add_alt_1, size: 50, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600) : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: context.tr('family.name_label'),
                      labelStyle: labelStyle,
                      enabledBorder: inputBorder,
                      focusedBorder: inputBorder,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return context.tr('family.name_validation');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedRelationship,
                    decoration: InputDecoration(
                      labelText: context.tr('family.relationship_label'),
                      labelStyle: labelStyle,
                      enabledBorder: inputBorder,
                      focusedBorder: inputBorder,
                    ),
                    dropdownColor: isDark ? AppColors.darkBG : Colors.white,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    items: ['Pai', 'Mãe', 'Irmão', 'Irmã', 'Amigo', 'Amiga', 'Tio', 'Tia', 'Avô', 'Avó', 'Primo', 'Prima', 'Outro']
                        .map((String value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                FamilyMember.localizedRelationship(context, value),
                                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                              ),
                            ))
                        .toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedRelationship = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.patasColor))
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.patasColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _submitForm,
                          child: Text(
                            context.tr('family.add_button'),
                            style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
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
}
