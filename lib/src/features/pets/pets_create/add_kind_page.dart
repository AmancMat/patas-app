import 'package:flutter/material.dart';
import 'package:patas_web_app/src/features/profile_creation/screens/profile_type_selection_screen.dart';

/// Tela de seleção de tipo de perfil (adicionar novo perfil)
/// Redireciona para a nova implementação moderna
class AddKindPage extends StatelessWidget {
  const AddKindPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileTypeSelectionScreen(isFirstProfile: false);
  }
}
