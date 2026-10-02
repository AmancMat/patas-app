import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/providers/active_account_provider.dart';
import '../models/shelter_animal_model.dart';
import '../models/adoption_application_model.dart';
import '../services/shelter_service.dart';

class ApplyAdoptionSheet extends StatefulWidget {
  final ShelterAnimal animal;

  const ApplyAdoptionSheet({super.key, required this.animal});

  static Future<bool?> show(
    BuildContext context, {
    required ShelterAnimal animal,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ApplyAdoptionSheet(animal: animal),
    );
  }

  @override
  State<ApplyAdoptionSheet> createState() => _ApplyAdoptionSheetState();
}

class _ApplyAdoptionSheetState extends State<ApplyAdoptionSheet> {
  final ShelterService _service = ShelterService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _reasonController;
  late TextEditingController _otherPetsController;

  String _housingType = 'casa';
  bool _hasYard = true;
  bool _hasOtherPets = false;
  bool _householdAgreement = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final activeAcc =
        Provider.of<ActiveAccountProvider>(context, listen: false).activeAccount;

    _nameController = TextEditingController(text: activeAcc?.name ?? '');
    _phoneController = TextEditingController();
    _reasonController = TextEditingController();
    _otherPetsController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _reasonController.dispose();
    _otherPetsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faça login para enviar a ficha de adoção.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final app = AdoptionApplication(
      id: '',
      animalId: widget.animal.id,
      ongId: widget.animal.ongId,
      applicantUserId: user.id,
      applicantName: _nameController.text.trim(),
      applicantPhone: _phoneController.text.trim(),
      applicantEmail: user.email,
      housingType: _housingType,
      hasYard: _hasYard,
      hasOtherPets: _hasOtherPets,
      otherPetsDetails: _hasOtherPets ? _otherPetsController.text.trim() : null,
      householdAgreement: _householdAgreement,
      adoptionReason: _reasonController.text.trim().isEmpty
          ? null
          : _reasonController.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await _service.submitAdoptionApplication(app);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao enviar proposta. Tente novamente.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;
    final animal = widget.animal;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.purpleAccent.withValues(alpha: 0.15),
                      backgroundImage: animal.photoUrl != null
                          ? NetworkImage(animal.photoUrl!)
                          : null,
                      child: animal.photoUrl == null
                          ? const Icon(Icons.pets, color: Colors.purpleAccent)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Adotar ${animal.name} 🐾',
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.darkBG,
                          ),
                        ),
                        Text(
                          'Ficha de Adoção Responsável',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Formulário
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('SEU NOME COMPLETO *'),
                    TextFormField(
                      controller: _nameController,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Informe seu nome' : null,
                      decoration: _inputDecoration(
                        hint: 'Como a ONG deve te chamar',
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(height: 14),

                    _buildLabel('SEU WHATSAPP / TELEFONE DE CONTATO *'),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      validator: (v) => v == null || v.trim().length < 8
                          ? 'Informe um telefone válido com DDD'
                          : null,
                      decoration: _inputDecoration(
                        hint: '(11) 99999-9999',
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Tipo de Moradia
                    _buildLabel('TIPO DE MORADIA'),
                    DropdownButtonFormField<String>(
                      initialValue: _housingType,
                      decoration: _inputDecoration(hint: '', isDark: isDark),
                      dropdownColor:
                          isDark ? const Color(0xFF1E293B) : Colors.white,
                      items: const [
                        DropdownMenuItem(value: 'casa', child: Text('🏠 Casa')),
                        DropdownMenuItem(
                            value: 'apartamento', child: Text('🏢 Apartamento')),
                        DropdownMenuItem(value: 'sitio', child: Text('🌳 Sítio / Chácara')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _housingType = v);
                      },
                    ),
                    const SizedBox(height: 14),

                    // Quintal / Área Externa
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Possui quintal ou área externa segura?'),
                      value: _hasYard,
                      activeColor: Colors.purpleAccent,
                      onChanged: (v) => setState(() => _hasYard = v ?? true),
                    ),

                    // Outros pets
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Já possui outros animais em casa?'),
                      value: _hasOtherPets,
                      activeColor: Colors.purpleAccent,
                      onChanged: (v) =>
                          setState(() => _hasOtherPets = v ?? false),
                    ),

                    if (_hasOtherPets) ...[
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _otherPetsController,
                        decoration: _inputDecoration(
                          hint: 'Quais? Ex: 1 cão macho dócil e 1 gata',
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Concordância familiar
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Todos os moradores da casa concordam com a adoção?'),
                      value: _householdAgreement,
                      activeColor: Colors.purpleAccent,
                      onChanged: (v) =>
                          setState(() => _householdAgreement = v ?? true),
                    ),
                    const SizedBox(height: 14),

                    // Motivo
                    _buildLabel('POR QUE VOCÊ QUER ADOTAR O(A) ${animal.name.toUpperCase()}?'),
                    TextFormField(
                      controller: _reasonController,
                      maxLines: 3,
                      decoration: _inputDecoration(
                        hint: 'Conte um pouco sobre sua rotina e como será o novo lar...',
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botão Enviar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purpleAccent.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.favorite_rounded),
                        label: Text(
                          _isSubmitting ? 'Enviando...' : 'Enviar Ficha para a ONG',
                          style: const TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Fredoka',
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.purpleAccent,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required bool isDark,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: 12,
        color: isDark ? Colors.white38 : Colors.black38,
      ),
      filled: true,
      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? Colors.white10 : Colors.grey.shade300,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? Colors.white10 : Colors.grey.shade300,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.purpleAccent,
          width: 1.5,
        ),
      ),
    );
  }
}
