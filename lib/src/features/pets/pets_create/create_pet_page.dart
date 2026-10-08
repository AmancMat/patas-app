import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:patas_web_app/src/constants/routes.dart';
import 'package:patas_web_app/src/features/pets/active_pet_provider.dart';
import 'package:patas_web_app/src/features/pets/models/pet_model.dart';
import 'package:patas_web_app/src/features/pets/services/pet_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../main.dart'; // Importando o cliente Supabase globalmente
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/features/pets/pets_create/add_canine_race_page.dart';
import 'package:patas_web_app/src/features/pets/pets_create/add_feline_race_page.dart';
import 'package:patas_web_app/src/features/pets/pets_create/widgets/species_selector_dialog.dart';
import 'package:patas_web_app/core/localization/app_localizations.dart';
import 'package:patas_web_app/src/common_widgets/patas_essencial_app_bar.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';
import 'package:provider/provider.dart';

class CreatePetPage extends StatefulWidget {
  final String species;
  final bool isFirstProfile;

  const CreatePetPage({
    super.key,
    required this.species,
    this.isFirstProfile = false,
  });

  @override
  CreatePetPageState createState() => CreatePetPageState();
}

class CreatePetPageState extends State<CreatePetPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _colorController = TextEditingController();
  final _birthPlaceController = TextEditingController();
  final _currentCityController = TextEditingController();
  final _weightController = TextEditingController();
  final _bloodTypeController = TextEditingController();

  // Controllers específicos para novas espécies
  final _anilhaController = TextEditingController();
  final _ibamaController = TextEditingController();
  String? _selectedDiet = 'Herbívoro';

  DateTime? _birthDate;
  String? _selectedGender;
  String? _selectedSize;

  File? _image;
  File? _coverImage;
  final ImagePicker _picker = ImagePicker();

  final PetService _petService = PetService();
  bool _isLoading = false;

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

  Future<void> _pickImage(ImageSource source, bool isProfileImage) async {
    final pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        if (isProfileImage) {
          _image = File(pickedFile.path);
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
              title: Text(context.tr('pet_create.gallery')),
              onTap: () {
                _pickImage(ImageSource.gallery, isProfileImage);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: Text(context.tr('pet_create.camera')),
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
    // Validação de campos obrigatórios adaptada por espécie
    bool hasImage = _image != null;
    bool hasName = _nameController.text.isNotEmpty;
    bool hasGender = _selectedGender != null;
    bool hasBirthDate = _birthDate != null;

    bool isTraditional = widget.species == 'canino' || widget.species == 'felino';
    bool hasSize = isTraditional ? _selectedSize != null : true; // Outros são pré-definidos
    bool hasColor = widget.species == 'exotico' ? true : _colorController.text.isNotEmpty;

    if (!hasImage || !hasName || !hasGender || !hasSize || !hasColor || !hasBirthDate) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.tr('pet_create.required_fields_title')),
          content: Text(context.tr('pet_create.required_fields_desc')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.tr('common.confirm')),
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

      User? user = supabase.auth.currentUser;
      if (user == null && supabase.auth.currentSession != null) {
        user = supabase.auth.currentSession!.user;
      }

      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(context.tr('pet_create.user_not_identified'))),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      String? photoUrl;
      String? coverUrl;

      try {
        if (_image != null) {
          photoUrl = await _petService.uploadPetImage(_image!);
        }
        if (_coverImage != null) {
          coverUrl = await _petService.uploadPetCover(_coverImage!);
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('pet_create.upload_error', {'error': e.toString()}))),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Mapeamento condicional de campos para persistência sem alterar o banco
      String? finalBreed = _breedController.text;
      String? finalColor = _colorController.text;
      String? finalBloodType = _bloodTypeController.text;
      String? finalSize = _selectedSize;

      if (widget.species == 'ave') {
        finalColor = _anilhaController.text.isNotEmpty ? 'Anilha: ${_anilhaController.text}' : 'Sem anilha';
        finalSize = 'Pequeno';
        finalBloodType = 'Não aplicável';
      } else if (widget.species == 'roedor') {
        finalSize = 'Pequeno';
        finalBloodType = 'Não aplicável';
      } else if (widget.species == 'exotico') {
        finalColor = _ibamaController.text.isNotEmpty ? 'IBAMA: ${_ibamaController.text}' : 'Sem registro';
        finalSize = _selectedSize ?? 'Pequeno';
        finalBloodType = _selectedDiet ?? 'Desconhecido';
      }

      final newPet = Pet(
        id: '',
        userId: user.id,
        name: _nameController.text,
        species: widget.species,
        breed: finalBreed,
        birthDate: _birthDate,
        photoUrl: photoUrl,
        coverUrl: coverUrl,
        createdAt: DateTime.now(),
        gender: _selectedGender,
        size: finalSize,
        color: finalColor,
        birthPlace: _birthPlaceController.text,
        currentCity: _currentCityController.text,
        weight: double.tryParse(_weightController.text),
        bloodType: finalBloodType,
      );

      try {
        await _petService.createPet(newPet);
        if (!mounted) return;

        await context.read<ActivePetProvider>().initialize();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pet criado com sucesso!')),
        );

        // Se é o primeiro pet, vai para o questionário de interesses
        // Se é um pet adicional, vai direto para a home
        if (widget.isFirstProfile) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            NamedRoute.interestsQuestionnaire,
            (route) => false,
          );
        } else {
          Navigator.pushNamedAndRemoveUntil(
            context,
            NamedRoute.home,
            (route) => false,
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar o pet: $e')),
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

  String _getAppBarTitle(BuildContext context) {
    switch (widget.species) {
      case 'canino':
        return context.tr('pet_create.title_dog');
      case 'felino':
        return context.tr('pet_create.title_cat');
      case 'ave':
        return context.tr('pet_create.title_bird');
      case 'roedor':
        return context.tr('pet_create.title_rodent');
      case 'exotico':
        return context.tr('pet_create.title_exotic');
      default:
        return context.tr('pet_create.title');
    }
  }

  List<Map<String, String>> _getBloodTypeOptions(BuildContext context) {
    if (widget.species == 'canino') {
      return [
        {'id': 'unknown', 'label': context.tr('pet_create.blood_unknown')},
        {'id': 'DEA 1.1 (+)', 'label': 'DEA 1.1 (+)'},
        {'id': 'DEA 1.1 (-)', 'label': 'DEA 1.1 (-)'},
        {'id': 'DEA 3', 'label': 'DEA 3'},
        {'id': 'DEA 4', 'label': 'DEA 4'},
        {'id': 'DEA 5', 'label': 'DEA 5'},
        {'id': 'DEA 7', 'label': 'DEA 7'},
        {'id': 'Dal', 'label': 'Dal'},
      ];
    } else {
      return [
        {'id': 'unknown', 'label': context.tr('pet_create.blood_unknown')},
        {'id': 'Tipo A', 'label': context.tr('pet_create.blood_type_a')},
        {'id': 'Tipo B', 'label': context.tr('pet_create.blood_type_b')},
        {'id': 'Tipo AB', 'label': context.tr('pet_create.blood_type_ab')},
      ];
    }
  }

  Widget _buildSelectedItem(String label, Color textColor) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  List<String> _getBirdSpeciesList(BuildContext context) {
    if (context.isEn) {
      return const [
        'Cockatiel',
        'Canary',
        'Parrot',
        'Parakeet / Budgie',
        'Monk Parakeet',
        'Lovebird',
        'Zebra Finch',
        'Java Sparrow',
        'Chestnut-bellied Seed-Finch',
        'Double-collared Seedeater',
        'Cockatoo',
        'Green-winged Saltator',
      ];
    }
    return const [
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
    ];
  }

  List<String> _getRodentSpeciesList(BuildContext context) {
    if (context.isEn) {
      return const [
        'Syrian Hamster',
        'Russian Dwarf Hamster',
        'Guinea Pig',
        'Chinchilla',
        'Rabbit (Lagomorph)',
        'Fancy Rat / Twister',
        'Mongolian Gerbil',
      ];
    }
    return const [
      'Hamster Sírio',
      'Hamster Anão Russo',
      'Porquinho da Índia',
      'Chinchila',
      'Coelho (Lagomorfo)',
      'Twister / Rato',
      'Gerbil / Esquilo da Mongólia',
    ];
  }

  List<String> _getExoticSpeciesList(BuildContext context) {
    if (context.isEn) {
      return const [
        'Red-footed Tortoise',
        'Red-eared Slider (Turtle)',
        'Green Iguana',
        'Bearded Dragon',
        'Boa Constrictor',
        'Corn Snake',
        'Leopard Gecko',
        'Ferret',
        'Mini Pig',
      ];
    }
    return const [
      'Jabuti',
      'Tigre d\'Água (Tartaruga)',
      'Iguana Verde',
      'Dragão Barbudo (Pogona)',
      'Jiboia',
      'Cobra Corn Snake',
      'Geco (Gecko Leopard)',
      'Furão (Ferret)',
      'Mini Pig',
    ];
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
        title: _getAppBarTitle(context),
        subtitle: context.tr('pet_create.subtitle'),
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
                    // Foto de Capa
                    Semantics(
                      button: true,
                      label: 'Adicionar foto de capa do pet',
                      child: GestureDetector(
                        onTap: () => _showImageSourceActionSheet(false),
                        child: Container(
                          height: 150,
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(15),
                            image: _coverImage != null
                                ? DecorationImage(
                                    image: kIsWeb
                                        ? NetworkImage(_coverImage!.path) as ImageProvider
                                        : FileImage(_coverImage!) as ImageProvider,
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _coverImage == null
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_photo_alternate,
                                        size: 40,
                                        color: thmode.darkMode
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade600,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        context.tr('pet_create.cover_photo'),
                                        style: TextStyle(
                                          color: textColor.withValues(alpha: 0.6),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Foto de Perfil
                    Center(
                      child: Semantics(
                        button: true,
                        label: 'Adicionar foto de perfil do pet',
                        child: GestureDetector(
                          onTap: () => _showImageSourceActionSheet(true),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: thmode.darkMode
                                ? Colors.grey.shade800
                                : Colors.grey.shade300,
                            backgroundImage: _image != null
                                ? (kIsWeb
                                    ? NetworkImage(_image!.path) as ImageProvider
                                    : FileImage(_image!) as ImageProvider)
                                : null,
                            child: _image == null
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
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        context.tr('pet_create.profile_photo'),
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildLabel(context.tr('pet_create.name'), textColor),
                    const SizedBox(height: 8),
                    TextFormField(
                      style: TextStyle(color: textColor),
                      controller: _nameController,
                      decoration: _buildInputDecoration(
                        hint: context.tr('pet_create.name_hint'),
                        cardColor: cardColor,
                        textColor: textColor,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.tr('pet_create.name_error');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Campos Dinâmicos por Espécie
                    _buildDynamicFields(textColor, cardColor, thmode),

                    const SizedBox(height: 24),
                    _buildLabel(context.tr('pet_create.birth_date'), textColor),
                    const SizedBox(height: 8),
                    Semantics(
                      button: true,
                      label: context.tr('pet_create.birth_date'),
                      child: InkWell(
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
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
                                    ? context.tr('pet_create.click_to_select')
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
                            child: Text(context.tr('pet_create.save_profile'),
                                style: const TextStyle(fontSize: 16, color: Colors.white)),
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

  // Seletor dinâmico de campos com base na espécie selecionada
  Widget _buildDynamicFields(Color textColor, Color cardColor, DarkMode thmode) {
    switch (widget.species) {
      case 'canino':
      case 'felino':
        return _buildCanineFelineFields(textColor, cardColor, thmode);
      case 'ave':
        return _buildBirdFields(textColor, cardColor, thmode);
      case 'roedor':
        return _buildRodentFields(textColor, cardColor, thmode);
      case 'exotico':
        return _buildExoticFields(textColor, cardColor, thmode);
      default:
        return Container();
    }
  }

  // 1. CAMPOS DE CÃO E GATO (Tradicionais)
  Widget _buildCanineFelineFields(Color textColor, Color cardColor, DarkMode thmode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(context.tr('pet_create.gender'), textColor),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedGender,
          hint: Text(
            context.tr('pet_create.gender_hint'),
            style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 14),
          ),
          decoration: _buildInputDecoration(
            hint: context.tr('pet_create.gender_hint'),
            cardColor: cardColor,
            textColor: textColor,
          ),
          dropdownColor:
              thmode.darkMode ? const Color(0xFF1E293B) : Colors.white,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: textColor.withValues(alpha: 0.7),
          ),
          style: TextStyle(color: textColor, fontSize: 14),
          selectedItemBuilder: (context) => [
            _buildSelectedItem(context.tr('pet_create.gender_male'), textColor),
            _buildSelectedItem(context.tr('pet_create.gender_female'), textColor),
          ],
          items: [
            DropdownMenuItem<String>(
              value: 'Macho',
              child: Text(
                context.tr('pet_create.gender_male'),
                style: TextStyle(color: textColor, fontSize: 14),
              ),
            ),
            DropdownMenuItem<String>(
              value: 'Fêmea',
              child: Text(
                context.tr('pet_create.gender_female'),
                style: TextStyle(color: textColor, fontSize: 14),
              ),
            ),
          ],
          onChanged: (newValue) {
            setState(() {
              _selectedGender = newValue;
            });
          },
        ),
        const SizedBox(height: 24),
        _buildLabel(context.tr('pet_create.size'), textColor),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedSize,
          hint: Text(
            context.tr('pet_create.size_hint'),
            style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 14),
          ),
          decoration: _buildInputDecoration(
            hint: context.tr('pet_create.size_hint'),
            cardColor: cardColor,
            textColor: textColor,
          ),
          dropdownColor:
              thmode.darkMode ? const Color(0xFF1E293B) : Colors.white,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: textColor.withValues(alpha: 0.7),
          ),
          style: TextStyle(color: textColor, fontSize: 14),
          selectedItemBuilder: (context) => [
            _buildSelectedItem(context.tr('pet_create.size_small'), textColor),
            _buildSelectedItem(context.tr('pet_create.size_medium'), textColor),
            _buildSelectedItem(context.tr('pet_create.size_large'), textColor),
          ],
          items: [
            DropdownMenuItem<String>(
              value: 'Pequeno',
              child: Text(
                context.tr('pet_create.size_small'),
                style: TextStyle(color: textColor, fontSize: 14),
              ),
            ),
            DropdownMenuItem<String>(
              value: 'Médio',
              child: Text(
                context.tr('pet_create.size_medium'),
                style: TextStyle(color: textColor, fontSize: 14),
              ),
            ),
            DropdownMenuItem<String>(
              value: 'Grande',
              child: Text(
                context.tr('pet_create.size_large'),
                style: TextStyle(color: textColor, fontSize: 14),
              ),
            ),
          ],
          onChanged: (newValue) {
            setState(() {
              _selectedSize = newValue;
            });
          },
        ),
        const SizedBox(height: 24),
        _buildLabel(context.tr('pet_create.breed'), textColor),
        const SizedBox(height: 8),
        TextFormField(
          style: TextStyle(color: textColor),
          controller: _breedController,
          readOnly: true,
          onTap: () async {
            final String? selectedBreed = await Navigator.push<String>(
              context,
              MaterialPageRoute(
                builder: (context) => widget.species == 'canino'
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
            hint: context.tr('pet_create.breed_hint'),
            cardColor: cardColor,
            textColor: textColor,
          ).copyWith(
            suffixIcon: Icon(Icons.arrow_forward_ios,
                size: 16, color: textColor.withValues(alpha: 0.4)),
          ),
        ),
        const SizedBox(height: 24),
        _buildLabel(context.tr('pet_create.birth_place'), textColor),
        const SizedBox(height: 8),
        TextFormField(
          style: TextStyle(color: textColor),
          controller: _birthPlaceController,
          decoration: _buildInputDecoration(
            hint: context.tr('pet_create.birth_place_hint'),
            cardColor: cardColor,
            textColor: textColor,
          ),
        ),
        const SizedBox(height: 24),
        _buildLabel(context.tr('pet_create.current_city'), textColor),
        const SizedBox(height: 8),
        TextFormField(
          style: TextStyle(color: textColor),
          controller: _currentCityController,
          decoration: _buildInputDecoration(
            hint: context.tr('pet_create.current_city_hint'),
            cardColor: cardColor,
            textColor: textColor,
          ),
        ),
        const SizedBox(height: 24),
        _buildLabel(context.tr('pet_create.color'), textColor),
        const SizedBox(height: 8),
        TextFormField(
          style: TextStyle(color: textColor),
          controller: _colorController,
          decoration: _buildInputDecoration(
            hint: context.tr('pet_create.color_hint'),
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
                  _buildLabel(context.tr('pet_create.weight'), textColor),
                  const SizedBox(height: 8),
                  TextFormField(
                    style: TextStyle(color: textColor),
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: _buildInputDecoration(
                      hint: context.tr('pet_create.weight_hint'),
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
                  _buildLabel(context.tr('pet_create.blood_type'), textColor),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: (_bloodTypeController.text.isEmpty ||
                            _bloodTypeController.text == 'Desconhecido' ||
                            _bloodTypeController.text == 'Unknown' ||
                            _bloodTypeController.text == 'unknown')
                        ? 'unknown'
                        : _bloodTypeController.text,
                    hint: Text(
                      context.tr('pet_create.blood_type_hint'),
                      style: TextStyle(
                          color: textColor.withValues(alpha: 0.5), fontSize: 14),
                    ),
                    decoration: _buildInputDecoration(
                      hint: context.tr('pet_create.blood_type_hint'),
                      cardColor: cardColor,
                      textColor: textColor,
                    ),
                    dropdownColor: thmode.darkMode
                        ? const Color(0xFF1E293B)
                        : Colors.white,
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: textColor.withValues(alpha: 0.7),
                    ),
                    style: TextStyle(color: textColor, fontSize: 14),
                    selectedItemBuilder: (context) {
                      return _getBloodTypeOptions(context).map((opt) {
                        return _buildSelectedItem(opt['label']!, textColor);
                      }).toList();
                    },
                    items: _getBloodTypeOptions(context).map((opt) {
                      return DropdownMenuItem<String>(
                        value: opt['id'],
                        child: Text(
                          opt['label']!,
                          style: TextStyle(color: textColor, fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _bloodTypeController.text = (newValue == 'unknown')
                            ? 'Desconhecido'
                            : (newValue ?? '');
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

  // 2. CAMPOS DE AVE
  Widget _buildBirdFields(Color textColor, Color cardColor, DarkMode thmode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(context.tr('pet_create.gender'), textColor),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedGender,
          hint: Text(
            context.tr('pet_create.gender_hint'),
            style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 14),
          ),
          decoration: _buildInputDecoration(
            hint: context.tr('pet_create.gender_hint'),
            cardColor: cardColor,
            textColor: textColor,
          ),
          dropdownColor:
              thmode.darkMode ? const Color(0xFF1E293B) : Colors.white,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: textColor.withValues(alpha: 0.7),
          ),
          style: TextStyle(color: textColor, fontSize: 14),
          selectedItemBuilder: (context) => [
            _buildSelectedItem(context.tr('pet_create.gender_male'), textColor),
            _buildSelectedItem(context.tr('pet_create.gender_female'), textColor),
            _buildSelectedItem(context.tr('pet_create.gender_pending'), textColor),
          ],
          items: [
            DropdownMenuItem<String>(
              value: 'Macho',
              child: Text(
                context.tr('pet_create.gender_male'),
                style: TextStyle(color: textColor, fontSize: 14),
              ),
            ),
            DropdownMenuItem<String>(
              value: 'Fêmea',
              child: Text(
                context.tr('pet_create.gender_female'),
                style: TextStyle(color: textColor, fontSize: 14),
              ),
            ),
            DropdownMenuItem<String>(
              value: 'Pendente (Não sexado/DNA)',
              child: Text(
                context.tr('pet_create.gender_pending'),
                style: TextStyle(color: textColor, fontSize: 14),
              ),
            ),
          ],
          onChanged: (newValue) {
            setState(() {
              _selectedGender = newValue;
            });
          },
        ),
        const SizedBox(height: 24),
        _buildLabel(context.tr('pet_create.species_bird'), textColor),
        const SizedBox(height: 8),
        TextFormField(
          style: TextStyle(color: textColor),
          controller: _breedController,
          readOnly: true,
          onTap: () async {
            final String? selected = await showDialog<String>(
              context: context,
              builder: (context) => SpeciesSelectorDialog(
                title: context.tr('pet_create.species_bird').replaceAll('*', '').trim(),
                popularSpecies: _getBirdSpeciesList(context),
                itemIcon: Icons.flutter_dash,
              ),
            );
            if (selected != null) {
              setState(() {
                _breedController.text = selected;
              });
            }
          },
          decoration: _buildInputDecoration(
            hint: context.tr('pet_create.touch_select_species'),
            cardColor: cardColor,
            textColor: textColor,
          ).copyWith(
            suffixIcon: Icon(Icons.arrow_forward_ios,
                size: 16, color: textColor.withValues(alpha: 0.4)),
          ),
        ),
        const SizedBox(height: 24),
        _buildLabel(context.tr('pet_create.bird_ring'), textColor),
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
        _buildLabel(context.tr('pet_create.color'), textColor),
        const SizedBox(height: 8),
        TextFormField(
          style: TextStyle(color: textColor),
          controller: _colorController,
          decoration: _buildInputDecoration(
            hint: context.tr('pet_create.color_hint'),
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
                  _buildLabel(context.tr('pet_create.weight_g'), textColor),
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
                  _buildLabel(context.tr('pet_create.current_city'), textColor),
                  const SizedBox(height: 8),
                  TextFormField(
                    style: TextStyle(color: textColor),
                    controller: _currentCityController,
                    decoration: _buildInputDecoration(
                      hint: context.tr('pet_create.current_city_hint'),
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

  // 3. CAMPOS DE ROEDOR
  Widget _buildRodentFields(Color textColor, Color cardColor, DarkMode thmode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(context.tr('pet_create.gender'), textColor),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedGender,
          hint: Text(
            context.tr('pet_create.gender_hint'),
            style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 14),
          ),
          decoration: _buildInputDecoration(
            hint: context.tr('pet_create.gender_hint'),
            cardColor: cardColor,
            textColor: textColor,
          ),
          dropdownColor:
              thmode.darkMode ? const Color(0xFF1E293B) : Colors.white,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: textColor.withValues(alpha: 0.7),
          ),
          style: TextStyle(color: textColor, fontSize: 14),
          selectedItemBuilder: (context) => [
            _buildSelectedItem(context.tr('pet_create.gender_male'), textColor),
            _buildSelectedItem(context.tr('pet_create.gender_female'), textColor),
          ],
          items: [
            DropdownMenuItem<String>(
              value: 'Macho',
              child: Text(
                context.tr('pet_create.gender_male'),
                style: TextStyle(color: textColor, fontSize: 14),
              ),
            ),
            DropdownMenuItem<String>(
              value: 'Fêmea',
              child: Text(
                context.tr('pet_create.gender_female'),
                style: TextStyle(color: textColor, fontSize: 14),
              ),
            ),
          ],
          onChanged: (newValue) {
            setState(() {
              _selectedGender = newValue;
            });
          },
        ),
        const SizedBox(height: 24),
        _buildLabel(context.tr('pet_create.species_rodent'), textColor),
        const SizedBox(height: 8),
        TextFormField(
          style: TextStyle(color: textColor),
          controller: _breedController,
          readOnly: true,
          onTap: () async {
            final String? selected = await showDialog<String>(
              context: context,
              builder: (context) => SpeciesSelectorDialog(
                title: context.tr('pet_create.species_rodent').replaceAll('*', '').trim(),
                popularSpecies: _getRodentSpeciesList(context),
                itemIcon: Icons.pets,
              ),
            );
            if (selected != null) {
              setState(() {
                _breedController.text = selected;
              });
            }
          },
          decoration: _buildInputDecoration(
            hint: context.tr('pet_create.touch_select_species'),
            cardColor: cardColor,
            textColor: textColor,
          ).copyWith(
            suffixIcon: Icon(Icons.arrow_forward_ios,
                size: 16, color: textColor.withValues(alpha: 0.4)),
          ),
        ),
        const SizedBox(height: 24),
        _buildLabel(context.tr('pet_create.color'), textColor),
        const SizedBox(height: 8),
        TextFormField(
          style: TextStyle(color: textColor),
          controller: _colorController,
          decoration: _buildInputDecoration(
            hint: context.tr('pet_create.color_hint'),
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
                  _buildLabel(context.tr('pet_create.weight_g'), textColor),
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
                  _buildLabel(context.tr('pet_create.current_city'), textColor),
                  const SizedBox(height: 8),
                  TextFormField(
                    style: TextStyle(color: textColor),
                    controller: _currentCityController,
                    decoration: _buildInputDecoration(
                      hint: context.tr('pet_create.current_city_hint'),
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

  // 4. CAMPOS DE EXÓTICO / RÉPTIL
  Widget _buildExoticFields(Color textColor, Color cardColor, DarkMode thmode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(context.tr('pet_create.gender'), textColor),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedGender,
          hint: Text(
            context.tr('pet_create.gender_hint'),
            style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 14),
          ),
          decoration: _buildInputDecoration(
            hint: context.tr('pet_create.gender_hint'),
            cardColor: cardColor,
            textColor: textColor,
          ),
          dropdownColor:
              thmode.darkMode ? const Color(0xFF1E293B) : Colors.white,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: textColor.withValues(alpha: 0.7),
          ),
          style: TextStyle(color: textColor, fontSize: 14),
          selectedItemBuilder: (context) => [
            _buildSelectedItem(context.tr('pet_create.gender_male'), textColor),
            _buildSelectedItem(context.tr('pet_create.gender_female'), textColor),
          ],
          items: [
            DropdownMenuItem<String>(
              value: 'Macho',
              child: Text(
                context.tr('pet_create.gender_male'),
                style: TextStyle(color: textColor, fontSize: 14),
              ),
            ),
            DropdownMenuItem<String>(
              value: 'Fêmea',
              child: Text(
                context.tr('pet_create.gender_female'),
                style: TextStyle(color: textColor, fontSize: 14),
              ),
            ),
          ],
          onChanged: (newValue) {
            setState(() {
              _selectedGender = newValue;
            });
          },
        ),
        const SizedBox(height: 24),
        _buildLabel(context.tr('pet_create.species_exotic'), textColor),
        const SizedBox(height: 8),
        TextFormField(
          style: TextStyle(color: textColor),
          controller: _breedController,
          readOnly: true,
          onTap: () async {
            final String? selected = await showDialog<String>(
              context: context,
              builder: (context) => SpeciesSelectorDialog(
                title: context.tr('pet_create.species_exotic').replaceAll('*', '').trim(),
                popularSpecies: _getExoticSpeciesList(context),
                itemIcon: Icons.pets,
              ),
            );
            if (selected != null) {
              setState(() {
                _breedController.text = selected;
              });
            }
          },
          decoration: _buildInputDecoration(
            hint: context.tr('pet_create.touch_select_species'),
            cardColor: cardColor,
            textColor: textColor,
          ).copyWith(
            suffixIcon: Icon(Icons.arrow_forward_ios,
                size: 16, color: textColor.withValues(alpha: 0.4)),
          ),
        ),
        const SizedBox(height: 24),
        _buildLabel(context.tr('pet_create.bird_ibama'), textColor),
        const SizedBox(height: 8),
        TextFormField(
          style: TextStyle(color: textColor),
          controller: _ibamaController,
          decoration: _buildInputDecoration(
            hint: context.tr('pet_create.ibama_hint'),
            cardColor: cardColor,
            textColor: textColor,
          ),
        ),
        const SizedBox(height: 24),
        _buildLabel(context.tr('pet_create.diet'), textColor),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedDiet,
          hint: Text(
            context.tr('pet_create.diet_hint'),
            style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 14),
          ),
          decoration: _buildInputDecoration(
            hint: context.tr('pet_create.diet_hint'),
            cardColor: cardColor,
            textColor: textColor,
          ),
          dropdownColor:
              thmode.darkMode ? const Color(0xFF1E293B) : Colors.white,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: textColor.withValues(alpha: 0.7),
          ),
          style: TextStyle(color: textColor, fontSize: 14),
          selectedItemBuilder: (context) => [
            _buildSelectedItem(context.tr('pet_create.herbivore'), textColor),
            _buildSelectedItem(context.tr('pet_create.carnivore'), textColor),
            _buildSelectedItem(context.tr('pet_create.omnivore'), textColor),
            _buildSelectedItem(context.tr('pet_create.insectivore'), textColor),
            _buildSelectedItem(context.tr('pet_create.diet_other'), textColor),
          ],
          items: [
            DropdownMenuItem<String>(
              value: 'Herbívoro',
              child: Text(
                context.tr('pet_create.herbivore'),
                style: TextStyle(color: textColor, fontSize: 14),
              ),
            ),
            DropdownMenuItem<String>(
              value: 'Carnívoro',
              child: Text(
                context.tr('pet_create.carnivore'),
                style: TextStyle(color: textColor, fontSize: 14),
              ),
            ),
            DropdownMenuItem<String>(
              value: 'Onívoro',
              child: Text(
                context.tr('pet_create.omnivore'),
                style: TextStyle(color: textColor, fontSize: 14),
              ),
            ),
            DropdownMenuItem<String>(
              value: 'Insetívoro',
              child: Text(
                context.tr('pet_create.insectivore'),
                style: TextStyle(color: textColor, fontSize: 14),
              ),
            ),
            DropdownMenuItem<String>(
              value: 'Outra',
              child: Text(
                context.tr('pet_create.diet_other'),
                style: TextStyle(color: textColor, fontSize: 14),
              ),
            ),
          ],
          onChanged: (newValue) {
            setState(() {
              _selectedDiet = newValue;
            });
          },
        ),
        const SizedBox(height: 24),
        _buildLabel(context.tr('pet_create.size'), textColor),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedSize,
          hint: Text(
            context.tr('pet_create.size_hint'),
            style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 14),
          ),
          decoration: _buildInputDecoration(
            hint: context.tr('pet_create.size_hint'),
            cardColor: cardColor,
            textColor: textColor,
          ),
          dropdownColor:
              thmode.darkMode ? const Color(0xFF1E293B) : Colors.white,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: textColor.withValues(alpha: 0.7),
          ),
          style: TextStyle(color: textColor, fontSize: 14),
          selectedItemBuilder: (context) => [
            _buildSelectedItem(context.tr('pet_create.size_small'), textColor),
            _buildSelectedItem(context.tr('pet_create.size_medium'), textColor),
            _buildSelectedItem(context.tr('pet_create.size_large'), textColor),
          ],
          items: [
            DropdownMenuItem<String>(
              value: 'Pequeno',
              child: Text(
                context.tr('pet_create.size_small'),
                style: TextStyle(color: textColor, fontSize: 14),
              ),
            ),
            DropdownMenuItem<String>(
              value: 'Médio',
              child: Text(
                context.tr('pet_create.size_medium'),
                style: TextStyle(color: textColor, fontSize: 14),
              ),
            ),
            DropdownMenuItem<String>(
              value: 'Grande',
              child: Text(
                context.tr('pet_create.size_large'),
                style: TextStyle(color: textColor, fontSize: 14),
              ),
            ),
          ],
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
                  _buildLabel(context.tr('pet_create.weight'), textColor),
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
                  _buildLabel(context.tr('pet_create.current_city'), textColor),
                  const SizedBox(height: 8),
                  TextFormField(
                    style: TextStyle(color: textColor),
                    controller: _currentCityController,
                    decoration: _buildInputDecoration(
                      hint: context.tr('pet_create.current_city_hint'),
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
          color: textColor.withValues(alpha: 0.6),
          fontSize: 13,
          fontWeight: FontWeight.bold),
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
