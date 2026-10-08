import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:patas_web_app/src/providers/active_account_provider.dart';
import '../../../../app.dart';
import '../../../../main.dart';

import 'package:patas_web_app/src/localization/localizations_ext.dart';

class EditProfilePage extends StatefulWidget {
  final bool isDialog;
  const EditProfilePage({super.key, this.isDialog = false});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  File? _imageFile;
  String? _imagePath;
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final data =
            await supabase.from('users').select().eq('id', user.id).single();
        setState(() {
          _userData = data;
          _nameController.text = data['name'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() {
        _imagePath = pickedFile.path;
        if (!kIsWeb) {
          _imageFile = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      String? imageUrl = _userData?['photo_url'];

      // 1. Upload new image if selected
      if (_imagePath != null) {
        final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final String path = '${user.id}/$fileName';

        if (kIsWeb) {
          final bytes = await XFile(_imagePath!).readAsBytes();
          await supabase.storage.from('user_avatars').uploadBinary(
                path,
                bytes,
                fileOptions: const FileOptions(
                  cacheControl: '3600',
                  upsert: false,
                  contentType: 'image/jpeg',
                ),
              );
        } else if (_imageFile != null) {
          await supabase.storage.from('user_avatars').upload(
                path,
                _imageFile!,
                fileOptions: const FileOptions(
                  cacheControl: '3600',
                  upsert: false,
                  contentType: 'image/jpeg',
                ),
              );
        }

        imageUrl = supabase.storage.from('user_avatars').getPublicUrl(path);
      }

      // 2. Update users table
      await supabase.from('users').update({
        'name': _nameController.text.trim(),
        'photo_url': imageUrl,
      }).eq('id', user.id);

      // 3. Update Auth Metadata (optional but good for consistency)
      await supabase.auth.updateUser(
        UserAttributes(
          data: {'name': _nameController.text.trim()},
        ),
      );

      // 4. Update Global Provider
      if (mounted) {
        Provider.of<ActiveAccountProvider>(context, listen: false).initialize();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('profile.tutor_updated_success'))),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('profile.tutor_save_error', {'error': '$e'}))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final bgColor = thmode.darkMode ? AppColors.bodygray : Colors.grey.shade100;
    final cardColor = thmode.darkMode ? AppColors.darkBG : Colors.white;
    final textColor = thmode.darkMode ? Colors.white : AppColors.darkBG;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(
            child: CircularProgressIndicator(color: AppColors.patasColor)),
      );
    }

    return Scaffold(
      backgroundColor: widget.isDialog ? Colors.transparent : bgColor,
      appBar: widget.isDialog 
        ? AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            centerTitle: true,
            title: Text(
              context.tr('profile.personal_data'),
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: textColor),
              ),
              const SizedBox(width: 8),
            ],
          )
        : AppBar(
            backgroundColor: bgColor,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.patasColor,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
        title: Text(
          context.tr('profile.personal_data'),
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          _isSaving
              ? const Center(
                  child: Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.patasColor),
                  ),
                ))
              : TextButton(
                  onPressed: _saveProfile,
                  child: Text(context.tr('common.save'),
                      style: const TextStyle(
                          color: AppColors.patasColor,
                          fontWeight: FontWeight.bold)),
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Semantics(
                button: true,
                label: context.tr('profile.change_photo_semantic'),
                child: GestureDetector(
                  onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor:
                          AppColors.patasColor.withValues(alpha: 0.1),
                      backgroundImage: _imagePath != null
                          ? (kIsWeb
                              ? NetworkImage(_imagePath!)
                              : FileImage(File(_imagePath!)) as ImageProvider)
                          : (_userData?['photo_url'] != null
                              ? NetworkImage(_userData?['photo_url'])
                                  as ImageProvider
                              : null),
                      child:
                          _imagePath == null && _userData?['photo_url'] == null
                              ? const Icon(Icons.person,
                                  size: 60, color: AppColors.patasColor)
                              : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.patasColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
),
              const SizedBox(height: 32),

              // Name Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('profile.name_call_hint'),
                    style: TextStyle(
                        color: textColor.withValues(alpha: 0.6), fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    style: TextStyle(color: textColor),
                    validator: (value) => value == null || value.isEmpty
                        ? context.tr('profile.name_required_error')
                        : null,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: cardColor,
                      hintText: context.tr('profile.name_hint'),
                      hintStyle:
                          TextStyle(color: textColor.withValues(alpha: 0.3)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Info Text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.patasColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: AppColors.patasColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.tr('profile.name_visibility_notice'),
                        style: TextStyle(
                            color: textColor.withValues(alpha: 0.6),
                            fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
