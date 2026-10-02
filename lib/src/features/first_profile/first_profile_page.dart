import 'package:flutter/material.dart';
import 'package:patas_web_app/src/features/profile_creation/screens/profile_type_selection_screen.dart';

/// Tela de criação do primeiro perfil (após cadastro)
/// Redireciona para a nova implementação moderna
class FirstProfilePage extends StatelessWidget {
  const FirstProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileTypeSelectionScreen(isFirstProfile: true);
  }
}
