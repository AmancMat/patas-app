import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import '../models/shelter_animal_model.dart';
import '../services/shelter_service.dart';

class OngCreateAnimalSheet extends StatefulWidget {
  final String ongId;
  final ShelterAnimal? animalToEdit;

  const OngCreateAnimalSheet({
    super.key,
    required this.ongId,
    this.animalToEdit,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String ongId,
    ShelterAnimal? animalToEdit,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OngCreateAnimalSheet(
        ongId: ongId,
        animalToEdit: animalToEdit,
      ),
    );
  }

  @override
  State<OngCreateAnimalSheet> createState() => _OngCreateAnimalSheetState();
}

class _OngCreateAnimalSheetState extends State<OngCreateAnimalSheet> {
  final ShelterService _service = ShelterService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _breedController;
  late TextEditingController _ageController;
  late TextEditingController _rescueStoryController;
  late TextEditingController _behaviorController;
  late TextEditingController _specialNeedsController;

  String _selectedSpecies = 'canino';
  String _selectedGender = 'macho';
  String _selectedSize = 'medio';
  String _selectedStatus = 'disponivel';
  bool _isCastrated = false;
  bool _isVaccinated = false;
  bool _isDewormed = false;
  bool _isPublicAdoption = true;

  File? _pickedImage;
  String? _currentPhotoUrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final a = widget.animalToEdit;
    _nameController = TextEditingController(text: a?.name ?? '');
    _breedController = TextEditingController(text: a?.breed ?? 'SRD (Sem Raça Definida)');
    _ageController = TextEditingController(text: a?.ageEstimate ?? '');
    _rescueStoryController = TextEditingController(text: a?.rescueStory ?? '');
    _behaviorController = TextEditingController(text: a?.behaviorNotes ?? '');
    _specialNeedsController = TextEditingController(text: a?.specialNeeds ?? '');

    if (a != null) {
      _selectedSpecies = a.species;
      _selectedGender = a.gender;
      _selectedSize = a.size;
      _selectedStatus = a.status;
      _isCastrated = a.isCastrated;
      _isVaccinated = a.isVaccinated;
      _isDewormed = a.isDewormed;
      _isPublicAdoption = a.isPublicAdoption;
      _currentPhotoUrl = a.photoUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _rescueStoryController.dispose();
    _behaviorController.dispose();
    _specialNeedsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        _pickedImage = File(picked.path);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    String? photoUrl = _currentPhotoUrl;
    if (_pickedImage != null) {
      final uploaded = await _service.uploadAnimalPhoto(_pickedImage!, widget.ongId);
      if (uploaded != null) {
        photoUrl = uploaded;
      }
    }

    final isEdit = widget.animalToEdit != null;
    final animal = ShelterAnimal(
      id: isEdit ? widget.animalToEdit!.id : '',
      ongId: widget.ongId,
      name: _nameController.text.trim(),
      species: _selectedSpecies,
      breed: _breedController.text.trim().isEmpty
          ? 'SRD'
          : _breedController.text.trim(),
      gender: _selectedGender,
      size: _selectedSize,
      ageEstimate: _ageController.text.trim().isEmpty ? null : _ageController.text.trim(),
      rescueStory: _rescueStoryController.text.trim().isEmpty ? null : _rescueStoryController.text.trim(),
      behaviorNotes: _behaviorController.text.trim().isEmpty ? null : _behaviorController.text.trim(),
      specialNeeds: _specialNeedsController.text.trim().isEmpty ? null : _specialNeedsController.text.trim(),
      photoUrl: photoUrl,
      isCastrated: _isCastrated,
      isVaccinated: _isVaccinated,
      isDewormed: _isDewormed,
      status: _selectedStatus,
      isPublicAdoption: _isPublicAdoption,
      createdAt: isEdit ? widget.animalToEdit!.createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
    );

    bool success = false;
    if (isEdit) {
      success = await _service.updateShelterAnimal(animal);
    } else {
      final created = await _service.createShelterAnimal(animal);
      success = created != null;
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Falha ao salvar animal acolhido. Tente novamente.'),
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
    final isEdit = widget.animalToEdit != null;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          brightness: isDark ? Brightness.dark : Brightness.light,
          textTheme: Theme.of(context).textTheme.apply(
            bodyColor: isDark ? Colors.white : AppColors.darkBG,
            displayColor: isDark ? Colors.white : AppColors.darkBG,
          ),
          unselectedWidgetColor: isDark ? Colors.white60 : Colors.black54,
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
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purpleAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.volunteer_activism_rounded,
                        color: Colors.purpleAccent,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit ? 'Editar Acolhido' : 'Novo Animal Resgatado',
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.darkBG,
                          ),
                        ),
                        Text(
                          'Ficha do animal sob tutela da ONG',
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
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),

          // Formulário com Scroll
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Foto do Animal
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          children: [
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.purpleAccent.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                                image: _pickedImage != null
                                    ? DecorationImage(
                                        image: FileImage(_pickedImage!),
                                        fit: BoxFit.cover,
                                      )
                                    : (_currentPhotoUrl != null
                                        ? DecorationImage(
                                            image: NetworkImage(_currentPhotoUrl!),
                                            fit: BoxFit.cover,
                                          )
                                        : null),
                              ),
                              child: _pickedImage == null && _currentPhotoUrl == null
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_a_photo_rounded,
                                          size: 32,
                                          color: Colors.purpleAccent.withValues(alpha: 0.8),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Adicionar Foto',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.purpleAccent,
                                          ),
                                        ),
                                      ],
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.purpleAccent,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 2. Nome do Animal
                    _buildLabel('NOME DO PET *', isDark: isDark),
                    TextFormField(
                      controller: _nameController,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isDark ? Colors.white : AppColors.darkBG,
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Informe o nome do pet' : null,
                      decoration: _inputDecoration(
                        hint: 'Ex: Caramelo, Pipoca, Luna...',
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 3. Espécie e Gênero
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('ESPÉCIE', isDark: isDark),
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue: _selectedSpecies,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white : AppColors.darkBG,
                                ),
                                iconEnabledColor: isDark ? Colors.white70 : Colors.black54,
                                decoration: _inputDecoration(hint: '', isDark: isDark),
                                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                items: [
                                  DropdownMenuItem(
                                    value: 'canino',
                                    child: Text(
                                      '🐶 Cachorro',
                                      style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'felino',
                                    child: Text(
                                      '🐱 Gato',
                                      style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'outro',
                                    child: Text(
                                      '🐾 Outro',
                                      style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedSpecies = val);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('GÊNERO', isDark: isDark),
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue: _selectedGender,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white : AppColors.darkBG,
                                ),
                                iconEnabledColor: isDark ? Colors.white70 : Colors.black54,
                                decoration: _inputDecoration(hint: '', isDark: isDark),
                                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                items: [
                                  DropdownMenuItem(
                                    value: 'macho',
                                    child: Text(
                                      'Macho',
                                      style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'femea',
                                    child: Text(
                                      'Fêmea',
                                      style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedGender = val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 4. Porte e Idade Estimada
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('PORTE', isDark: isDark),
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue: _selectedSize,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white : AppColors.darkBG,
                                ),
                                iconEnabledColor: isDark ? Colors.white70 : Colors.black54,
                                decoration: _inputDecoration(hint: '', isDark: isDark),
                                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                items: [
                                  DropdownMenuItem(
                                    value: 'pequeno',
                                    child: Text(
                                      'Pequeno (<10kg)',
                                      style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'medio',
                                    child: Text(
                                      'Médio (11-25kg)',
                                      style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'grande',
                                    child: Text(
                                      'Grande (>25kg)',
                                      style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedSize = val);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('IDADE APROX.', isDark: isDark),
                              TextFormField(
                                controller: _ageController,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: isDark ? Colors.white : AppColors.darkBG,
                                ),
                                decoration: _inputDecoration(
                                  hint: 'Ex: 2 anos, Filhote...',
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 5. Raça / Pelagem
                    _buildLabel('RAÇA / MESTIÇO', isDark: isDark),
                    TextFormField(
                      controller: _breedController,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isDark ? Colors.white : AppColors.darkBG,
                      ),
                      decoration: _inputDecoration(
                        hint: 'Ex: SRD / Vira-lata, Mestiço Poodle...',
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 6. Status no Abrigo
                    _buildLabel('STATUS ATUAL NO ABRIGO', isDark: isDark),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _selectedStatus,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white : AppColors.darkBG,
                      ),
                      iconEnabledColor: isDark ? Colors.white70 : Colors.black54,
                      decoration: _inputDecoration(hint: '', isDark: isDark),
                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      items: [
                        DropdownMenuItem(
                          value: 'disponivel',
                          child: Text(
                            '✅ Disponível para Adoção',
                            style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'em_tratamento',
                          child: Text(
                            '🏥 Em Tratamento Médico',
                            style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'lar_temporario',
                          child: Text(
                            '🏠 Em Lar Temporário (LT)',
                            style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'adotado',
                          child: Text(
                            '🎉 Já Adotado (Histórico)',
                            style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedStatus = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    // 7. Checkboxes de Cuidados Preventivos
                    _buildLabel('CUIDADOS VETERINÁRIOS', isDark: isDark),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white10 : Colors.grey.shade200,
                        ),
                      ),
                      child: Column(
                        children: [
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Castrado(a)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : AppColors.darkBG,
                              ),
                            ),
                            subtitle: Text(
                              'Cirurgia de esterilização concluída',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                            value: _isCastrated,
                            activeColor: Colors.purpleAccent,
                            checkColor: Colors.white,
                            onChanged: (v) => setState(() => _isCastrated = v ?? false),
                          ),
                          Divider(
                            height: 1,
                            color: isDark ? Colors.white10 : Colors.grey.shade200,
                          ),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Vacinado(a)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : AppColors.darkBG,
                              ),
                            ),
                            subtitle: Text(
                              'V8/V10 ou Antirrábica aplicadas',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                            value: _isVaccinated,
                            activeColor: Colors.purpleAccent,
                            checkColor: Colors.white,
                            onChanged: (v) => setState(() => _isVaccinated = v ?? false),
                          ),
                          Divider(
                            height: 1,
                            color: isDark ? Colors.white10 : Colors.grey.shade200,
                          ),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Vermifugado / Antipulgas em dia',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : AppColors.darkBG,
                              ),
                            ),
                            subtitle: Text(
                              'Proteção contra parasitas em dia',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                            value: _isDewormed,
                            activeColor: Colors.purpleAccent,
                            checkColor: Colors.white,
                            onChanged: (v) => setState(() => _isDewormed = v ?? false),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 8. Visibilidade Pública
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Exibir no "Adote um Pet" dos Tutores',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isDark ? Colors.white : AppColors.darkBG,
                        ),
                      ),
                      subtitle: Text(
                        'Permite que tutores da região vejam e enviem pedidos de adoção',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      value: _isPublicAdoption,
                      activeTrackColor: Colors.purpleAccent,
                      onChanged: (v) => setState(() => _isPublicAdoption = v),
                    ),
                    const SizedBox(height: 14),

                    // 9. História do Resgate
                    _buildLabel('HISTÓRIA DO RESGATE (OPCIONAL)', isDark: isDark),
                    TextFormField(
                      controller: _rescueStoryController,
                      maxLines: 3,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isDark ? Colors.white : AppColors.darkBG,
                      ),
                      decoration: _inputDecoration(
                        hint: 'Conte como ele foi resgatado e sua jornada até o abrigo...',
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 10. Comportamento e Temperamento
                    _buildLabel('TEMPERAMENTO & CONVIVÊNCIA', isDark: isDark),
                    TextFormField(
                      controller: _behaviorController,
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isDark ? Colors.white : AppColors.darkBG,
                      ),
                      decoration: _inputDecoration(
                        hint: 'Ex: Dócil, amigável com gatos, calmo em apartamento...',
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botão Salvar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purpleAccent.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.check_rounded),
                        label: Text(
                          _isSaving ? 'Salvando...' : (isEdit ? 'Salvar Alterações' : 'Cadastrar Animal'),
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
    ),
  );
}

  Widget _buildLabel(String text, {required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Fredoka',
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isDark ? const Color(0xFFC084FC) : const Color(0xFF7E22CE),
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
