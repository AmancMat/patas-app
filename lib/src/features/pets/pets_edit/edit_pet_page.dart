import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:patas_web_app/src/features/pets/models/pet_model.dart';
import 'package:patas_web_app/src/features/pets/services/pet_service.dart';
import '../../../../main.dart'; // Importando o cliente Supabase globalmente
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/features/pets/pets_create/add_canine_race_page.dart';
import 'package:patas_web_app/src/features/pets/pets_create/add_feline_race_page.dart';
import 'package:patas_web_app/src/features/pets/pets_create/widgets/species_selector_dialog.dart';
import 'package:patas_web_app/src/common_widgets/patas_essencial_app_bar.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';
import 'package:provider/provider.dart';

class EditPetPage extends StatefulWidget {
  final Pet pet;

  const EditPetPage({super.key, required this.pet});

  @override
  EditPetPageState createState() => EditPetPageState();
}

class EditPetPageState extends State<EditPetPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _breedController;
  late TextEditingController _colorController;
  late TextEditingController _birthPlaceController;
  late TextEditingController _currentCityController;
  late TextEditingController _weightController;
  late TextEditingController _bloodTypeController;

  // Controllers específicos para novas espécies
  late TextEditingController _anilhaController;
  late TextEditingController _ibamaController;
  String? _selectedDiet = 'Herbívoro';

  DateTime? _birthDate;
  String? _selectedGender;
  String? _selectedSize;

  File? _image;
  final ImagePicker _picker = ImagePicker();

  final PetService _petService = PetService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.pet.name);
    _breedController = TextEditingController(text: widget.pet.breed);
    _birthPlaceController = TextEditingController(text: widget.pet.birthPlace);
    _currentCityController =
        TextEditingController(text: widget.pet.currentCity);
    _weightController =
        TextEditingController(text: widget.pet.weight?.toString());
    _birthDate = widget.pet.birthDate;
    _selectedGender = widget.pet.gender;
    _selectedSize = widget.pet.size;

    // Inicialização condicional baseada na espécie
    String rawColor = widget.pet.color ?? '';
    String rawBloodType = widget.pet.bloodType ?? '';

    if (widget.pet.species == 'ave') {
      _anilhaController = TextEditingController(
          text: rawColor.startsWith('Anilha: ') ? rawColor.replaceAll('Anilha: ', '') : '');
      _colorController = TextEditingController(text: '');
      _bloodTypeController = TextEditingController(text: 'Não aplicável');
      _ibamaController = TextEditingController();
    } else if (widget.pet.species == 'exotico') {
      _ibamaController = TextEditingController(
          text: rawColor.startsWith('IBAMA: ') ? rawColor.replaceAll('IBAMA: ', '') : '');
      _colorController = TextEditingController(text: '');
      _anilhaController = TextEditingController();
      _selectedDiet = ['Herbívoro', 'Carnívoro', 'Onívoro', 'Insetívoro', 'Outra'].contains(rawBloodType)
          ? rawBloodType
          : 'Herbívoro';
      _bloodTypeController = TextEditingController(text: _selectedDiet);
    } else {
      _colorController = TextEditingController(text: rawColor);
      _bloodTypeController = TextEditingController(text: rawBloodType);
      _anilhaController = TextEditingController();
      _ibamaController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _colorController.dispose();
    _birthPlaceController.dispose();
    _currentCityController.dispose();
    _weightController.dispose();
    _bloodTypeController.dispose();
    _anilhaController.dispose();
    _ibamaController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
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
    // Validação de campos obrigatórios adaptada por espécie
    final hasExistingImage =
        widget.pet.photoUrl != null && widget.pet.photoUrl!.isNotEmpty;
    bool hasImage = _image != null || hasExistingImage;
    bool hasName = _nameController.text.isNotEmpty;
    bool hasGender = _selectedGender != null;
    bool hasBirthDate = _birthDate != null;

    final sp = widget.pet.species.toLowerCase().trim();
    bool isTraditional = sp == 'canino' ||
        sp == 'felino' ||
        sp == 'cão' ||
        sp == 'cao' ||
        sp == 'cachorro' ||
        sp == 'gato';
    bool hasSize = isTraditional ? _selectedSize != null : true;
    bool hasColor = sp == 'exotico' ? true : _colorController.text.isNotEmpty;

    if (!hasImage || !hasName || !hasGender || !hasSize || !hasColor || !hasBirthDate) {
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

      final user = supabase.auth.currentUser;
      if (user == null) {
        return;
      }

      String? photoUrl = widget.pet.photoUrl;
      if (_image != null) {
        try {
          photoUrl = await _petService.uploadPetImage(_image!);
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro no upload da imagem: $e')),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      // Mapeamento condicional de campos para persistência
      String? finalBreed = _breedController.text;
      String? finalColor = _colorController.text;
      String? finalBloodType = _bloodTypeController.text;
      String? finalSize = _selectedSize;

      if (widget.pet.species == 'ave') {
        finalColor = _anilhaController.text.isNotEmpty ? 'Anilha: ${_anilhaController.text}' : 'Sem anilha';
        finalSize = 'Pequeno';
        finalBloodType = 'Não aplicável';
      } else if (widget.pet.species == 'roedor') {
        finalSize = 'Pequeno';
        finalBloodType = 'Não aplicável';
      } else if (widget.pet.species == 'exotico') {
        finalColor = _ibamaController.text.isNotEmpty ? 'IBAMA: ${_ibamaController.text}' : 'Sem registro';
        finalSize = _selectedSize ?? 'Pequeno';
        finalBloodType = _selectedDiet ?? 'Desconhecido';
      }

      final updatedPet = Pet(
        id: widget.pet.id,
        userId: user.id,
        name: _nameController.text,
        species: widget.pet.species,
        breed: finalBreed,
        birthDate: _birthDate,
        photoUrl: photoUrl,
        createdAt: widget.pet.createdAt,
        gender: _selectedGender,
        size: finalSize,
        color: finalColor,
        birthPlace: _birthPlaceController.text,
        currentCity: _currentCityController.text,
        weight: double.tryParse(_weightController.text),
        bloodType: finalBloodType,
        coverUrl: widget.pet.coverUrl,
        isLoveActive: widget.pet.isLoveActive,
      );

      try {
        await _petService.updatePet(updatedPet);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pet atualizado com sucesso!')),
        );
        Navigator.of(context).pop(true);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar o pet: $e')),
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

  ImageProvider? _getImageProvider() {
    if (_image != null) {
      return FileImage(_image!);
    }
    if (widget.pet.photoUrl != null && widget.pet.photoUrl!.isNotEmpty) {
      return NetworkImage(widget.pet.photoUrl!);
    }
    return null;
  }

  List<String> _getBloodTypeOptions() {
    if (widget.pet.species == 'canino') {
      return [
        'Desconhecido',
        'DEA 1.1 (+)',
        'DEA 1.1 (-)',
        'DEA 3',
        'DEA 4',
        'DEA 5',
        'DEA 7',
        'Dal'
      ];
    } else {
      return ['Desconhecido', 'Tipo A', 'Tipo B', 'Tipo AB'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final cardColor =
        thmode.darkMode ? Colors.white.withValues(alpha: 0.05) : Colors.white;
    final textColor = thmode.darkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: thmode.darkMode ? AppColors.darkBG : AppColors.bodyLight,
      appBar: PatasEssencialAppBar(
        title: 'Editar Perfil',
        subtitle: 'Atualize os dados de ${widget.pet.name}',
        leadingIcon: const Icon(
          Icons.pets_rounded,
          color: AppColors.patasColor,
          size: 22,
        ),
        showBackButton: true,
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
                    Center(
                      child: Semantics(
                        button: true,
                        label: 'Adicionar ou alterar foto de perfil do pet',
                        child: GestureDetector(
                          onTap: _showImageSourceActionSheet,
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: thmode.darkMode
                                ? Colors.grey.shade800
                                : Colors.grey.shade300,
                            backgroundImage: _getImageProvider(),
                            child: _getImageProvider() == null
                                ? Icon(Icons.camera_alt,
                                    size: 50,
                                    color: thmode.darkMode
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade600)
                                : null,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildLabel('Nome*', textColor),
                    const SizedBox(height: 8),
                    TextFormField(
                      style: TextStyle(color: textColor),
                      controller: _nameController,
                      decoration: _buildInputDecoration(
                        hint: 'Nome do pet',
                        cardColor: cardColor,
                        textColor: textColor,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira o nome do pet.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Campos dinâmicos por espécie
                    _buildDynamicFields(textColor, cardColor, thmode),

                    const SizedBox(height: 24),
                    _buildLabel('Data de Nascimento*', textColor),
                    const SizedBox(height: 8),
                    Semantics(
                      button: true,
                      label: 'Selecionar data de nascimento',
                      child: InkWell(
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: _birthDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              _birthDate = pickedDate;
                            });
                          }
                        },
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _birthDate == null
                                    ? 'Clique para selecionar'
                                    : '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}',
                                style: TextStyle(
                                  color: _birthDate == null
                                      ? textColor.withValues(alpha: 0.3)
                                      : textColor,
                                ),
                              ),
                              Icon(Icons.calendar_today,
                                  color: textColor.withValues(alpha: 0.4), size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
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
                            child: const Text('Salvar Alterações',
                                style: TextStyle(fontSize: 16, color: Colors.white)),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicFields(Color textColor, Color cardColor, DarkMode thmode) {
    final s = widget.pet.species.toLowerCase().trim();
    if (s == 'canino' ||
        s == 'felino' ||
        s == 'cão' ||
        s == 'cao' ||
        s == 'cachorro' ||
        s == 'gato') {
      return _buildCanineFelineFields(textColor, cardColor, thmode);
    }
    switch (s) {
      case 'ave':
        return _buildBirdFields(textColor, cardColor, thmode);
      case 'roedor':
        return _buildRodentFields(textColor, cardColor, thmode);
      case 'exotico':
        return _buildExoticFields(textColor, cardColor, thmode);
      default:
        return _buildCanineFelineFields(textColor, cardColor, thmode);
    }
  }

  Widget _buildCanineFelineFields(Color textColor, Color cardColor, DarkMode thmode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Gênero*', textColor),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedGender,
          decoration: _buildInputDecoration(
            hint: 'Selecione o gênero',
            cardColor: cardColor,
            textColor: textColor,
          ),
          dropdownColor:
              thmode.darkMode ? AppColors.darkBG : AppColors.bodyLight,
          style: TextStyle(
              color: thmode.darkMode ? Colors.white : Colors.black),
          items: ['Macho', 'Fêmea'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedGender = newValue;
            });
          },
        ),
        const SizedBox(height: 24),
        _buildLabel('Porte*', textColor),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedSize,
          decoration: _buildInputDecoration(
            hint: 'Selecione o porte',
            cardColor: cardColor,
            textColor: textColor,
          ),
          dropdownColor:
              thmode.darkMode ? AppColors.darkBG : AppColors.bodyLight,
          style: TextStyle(
              color: thmode.darkMode ? Colors.white : Colors.black),
          items: ['Pequeno', 'Médio', 'Grande'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedSize = newValue;
            });
          },
        ),
        const SizedBox(height: 24),
        _buildLabel('Raça', textColor),
        const SizedBox(height: 8),
        TextFormField(
          style: TextStyle(color: textColor),
          controller: _breedController,
          readOnly: true,
          onTap: () async {
            final String? selectedBreed = await Navigator.push<String>(
              context,
              MaterialPageRoute(
                builder: (context) => widget.pet.species == 'canino'
                    ? const AddCanineRacePage()
                    : const AddFelineRacePage(),
              ),
            );
            if (selectedBreed != null) {
              setState(() {
                _breedController.text = selectedBreed;
              });
            }
          },
          decoration: _buildInputDecoration(
            hint: 'Toque para selecionar a raça',
            cardColor: cardColor,
            textColor: textColor,
          ).copyWith(
            suffixIcon: Icon(Icons.arrow_forward_ios,
                size: 16, color: textColor.withValues(alpha: 0.4)),
          ),
        ),
        const SizedBox(height: 24),
        _buildLabel('Local de nascimento', textColor),
        const SizedBox(height: 8),
        TextFormField(
          style: TextStyle(color: textColor),
          controller: _birthPlaceController,
          decoration: _buildInputDecoration(
            hint: 'Onde nasceu',
            cardColor: cardColor,
            textColor: textColor,
          ),
        ),
        const SizedBox(height: 24),
        _buildLabel('Vive em:', textColor),
        const SizedBox(height: 8),
        TextFormField(
          style: TextStyle(color: textColor),
          controller: _currentCityController,
          decoration: _buildInputDecoration(
            hint: 'Cidade atual',
            cardColor: cardColor,
            textColor: textColor,
          ),
        ),
        const SizedBox(height: 24),
        _buildLabel('Cor*', textColor),
        const SizedBox(height: 8),
        TextFormField(
          style: TextStyle(color: textColor),
          controller: _colorController,
          decoration: _buildInputDecoration(
            hint: 'Cor predominante',
            cardColor: cardColor,
            textColor: textColor,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Peso (kg)', textColor),
                  const SizedBox(height: 8),
                  TextFormField(
                    style: TextStyle(color: textColor),
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: _buildInputDecoration(
                      hint: '0.0',
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
                  _buildLabel('Tipo Sanguíneo', textColor),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: (_bloodTypeController.text.isEmpty ||
                            !_getBloodTypeOptions()
                                .contains(_bloodTypeController.text))
                        ? 'Desconhecido'
                        : _bloodTypeController.text,
                    decoration: _buildInputDecoration(
                      hint: 'Tipo',
                      cardColor: cardColor,
                      textColor: textColor,
                    ),
                    dropdownColor: thmode.darkMode
                        ? AppColors.darkBG
                        : AppColors.bodyLight,
                    style: TextStyle(
                        color: thmode.darkMode
                            ? Colors.white
                            : Colors.black),
                    items: _getBloodTypeOptions().map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _bloodTypeController.text = newValue!;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBirdFields(Color textColor, Color cardColor, DarkMode thmode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Gênero*', textColor),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedGender,
          decoration: _buildInputDecoration(
            hint: 'Selecione o gênero',
            cardColor: cardColor,
            textColor: textColor,
          ),
          dropdownColor:
              thmode.darkMode ? AppColors.darkBG : AppColors.bodyLight,
          style: TextStyle(
              color: thmode.darkMode ? Colors.white : Colors.black),
          items: ['Macho', 'Fêmea', 'Pendente (Não sexado/DNA)'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedGender = newValue;
            });
          },
        ),
        const SizedBox(height: 24),
        _buildLabel('Espécie de Ave*', textColor),
        const SizedBox(height: 8),
        TextFormField(
          style: TextStyle(color: textColor),
          controller: _breedController,
          readOnly: true,
          onTap: () async {
            final String? selected = await showDialog<String>(
              context: context,
              builder: (context) => const SpeciesSelectorDialog(
                title: 'Espécie da Ave',
                popularSpecies: [
                  'Calopsita',
                  'Canário',
                  'Papagaio',
                  'Periquito',
                  'Caturrita',
                  'Agapornis',
                  'Mandarim',
                  'Calafate',
                  'Curió',
                  'Coleiro',
                  'Cacatua',
                  'Trinca-ferro',
                ],
              ),
            );
            if (selected != null) {
              setState(() {
                _breedController.text = selected;
              });
            }
          },
          decoration: _buildInputDecoration(
            hint: 'Toque para selecionar a espécie',
            cardColor: cardColor,
            textColor: textColor,
          ).copyWith(
            suffixIcon: Icon(Icons.arrow_forward_ios,
                size: 16, color: textColor.withValues(alpha: 0.4)),
          ),
        ),
        const SizedBox(height: 24),
        _buildLabel('Número da Anilha (Identificação)', textColor),
        const SizedBox(height: 8),
        TextFormField(
          style: TextStyle(color: textColor),
          controller: _anilhaController,
          decoration: _buildInputDecoration(
            hint: 'Ex: SISPASS 1234-56',
            cardColor: cardColor,
            textColor: textColor,
          ),
        ),
        const SizedBox(height: 24),
        _buildLabel('Cor Predominante*', textColor),
        const SizedBox(height: 8),
        TextFormField(
          style: TextStyle(color: textColor),
          controller: _colorController,
          decoration: _buildInputDecoration(
            hint: 'Ex: Amarelo, Verde, Cinza',
            cardColor: cardColor,
            textColor: textColor,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Peso (g)', textColor),
                  const SizedBox(height: 8),
                  TextFormField(
                    style: TextStyle(color: textColor),
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: _buildInputDecoration(
                      hint: 'Ex: 90',
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
                  _buildLabel('Vive em:', textColor),
                  const SizedBox(height: 8),
                  TextFormField(
                    style: TextStyle(color: textColor),
                    controller: _currentCityController,
                    decoration: _buildInputDecoration(
                      hint: 'Cidade atual',
                      cardColor: cardColor,
                      textColor: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRodentFields(Color textColor, Color cardColor, DarkMode thmode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Gênero*', textColor),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedGender,
          decoration: _buildInputDecoration(
            hint: 'Selecione o gênero',
            cardColor: cardColor,
            textColor: textColor,
          ),
          dropdownColor:
              thmode.darkMode ? AppColors.darkBG : AppColors.bodyLight,
          style: TextStyle(
              color: thmode.darkMode ? Colors.white : Colors.black),
          items: ['Macho', 'Fêmea'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedGender = newValue;
            });
          },
        ),
        const SizedBox(height: 24),
        _buildLabel('Espécie do Roedor*', textColor),
        const SizedBox(height: 8),
        TextFormField(
          style: TextStyle(color: textColor),
          controller: _breedController,
          readOnly: true,
          onTap: () async {
            final String? selected = await showDialog<String>(
              context: context,
              builder: (context) => const SpeciesSelectorDialog(
                title: 'Espécie do Roedor',
                popularSpecies: [
                  'Hamster Sírio',
                  'Hamster Anão Russo',
                  'Porquinho da Índia',
                  'Chinchila',
                  'Coelho (Lagomorfo)',
                  'Twister / Rato',
                  'Gerbil / Esquilo da Mongólia',
                ],
              ),
            );
            if (selected != null) {
              setState(() {
                _breedController.text = selected;
              });
            }
          },
          decoration: _buildInputDecoration(
            hint: 'Toque para selecionar a espécie',
            cardColor: cardColor,
            textColor: textColor,
          ).copyWith(
            suffixIcon: Icon(Icons.arrow_forward_ios,
                size: 16, color: textColor.withValues(alpha: 0.4)),
          ),
        ),
        const SizedBox(height: 24),
        _buildLabel('Cor Predominante*', textColor),
        const SizedBox(height: 8),
        TextFormField(
          style: TextStyle(color: textColor),
          controller: _colorController,
          decoration: _buildInputDecoration(
            hint: 'Ex: Dourado, Branco, Cinza',
            cardColor: cardColor,
            textColor: textColor,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Peso (g)', textColor),
                  const SizedBox(height: 8),
                  TextFormField(
                    style: TextStyle(color: textColor),
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: _buildInputDecoration(
                      hint: 'Ex: 120',
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
                  _buildLabel('Vive em:', textColor),
                  const SizedBox(height: 8),
                  TextFormField(
                    style: TextStyle(color: textColor),
                    controller: _currentCityController,
                    decoration: _buildInputDecoration(
                      hint: 'Cidade atual',
                      cardColor: cardColor,
                      textColor: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExoticFields(Color textColor, Color cardColor, DarkMode thmode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Gênero*', textColor),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedGender,
          decoration: _buildInputDecoration(
            hint: 'Selecione o gênero',
            cardColor: cardColor,
            textColor: textColor,
          ),
          dropdownColor:
              thmode.darkMode ? AppColors.darkBG : AppColors.bodyLight,
          style: TextStyle(
              color: thmode.darkMode ? Colors.white : Colors.black),
          items: ['Macho', 'Fêmea'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedGender = newValue;
            });
          },
        ),
        const SizedBox(height: 24),
        _buildLabel('Espécie*', textColor),
        const SizedBox(height: 8),
        TextFormField(
          style: TextStyle(color: textColor),
          controller: _breedController,
          readOnly: true,
          onTap: () async {
            final String? selected = await showDialog<String>(
              context: context,
              builder: (context) => const SpeciesSelectorDialog(
                title: 'Espécie Exótica / Réptil',
                popularSpecies: [
                  'Jabuti',
                  'Tigre d\'Água (Tartaruga)',
                  'Iguana Verde',
                  'Dragão Barbudo (Pogona)',
                  'Jiboia',
                  'Cobra Corn Snake',
                  'Geco (Gecko Leopard)',
                  'Furão (Ferret)',
                  'Mini Pig',
                ],
              ),
            );
            if (selected != null) {
              setState(() {
                _breedController.text = selected;
              });
            }
          },
          decoration: _buildInputDecoration(
            hint: 'Toque para selecionar a espécie',
            cardColor: cardColor,
            textColor: textColor,
          ).copyWith(
            suffixIcon: Icon(Icons.arrow_forward_ios,
                size: 16, color: textColor.withValues(alpha: 0.4)),
          ),
        ),
        const SizedBox(height: 24),
        _buildLabel('Autorização / Registro (IBAMA/SISMA)', textColor),
        const SizedBox(height: 8),
        TextFormField(
          style: TextStyle(color: textColor),
          controller: _ibamaController,
          decoration: _buildInputDecoration(
            hint: 'Número do registro de origem legal',
            cardColor: cardColor,
            textColor: textColor,
          ),
        ),
        const SizedBox(height: 24),
        _buildLabel('Alimentação / Dieta', textColor),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedDiet,
          decoration: _buildInputDecoration(
            hint: 'Selecione a dieta',
            cardColor: cardColor,
            textColor: textColor,
          ),
          dropdownColor:
              thmode.darkMode ? AppColors.darkBG : AppColors.bodyLight,
          style: TextStyle(
              color: thmode.darkMode ? Colors.white : Colors.black),
          items: ['Herbívoro', 'Carnívoro', 'Onívoro', 'Insetívoro', 'Outra'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedDiet = newValue;
            });
          },
        ),
        const SizedBox(height: 24),
        _buildLabel('Porte', textColor),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedSize,
          decoration: _buildInputDecoration(
            hint: 'Selecione o porte',
            cardColor: cardColor,
            textColor: textColor,
          ),
          dropdownColor:
              thmode.darkMode ? AppColors.darkBG : AppColors.bodyLight,
          style: TextStyle(
              color: thmode.darkMode ? Colors.white : Colors.black),
          items: ['Pequeno', 'Médio', 'Grande'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedSize = newValue;
            });
          },
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Peso (kg/g)', textColor),
                  const SizedBox(height: 8),
                  TextFormField(
                    style: TextStyle(color: textColor),
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: _buildInputDecoration(
                      hint: 'Ex: 1.5',
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
                  _buildLabel('Vive em:', textColor),
                  const SizedBox(height: 8),
                  TextFormField(
                    style: TextStyle(color: textColor),
                    controller: _currentCityController,
                    decoration: _buildInputDecoration(
                      hint: 'Cidade atual',
                      cardColor: cardColor,
                      textColor: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLabel(String label, Color textColor) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: 'Fredoka',
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
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
