import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:patas_web_app/src/features/ongs_corp/models/corp_profile_model.dart';
import 'package:patas_web_app/src/features/ongs_corp/services/corp_service.dart';
import '../../../../main.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/src/providers/active_account_provider.dart';
import 'package:patas_web_app/src/models/active_account_model.dart';

class EditCorpProfilePage extends StatefulWidget {
  final CorpProfile corp;
  const EditCorpProfilePage({super.key, required this.corp});

  @override
  EditCorpProfilePageState createState() => EditCorpProfilePageState();
}

class EditCorpProfilePageState extends State<EditCorpProfilePage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers para campos de texto
  late TextEditingController _nameController;
  late TextEditingController _cnpjController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _websiteController;
  late TextEditingController _openingHoursController;
  late TextEditingController _workingDaysController;
  late TextEditingController _aboutController;

  // Categorias e listas
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
  late List<String> _selectedServices;

  final List<String> _availablePaymentMethods = [
    'Dinheiro',
    'PIX',
    'Cartão de Crédito',
    'Cartão de Débito',
    'Boleto',
    'Transferência',
  ];
  late List<String> _selectedPaymentMethods;

  File? _profileImage;
  File? _coverImage;
  final ImagePicker _picker = ImagePicker();

  final CorpService _corpService = CorpService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.corp.name);
    _cnpjController = TextEditingController(text: widget.corp.cnpj);
    _addressController = TextEditingController(text: widget.corp.address);
    _phoneController = TextEditingController(text: widget.corp.phone);
    _emailController = TextEditingController(text: widget.corp.email);
    _websiteController = TextEditingController(text: widget.corp.website);
    _openingHoursController =
        TextEditingController(text: widget.corp.openingHours);
    _workingDaysController =
        TextEditingController(text: widget.corp.workingDays);
    _aboutController = TextEditingController(text: widget.corp.about);
    _selectedCategory = widget.corp.category;
    _selectedServices = List.from(widget.corp.servicesOffered ?? []);
    _selectedPaymentMethods = List.from(widget.corp.paymentMethods ?? []);
  }

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
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final user = supabase.auth.currentUser;
      if (user == null) return;

      String? photoUrl = widget.corp.photoUrl;
      String? coverUrl = widget.corp.coverUrl;

      try {
        if (_profileImage != null) {
          photoUrl =
              await _corpService.uploadCorpImage(_profileImage!, user.id);
        }
        if (_coverImage != null) {
          coverUrl = await _corpService.uploadCorpCover(_coverImage!, user.id);
        }

        final updatedCorp = widget.corp.copyWith(
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
          servicesOffered: _selectedServices,
          paymentMethods: _selectedPaymentMethods,
          photoUrl: photoUrl,
          coverUrl: coverUrl,
          about: _aboutController.text.isEmpty ? null : _aboutController.text,
        );

        await _corpService.updateCorpProfile(updatedCorp);
        if (!mounted) return;

        final activeAccountProvider =
            Provider.of<ActiveAccountProvider>(context, listen: false);
        if (activeAccountProvider.activeAccount?.id == updatedCorp.id) {
          activeAccountProvider.setActiveAccount(
            ActiveAccount(
              id: updatedCorp.id,
              name: updatedCorp.name,
              photoUrl: updatedCorp.photoUrl,
              type: AccountType.company,
            ),
          );
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil atualizado com sucesso!')),
        );
        Navigator.pop(context, updatedCorp);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar o perfil: $e')),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
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
        title: const Text('Editar Perfil de Empresa'),
        backgroundColor:
            thmode.darkMode ? AppColors.darkBG : AppColors.bodyLight,
        elevation: 0,
        foregroundColor: textColor,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.patasColor,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildCoverImagePicker(thmode, cardColor, textColor),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: () => _showImageSourceActionSheet(true),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: thmode.darkMode
                        ? Colors.grey.shade800
                        : Colors.grey.shade300,
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : (widget.corp.photoUrl != null &&
                                widget.corp.photoUrl!.isNotEmpty
                            ? NetworkImage(widget.corp.photoUrl!)
                            : null) as ImageProvider?,
                    child: _profileImage == null &&
                            (widget.corp.photoUrl == null ||
                                widget.corp.photoUrl!.isEmpty)
                        ? Icon(Icons.camera_alt,
                            size: 50, color: Colors.grey.shade400)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _buildSectionHeader('Informações Básicas', textColor),
              const SizedBox(height: 16),
              _buildLabel('Nome da Empresa*', textColor),
              const SizedBox(height: 8),
              TextFormField(
                style: TextStyle(color: textColor),
                controller: _nameController,
                decoration: _buildInputDecoration(
                    hint: 'Nome Comercial',
                    cardColor: cardColor,
                    textColor: textColor),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              _buildLabel('Categoria*', textColor),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: _buildInputDecoration(
                    hint: 'Selecione a categoria',
                    cardColor: cardColor,
                    textColor: textColor),
                dropdownColor:
                    thmode.darkMode ? AppColors.darkBG : AppColors.bodyLight,
                style: TextStyle(color: textColor),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
              ),
              const SizedBox(height: 32),
              _buildSectionHeader('Serviços e Pagamento', textColor),
              const SizedBox(height: 16),
              _buildSelectionChips(
                  items: _availableServices,
                  selectedItems: _selectedServices,
                  textColor: textColor),
              const SizedBox(height: 16),
              _buildLabel('Formas de Pagamento', textColor),
              const SizedBox(height: 8),
              _buildSelectionChips(
                  items: _availablePaymentMethods,
                  selectedItems: _selectedPaymentMethods,
                  textColor: textColor),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.patasColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _submitForm,
                      child: const Text('Salvar Alterações',
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverImagePicker(
      DarkMode thmode, Color cardColor, Color textColor) {
    return GestureDetector(
      onTap: () => _showImageSourceActionSheet(false),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(15),
          image: _coverImage != null
              ? DecorationImage(
                  image: FileImage(_coverImage!), fit: BoxFit.cover)
              : (widget.corp.coverUrl != null &&
                      widget.corp.coverUrl!.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(widget.corp.coverUrl!),
                      fit: BoxFit.cover)
                  : null),
        ),
        child: _coverImage == null &&
                (widget.corp.coverUrl == null || widget.corp.coverUrl!.isEmpty)
            ? Center(
                child: Icon(Icons.add_photo_alternate,
                    size: 40, color: Colors.grey.shade400))
            : null,
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
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(
                color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSelectionChips(
      {required List<String> items,
      required List<String> selectedItems,
      required Color textColor}) {
    final thmode = Provider.of<DarkMode>(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final isSelected = selectedItems.contains(item);
        return FilterChip(
          label: Text(item),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              selected ? selectedItems.add(item) : selectedItems.remove(item);
            });
          },
          selectedColor: AppColors.patasColor,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
              color: isSelected ? Colors.white : textColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12),
          backgroundColor:
              thmode.darkMode ? const Color(0xFF353535) : Colors.grey.shade200,
          side: BorderSide(
            color: isSelected
                ? AppColors.patasColor
                : (thmode.darkMode
                    ? Colors.grey.shade700
                    : Colors.grey.shade300),
            width: isSelected ? 1.5 : 1,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLabel(String label, Color textColor) {
    return Text(label,
        style: TextStyle(
            color: textColor.withValues(alpha: 0.6),
            fontSize: 13,
            fontWeight: FontWeight.bold));
  }

  InputDecoration _buildInputDecoration(
      {required String hint,
      required Color cardColor,
      required Color textColor}) {
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
