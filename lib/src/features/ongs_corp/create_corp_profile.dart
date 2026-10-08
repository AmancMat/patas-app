import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:patas_web_app/src/constants/routes.dart';
import 'package:patas_web_app/src/features/ongs_corp/models/corp_profile_model.dart';
import 'package:patas_web_app/src/features/ongs_corp/services/corp_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../main.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';
import 'package:patas_web_app/core/localization/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/src/providers/active_account_provider.dart';
import 'package:patas_web_app/src/models/active_account_model.dart';

class CreateCorpProfilePage extends StatefulWidget {
  const CreateCorpProfilePage({super.key});

  @override
  CreateCorpProfilePageState createState() => CreateCorpProfilePageState();
}

class CreateCorpProfilePageState extends State<CreateCorpProfilePage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers para campos de texto
  final _nameController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _openingHoursController = TextEditingController();
  final _workingDaysController = TextEditingController();
  final _aboutController = TextEditingController();

  // Categorias de empresas
  final List<String> _categories = [
    'Pet Shop',
    'Clínica Veterinária',
    'Hospital Veterinário',
    'Hotel para Pets',
    'Adestramento',
    'Banho e Tosa',
    'Passeador de Cães',
    'Loja Especializada',
    'Fabricante/Marca',
    'Outro',
  ];
  String? _selectedCategory;

  // Serviços oferecidos (multi-seleção)
  final List<String> _availableServices = [
    'Consultas',
    'Vacinas',
    'Cirurgias',
    'Exames',
    'Banho',
    'Tosa',
    'Hospedagem',
    'Adestramento',
    'Venda de Produtos',
    'Delivery',
  ];
  final List<String> _selectedServices = [];

  // Formas de Pagamento (multi-seleção)
  final List<String> _availablePaymentMethods = [
    'Dinheiro',
    'PIX',
    'Cartão de Crédito',
    'Cartão de Débito',
    'Boleto',
    'Transferência',
  ];
  final List<String> _selectedPaymentMethods = [];

  File? _profileImage;
  File? _coverImage;
  final ImagePicker _picker = ImagePicker();

  final CorpService _corpService = CorpService();
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source, bool isProfileImage) async {
    final pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        if (isProfileImage) {
          _profileImage = File(pickedFile.path);
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
    // Validação de campos obrigatórios
    if (_profileImage == null ||
        _nameController.text.isEmpty ||
        _cnpjController.text.isEmpty ||
        _selectedCategory == null ||
        _addressController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _emailController.text.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.tr('pet_create.required_fields_title')),
          content: Text(context.tr('pet_create.required_fields_desc')),
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
        // Upload da foto de perfil
        if (_profileImage != null) {
          photoUrl =
              await _corpService.uploadCorpImage(_profileImage!, user.id);
        }

        // Upload da foto de capa
        if (_coverImage != null) {
          coverUrl = await _corpService.uploadCorpCover(_coverImage!, user.id);
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

      final newCorp = CorpProfile(
        id: '',
        userId: user.id,
        name: _nameController.text,
        cnpj: _cnpjController.text,
        category: _selectedCategory!,
        address: _addressController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        website:
            _websiteController.text.isEmpty ? null : _websiteController.text,
        openingHours: _openingHoursController.text.isEmpty
            ? null
            : _openingHoursController.text,
        workingDays: _workingDaysController.text.isEmpty
            ? null
            : _workingDaysController.text,
        servicesOffered: _selectedServices.isEmpty ? null : _selectedServices,
        paymentMethods:
            _selectedPaymentMethods.isEmpty ? null : _selectedPaymentMethods,
        photoUrl: photoUrl,
        coverUrl: coverUrl,
        about: _aboutController.text.isEmpty ? null : _aboutController.text,
        createdAt: DateTime.now(),
      );

      try {
        await _corpService.createCorpProfile(newCorp);
        if (!mounted) return;

        final activeAccountProvider =
            Provider.of<ActiveAccountProvider>(context, listen: false);
        await activeAccountProvider.setActiveAccount(
          ActiveAccount(
            id: newCorp.id,
            name: newCorp.name,
            photoUrl: newCorp.photoUrl,
            type: AccountType.company,
          ),
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(context.tr('corp_create.success'))),
        );

        // Navega para a Home limpando todo o histórico
        Navigator.pushNamedAndRemoveUntil(
          context,
          NamedRoute.home,
          (route) => false,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('corp_create.create_error', {'error': e.toString()}))),
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

  @override
  void dispose() {
    _nameController.dispose();
    _cnpjController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _openingHoursController.dispose();
    _workingDaysController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final cardColor =
        thmode.darkMode ? Colors.white.withValues(alpha: 0.05) : Colors.white;
    final textColor = thmode.darkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: thmode.darkMode ? AppColors.darkBG : AppColors.bodyLight,
      appBar: AppBar(
        title: Text(context.tr('corp_create.title')),
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.patasColor,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        centerTitle: true,
        backgroundColor:
            thmode.darkMode ? AppColors.darkBG : AppColors.bodyLight,
        elevation: 0,
        foregroundColor: thmode.darkMode ? Colors.white : Colors.black,
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
              _buildCoverImagePicker(thmode, cardColor, textColor),
              const SizedBox(height: 16),

              // Foto de Perfil
              Center(
                child: Semantics(
                  button: true,
                  label: context.tr('corp_create.logo'),
                  child: GestureDetector(
                    onTap: () => _showImageSourceActionSheet(true),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: thmode.darkMode
                          ? Colors.grey.shade800
                          : Colors.grey.shade300,
                      backgroundImage: _profileImage != null
                          ? (kIsWeb
                              ? NetworkImage(_profileImage!.path) as ImageProvider
                              : FileImage(_profileImage!) as ImageProvider)
                          : null,
                      child: _profileImage == null
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
                  context.tr('corp_create.logo'),
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Seção: Informações Básicas
              _buildSectionHeader(context.tr('corp_create.basic_info'), textColor),
              const SizedBox(height: 16),

              _buildLabel(context.tr('corp_create.name'), textColor),
              const SizedBox(height: 8),
              TextFormField(
                style: TextStyle(color: textColor),
                controller: _nameController,
                decoration: _buildInputDecoration(
                  hint: context.tr('corp_create.name_hint'),
                  cardColor: cardColor,
                  textColor: textColor,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.tr('corp_create.name_error');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildLabel(context.tr('corp_create.cnpj'), textColor),
              const SizedBox(height: 8),
              TextFormField(
                style: TextStyle(color: textColor),
                controller: _cnpjController,
                keyboardType: TextInputType.number,
                decoration: _buildInputDecoration(
                  hint: '00.000.000/0000-00',
                  cardColor: cardColor,
                  textColor: textColor,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.tr('corp_create.cnpj_error');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildLabel(context.tr('corp_create.category'), textColor),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                hint: Text(
                  context.tr('corp_create.category_hint'),
                  style: TextStyle(
                      color: textColor.withValues(alpha: 0.5), fontSize: 14),
                ),
                decoration: _buildInputDecoration(
                  hint: context.tr('corp_create.category_hint'),
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
                selectedItemBuilder: (context) {
                  return _categories.map((String value) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _getCategoryLabel(context, value),
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList();
                },
                items: _categories.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      _getCategoryLabel(context, value),
                      style: TextStyle(color: textColor, fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.tr('corp_create.category_error');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildLabel(context.tr('corp_create.address'), textColor),
              const SizedBox(height: 8),
              TextFormField(
                style: TextStyle(color: textColor),
                controller: _addressController,
                maxLines: 2,
                decoration: _buildInputDecoration(
                  hint: context.tr('corp_create.address_hint'),
                  cardColor: cardColor,
                  textColor: textColor,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.tr('corp_create.address_error');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(context.tr('corp_create.phone'), textColor),
                        const SizedBox(height: 8),
                        TextFormField(
                          style: TextStyle(color: textColor),
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: _buildInputDecoration(
                            hint: context.tr('corp_create.phone_hint'),
                            cardColor: cardColor,
                            textColor: textColor,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return context.tr('corp_create.required_field');
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(context.tr('corp_create.email'), textColor),
                        const SizedBox(height: 8),
                        TextFormField(
                          style: TextStyle(color: textColor),
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _buildInputDecoration(
                            hint: context.tr('corp_create.email_hint'),
                            cardColor: cardColor,
                            textColor: textColor,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return context.tr('corp_create.required_field');
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildLabel(context.tr('corp_create.website'), textColor),
              const SizedBox(height: 8),
              TextFormField(
                style: TextStyle(color: textColor),
                controller: _websiteController,
                keyboardType: TextInputType.url,
                decoration: _buildInputDecoration(
                  hint: context.tr('corp_create.website_hint'),
                  cardColor: cardColor,
                  textColor: textColor,
                ),
              ),
              const SizedBox(height: 32),

              // Seção: Operação
              _buildSectionHeader(context.tr('corp_create.operation_section'), textColor),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(context.tr('corp_create.opening_hours'), textColor),
                        const SizedBox(height: 8),
                        TextFormField(
                          style: TextStyle(color: textColor),
                          controller: _openingHoursController,
                          decoration: _buildInputDecoration(
                            hint: context.tr('corp_create.opening_hours_hint'),
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
                        _buildLabel(context.tr('corp_create.working_days'), textColor),
                        const SizedBox(height: 8),
                        TextFormField(
                          style: TextStyle(color: textColor),
                          controller: _workingDaysController,
                          decoration: _buildInputDecoration(
                            hint: context.tr('corp_create.working_days_hint'),
                            cardColor: cardColor,
                            textColor: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildLabel(context.tr('corp_create.services_offered'), textColor),
              const SizedBox(height: 8),
              _buildSelectionChips(
                items: _availableServices,
                selectedItems: _selectedServices,
                cardColor: cardColor,
                textColor: textColor,
                labelBuilder: (item) => _getServiceLabel(context, item),
              ),
              const SizedBox(height: 24),

              _buildLabel(context.tr('corp_create.payment_methods'), textColor),
              const SizedBox(height: 8),
              _buildSelectionChips(
                items: _availablePaymentMethods,
                selectedItems: _selectedPaymentMethods,
                cardColor: cardColor,
                textColor: textColor,
                labelBuilder: (item) => _getPaymentMethodLabel(context, item),
              ),
              const SizedBox(height: 32),

              // Seção: Sobre
              _buildSectionHeader(context.tr('corp_create.about_section'), textColor),
              const SizedBox(height: 16),

              _buildLabel(context.tr('corp_create.about'), textColor),
              const SizedBox(height: 8),
              TextFormField(
                style: TextStyle(color: textColor),
                controller: _aboutController,
                maxLines: 5,
                decoration: _buildInputDecoration(
                  hint: context.tr('corp_create.about_hint'),
                  cardColor: cardColor,
                  textColor: textColor,
                ),
              ),
              const SizedBox(height: 32),

              // Botão Salvar
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
                      child: Text(context.tr('corp_create.save_button'),
                          style: const TextStyle(fontSize: 16, color: Colors.white)),
                    ),
              const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildCoverImagePicker(
      DarkMode thmode, Color cardColor, Color textColor) {
    return Semantics(
      button: true,
      label: context.tr('corp_create.cover_label'),
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
                        context.tr('corp_create.cover_title'),
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
    );
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.patasColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _getCategoryLabel(BuildContext context, String cat) {
    switch (cat) {
      case 'Pet Shop':
        return context.tr('corp_create.cat_pet_shop');
      case 'Clínica Veterinária':
        return context.tr('corp_create.cat_vet_clinic');
      case 'Hospital Veterinário':
        return context.tr('corp_create.cat_vet_hospital');
      case 'Hotel para Pets':
        return context.tr('corp_create.cat_pet_hotel');
      case 'Adestramento':
        return context.tr('corp_create.cat_training');
      case 'Banho e Tosa':
        return context.tr('corp_create.cat_grooming');
      case 'Passeador de Cães':
        return context.tr('corp_create.cat_dog_walker');
      case 'Loja Especializada':
        return context.tr('corp_create.cat_specialty_store');
      case 'Fabricante/Marca':
        return context.tr('corp_create.cat_manufacturer');
      case 'Outro':
        return context.tr('corp_create.cat_other');
      default:
        return cat;
    }
  }

  String _getServiceLabel(BuildContext context, String service) {
    switch (service) {
      case 'Consultas':
        return context.tr('corp_create.srv_consultations');
      case 'Vacinas':
        return context.tr('corp_create.srv_vaccines');
      case 'Cirurgias':
        return context.tr('corp_create.srv_surgeries');
      case 'Exames':
        return context.tr('corp_create.srv_exams');
      case 'Banho':
        return context.tr('corp_create.srv_bath');
      case 'Tosa':
        return context.tr('corp_create.srv_grooming');
      case 'Hospedagem':
        return context.tr('corp_create.srv_boarding');
      case 'Adestramento':
        return context.tr('corp_create.srv_training');
      case 'Venda de Produtos':
        return context.tr('corp_create.srv_products');
      case 'Delivery':
        return context.tr('corp_create.srv_delivery');
      default:
        return service;
    }
  }

  String _getPaymentMethodLabel(BuildContext context, String method) {
    switch (method) {
      case 'Dinheiro':
        return context.tr('corp_create.pay_cash');
      case 'PIX':
        return context.tr('corp_create.pay_pix');
      case 'Cartão de Crédito':
        return context.tr('corp_create.pay_credit');
      case 'Cartão de Débito':
        return context.tr('corp_create.pay_debit');
      case 'Boleto':
        return context.tr('corp_create.pay_bank_slip');
      case 'Transferência':
        return context.tr('corp_create.pay_transfer');
      default:
        return method;
    }
  }

  Widget _buildSelectionChips({
    required List<String> items,
    required List<String> selectedItems,
    required Color cardColor,
    required Color textColor,
    String Function(String)? labelBuilder,
  }) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final isSelected = selectedItems.contains(item);
        final label = labelBuilder != null ? labelBuilder(item) : item;
        return FilterChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                selectedItems.add(item);
              } else {
                selectedItems.remove(item);
              }
            });
          },
          // CORES DE ALTO CONTRASTE
          selectedColor: AppColors.patasColor,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : textColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
          // Fundo do chip não selecionado
          backgroundColor: isDark
              ? const Color(0xFF353535) // Cinza escuro para texto branco
              : Colors.grey.shade200, // Cinza claro para texto preto
          side: BorderSide(
            color: isSelected
                ? AppColors.patasColor
                : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            width: isSelected ? 1.5 : 1,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          elevation: isSelected ? 2 : 0,
          pressElevation: 4,
          shadowColor: Colors.black.withValues(alpha: 0.3),
        );
      }).toList(),
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
