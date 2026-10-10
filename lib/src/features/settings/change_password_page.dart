import 'package:flutter/material.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/features/auth/services/auth_services.dart';
import 'package:patas_web_app/src/localization/locator.dart';
import 'package:patas_web_app/src/localization/localizations_ext.dart';
import 'package:patas_web_app/src/common_widgets/mobile_scroll_padding.dart';
import 'package:provider/provider.dart';
import '../../../../app.dart';

class ChangePasswordPage extends StatefulWidget {
  final bool isDialog;
  const ChangePasswordPage({super.key, this.isDialog = false});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSaving = false;
  bool _obscureCurrentPassword = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final successMsg = context.tr('password.success_message');
    setState(() => _isSaving = true);

    try {
      final authService = locator.get<AuthService>();

      // 1. Verificar a senha atual
      await authService.verifyPassword(_currentPasswordController.text.trim());

      // 2. Se a verificação passar, atualizar a senha
      await authService.updatePassword(_passwordController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMsg)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
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

    return Scaffold(
      backgroundColor: widget.isDialog ? Colors.transparent : bgColor,
      appBar: widget.isDialog
        ? AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            centerTitle: true,
            title: Text(
              context.tr('password.title'),
              style: const TextStyle(
                color: AppColors.patasColor,
                fontSize: 22,
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
              context.tr('password.title'),
              style: const TextStyle(
                color: AppColors.patasColor,
                fontSize: 22,
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.tr('password.subtitle'),
                style: TextStyle(
                    color: textColor.withValues(alpha: 0.7), fontSize: 14),
              ),
              const SizedBox(height: 32),

              // Current Password
              _buildLabel(context.tr('password.current_password'), textColor),
              const SizedBox(height: 8),
              TextFormField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrentPassword,
                style: TextStyle(color: textColor),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.tr('password.current_password_required');
                  }
                  return null;
                },
                decoration: _buildInputDecoration(
                  hint: context.tr('password.current_password_hint'),
                  cardColor: cardColor,
                  textColor: textColor,
                  isObscured: _obscureCurrentPassword,
                  onToggleVisibility: () => setState(
                      () => _obscureCurrentPassword = !_obscureCurrentPassword),
                ),
              ),

              const SizedBox(height: 24),

              // Password
              _buildLabel(context.tr('password.new_password'), textColor),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: TextStyle(color: textColor),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.tr('password.new_password_required');
                  }
                  if (value.length < 6) {
                    return context.tr('password.min_length_error');
                  }
                  return null;
                },
                decoration: _buildInputDecoration(
                  hint: context.tr('password.min_characters'),
                  cardColor: cardColor,
                  textColor: textColor,
                  isObscured: _obscurePassword,
                  onToggleVisibility: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),

              const SizedBox(height: 24),

              // Confirm Password
              _buildLabel(context.tr('password.confirm_password'), textColor),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                style: TextStyle(color: textColor),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.tr('password.confirm_password_required');
                  }
                  if (value != _passwordController.text) {
                    return context.tr('password.passwords_dont_match');
                  }
                  return null;
                },
                decoration: _buildInputDecoration(
                  hint: context.tr('password.repeat_password_hint'),
                  cardColor: cardColor,
                  textColor: textColor,
                  isObscured: _obscureConfirmPassword,
                  onToggleVisibility: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ),

              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: _isSaving ? null : _updatePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.patasColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        context.tr('password.update_button'),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
              const MobileScrollPadding(),
            ],
          ),
        ),
      ),
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
    required bool isObscured,
    required VoidCallback onToggleVisibility,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: cardColor,
      hintText: hint,
      hintStyle: TextStyle(color: textColor.withValues(alpha: 0.3)),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      suffixIcon: IconButton(
        icon: Icon(isObscured ? Icons.visibility_off : Icons.visibility,
            color: textColor.withValues(alpha: 0.4)),
        onPressed: onToggleVisibility,
      ),
    );
  }
}
