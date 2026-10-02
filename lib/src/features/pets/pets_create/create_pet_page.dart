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
              title: const Text('Galeria'),
              onTap: () {
                _pickImage(ImageSource.gallery, isProfileImage);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Câmera'),
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

      User? user = supabase.auth.currentUser;
      if (user == null && supabase.auth.currentSession != null) {
        user = supabase.auth.currentSession!.user;
      }

      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Erro: Usuário não identificado. Tente fazer login novamente.')),
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
          SnackBar(content: Text('Erro no upload das imagens: $e')),
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

  String _getAppBarTitle() {
    switch (widget.species) {
      case 'canino':
        return 'Criar Perfil de Cachorro';
      case 'felino':
        return 'Criar Perfil de Gato';
      case 'ave':
        return 'Criar Perfil de Ave';
      case 'roedor':
        return 'Criar Perfil de Roedor';
      case 'exotico':
        return 'Criar Perfil de Exótico';
      default:
        return 'Criar Perfil de Pet';
    }
  }

  List<String> _getBloodTypeOptions() {
    if (widget.species == 'canino') {
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
        title: _getAppBarTitle(),
        subtitle: 'Preencha os dados do pet para criar o perfil',
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
                                        'Adicionar Foto de Capa',
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
                        'Foto de Perfil*',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.6),
                          fontSize: 12,
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

                    // Campos Dinâmicos por Espécie
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
                            child: const Text('Salvar Perfil',
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

  // 2. CAMPOS DE AVE
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

  // 3. CAMPOS DE ROEDOR
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

  // 4. CAMPOS DE EXÓTICO / RÉPTIL
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
