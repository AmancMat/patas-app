import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/common_widgets/mobile_scroll_padding.dart';
import '../models/donation_campaign_model.dart';
import '../services/shelter_service.dart';

class OngCreateCampaignSheet extends StatefulWidget {
  final String ongId;
  final String? ongName;
  final String? defaultPixKey;
  final DonationCampaign? existingCampaign;

  const OngCreateCampaignSheet({
    super.key,
    required this.ongId,
    this.ongName,
    this.defaultPixKey,
    this.existingCampaign,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String ongId,
    String? ongName,
    String? defaultPixKey,
    DonationCampaign? existingCampaign,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OngCreateCampaignSheet(
        ongId: ongId,
        ongName: ongName,
        defaultPixKey: defaultPixKey,
        existingCampaign: existingCampaign,
      ),
    );
  }

  @override
  State<OngCreateCampaignSheet> createState() => _OngCreateCampaignSheetState();
}

class _OngCreateCampaignSheetState extends State<OngCreateCampaignSheet> {
  final _formKey = GlobalKey<FormState>();
  final ShelterService _service = ShelterService();

  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _targetAmountController;
  late TextEditingController _currentAmountController;
  late TextEditingController _unitLabelController;
  late TextEditingController _pixKeyController;
  late TextEditingController _solanaWalletController;
  late TextEditingController _petBeneficiaryController;

  File? _pickedImage;
  String? _currentPhotoUrl;

  String _selectedCategory = 'Ração & Alimento';
  String _selectedGoalType = 'money'; // 'money' ou 'items'
  String _selectedPixType = 'cnpj';
  bool _isLoading = false;

  final List<String> _categories = [
    'Ração & Alimento',
    'Saúde & Cirurgia',
    'Reforma & Abrigo',
    'Geral & Manutenção',
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.existingCampaign;

    _titleController = TextEditingController(text: c?.title ?? '');
    _descController = TextEditingController(text: c?.description ?? '');
    _targetAmountController = TextEditingController(
      text: c != null ? c.targetAmount.toStringAsFixed(0) : '1500',
    );
    _currentAmountController = TextEditingController(
      text: c != null ? c.currentAmount.toStringAsFixed(0) : '0',
    );
    _unitLabelController = TextEditingController(text: c?.unitLabel ?? 'R\$');
    _pixKeyController = TextEditingController(
      text: c?.pixKey ?? widget.defaultPixKey ?? '',
    );
    _solanaWalletController = TextEditingController(
      text: c?.solanaWallet ?? '',
    );
    _petBeneficiaryController =
        TextEditingController(text: c?.beneficiaryPetName ?? '');

    _selectedCategory = c?.category ?? 'Ração & Alimento';
    _selectedGoalType = c?.goalType ?? 'money';
    _selectedPixType = c?.pixKeyType ?? 'cnpj';
    _currentPhotoUrl = c?.imageUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _targetAmountController.dispose();
    _currentAmountController.dispose();
    _unitLabelController.dispose();
    _pixKeyController.dispose();
    _solanaWalletController.dispose();
    _petBeneficiaryController.dispose();
    super.dispose();
  }

  /// Formata dinamicamente o CNPJ: 00.000.000/0000-00
  String _formatCnpj(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 14) return _formatCnpj(digits.substring(0, 14));

    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 2 || i == 5) buf.write('.');
      if (i == 8) buf.write('/');
      if (i == 12) buf.write('-');
      buf.write(digits[i]);
    }
    return buf.toString();
  }

  void _onPixKeyChanged(String value) {
    if (_selectedPixType == 'cnpj') {
      final formatted = _formatCnpj(value);
      if (formatted != value) {
        _pixKeyController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  void _showImagePicker(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: Colors.purpleAccent),
              title: const Text('Galeria',
                  style: TextStyle(fontFamily: 'Fredoka')),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded,
                  color: Colors.purpleAccent),
              title: const Text('Câmera',
                  style: TextStyle(fontFamily: 'Fredoka')),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? photoUrl = _currentPhotoUrl;
      if (_pickedImage != null) {
        final uploaded =
            await _service.uploadCampaignPhoto(_pickedImage!, widget.ongId);
        if (uploaded != null) photoUrl = uploaded;
      }

      final target = double.tryParse(
            _targetAmountController.text
                .replaceAll('R\$', '')
                .replaceAll('.', '')
                .replaceAll(',', '.')
                .trim(),
          ) ??
          1000.0;

      final current = double.tryParse(
            _currentAmountController.text
                .replaceAll('R\$', '')
                .replaceAll('.', '')
                .replaceAll(',', '.')
                .trim(),
          ) ??
          0.0;

      final campaign = DonationCampaign(
        id: widget.existingCampaign?.id ?? '',
        ongId: widget.ongId,
        ongName: widget.ongName ?? 'ONG Parceira',
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        imageUrl: photoUrl,
        category: _selectedCategory,
        goalType: _selectedGoalType,
        targetAmount: target,
        currentAmount: current,
        unitLabel: _selectedGoalType == 'money'
            ? 'R\$'
            : _unitLabelController.text.trim(),
        pixKey: _pixKeyController.text.trim(),
        pixKeyType: _selectedPixType,
        solanaWallet: _solanaWalletController.text.trim().isNotEmpty
            ? _solanaWalletController.text.trim()
            : null,
        beneficiaryPetName: _petBeneficiaryController.text.trim().isNotEmpty
            ? _petBeneficiaryController.text.trim()
            : null,
        createdAt: widget.existingCampaign?.createdAt ?? DateTime.now(),
      );

      await _service.saveDonationCampaign(campaign);

      if (mounted) {
        final isEdit = widget.existingCampaign != null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isEdit
                        ? 'Campanha de doação atualizada com sucesso! 💖'
                        : 'Campanha de doação publicada com sucesso! 💖',
                    style: const TextStyle(fontFamily: 'Fredoka', fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        String friendlyError = 'Não foi possível publicar a campanha. Tente novamente.';
        final errStr = e.toString().toLowerCase();

        if (errStr.contains('403') || errStr.contains('row-level security') || errStr.contains('unauthorized')) {
          friendlyError = 'Sem permissão para salvar no banco ou enviar a foto da campanha. Verifique sua sessão.';
        } else if (errStr.contains('socketexception') || errStr.contains('network') || errStr.contains('timeout')) {
          friendlyError = 'Falha de conexão com a internet. Verifique seu sinal e tente novamente.';
        } else if (errStr.contains('pgrst') || errStr.contains('schema')) {
          friendlyError = 'O servidor do banco de dados está atualizando seu catálogo. Tente novamente em instantes.';
        } else if (errStr.contains('null') || errStr.contains('not-null')) {
          friendlyError = 'Preencha todos os campos obrigatórios marcados com * para continuar.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    friendlyError,
                    style: const TextStyle(fontFamily: 'Fredoka', fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.redAccent.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).viewInsets.bottom +
            MobileScrollPadding.bottomInset(context),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Cabeçalho
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.pinkAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.volunteer_activism_rounded,
                      color: Colors.pinkAccent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.existingCampaign != null
                          ? 'Editar Campanha'
                          : 'Nova Campanha de Doação',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.darkBG,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const Divider(height: 22),

              // 1. Foto de Capa da Campanha
              InkWell(
                onTap: () => _showImagePicker(isDark),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.grey.shade300,
                      style: BorderStyle.solid,
                    ),
                    image: _pickedImage != null
                        ? DecorationImage(
                            image: FileImage(_pickedImage!),
                            fit: BoxFit.cover,
                          )
                        : (_currentPhotoUrl != null &&
                                _currentPhotoUrl!.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(_currentPhotoUrl!),
                                fit: BoxFit.cover,
                              )
                            : null),
                  ),
                  child: (_pickedImage == null &&
                          (_currentPhotoUrl == null ||
                              _currentPhotoUrl!.isEmpty))
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_rounded,
                              size: 40,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Toque para adicionar foto de capa',
                              style: TextStyle(
                                fontFamily: 'Fredoka',
                                fontSize: 13,
                                color:
                                    isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        )
                      : null,
                ),
              ),

              const SizedBox(height: 16),

              // 2. Título da Campanha
              _buildTextField(
                controller: _titleController,
                label: 'Título da Campanha *',
                hint: 'Ex: Ração para 85 cães resgatados neste mês',
                isDark: isDark,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Informe o título' : null,
              ),

              const SizedBox(height: 14),

              // 3. Categoria
              Text(
                'Categoria da Campanha',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: Colors.pinkAccent,
                    labelStyle: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 12,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black87),
                    ),
                    backgroundColor:
                        isDark ? const Color(0xFF334155) : Colors.grey.shade100,
                    onSelected: (val) {
                      if (val) setState(() => _selectedCategory = cat);
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 14),

              // 4. Tipo de Meta: Financeira vs Itens
              Text(
                'Tipo de Meta da Campanha',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedGoalType = 'money'),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedGoalType == 'money'
                              ? Colors.pinkAccent
                              : (isDark
                                  ? const Color(0xFF0F172A)
                                  : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _selectedGoalType == 'money'
                                ? Colors.pinkAccent
                                : (isDark ? Colors.white12 : Colors.grey.shade300),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.attach_money_rounded,
                              size: 18,
                              color: _selectedGoalType == 'money'
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : Colors.black87),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Financeira (R\$)',
                              style: TextStyle(
                                fontFamily: 'Fredoka',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _selectedGoalType == 'money'
                                    ? Colors.white
                                    : (isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedGoalType = 'items'),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedGoalType == 'items'
                              ? Colors.pinkAccent
                              : (isDark
                                  ? const Color(0xFF0F172A)
                                  : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _selectedGoalType == 'items'
                                ? Colors.pinkAccent
                                : (isDark ? Colors.white12 : Colors.grey.shade300),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 18,
                              color: _selectedGoalType == 'items'
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : Colors.black87),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Em Itens (kg, etc)',
                              style: TextStyle(
                                fontFamily: 'Fredoka',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _selectedGoalType == 'items'
                                    ? Colors.white
                                    : (isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // 5. Meta e Valor Arrecadado
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildTextField(
                      controller: _targetAmountController,
                      label: _selectedGoalType == 'money'
                          ? 'Meta Financeira (R\$) *'
                          : 'Meta de Quantidade *',
                      hint: _selectedGoalType == 'money' ? 'Ex: 2500' : 'Ex: 300',
                      keyboardType: TextInputType.number,
                      isDark: isDark,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Meta obrigatória' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (_selectedGoalType == 'items')
                    Expanded(
                      flex: 2,
                      child: _buildTextField(
                        controller: _unitLabelController,
                        label: 'Unidade',
                        hint: 'Ex: kg, sacos',
                        isDark: isDark,
                      ),
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: _buildTextField(
                      controller: _currentAmountController,
                      label: 'Já Arrecadado',
                      hint: '0',
                      keyboardType: TextInputType.number,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // 6. Chave PIX e Tipo
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: _buildTextField(
                      controller: _pixKeyController,
                      label: 'Chave PIX da Campanha *',
                      hint: _selectedPixType == 'cnpj'
                          ? '00.000.000/0000-00'
                          : (_selectedPixType == 'email'
                              ? 'contato@ong.org.br'
                              : (_selectedPixType == 'telefone'
                                  ? '(11) 99999-9999'
                                  : 'Chave aleatória')),
                      isDark: isDark,
                      keyboardType: _selectedPixType == 'cnpj' ||
                              _selectedPixType == 'telefone'
                          ? TextInputType.number
                          : TextInputType.text,
                      prefixIcon: const Icon(Icons.pix_rounded,
                          color: Colors.teal, size: 20),
                      onChanged: _onPixKeyChanged,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Informe a chave PIX' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tipo',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF0F172A)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white12
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedPixType,
                              isExpanded: true,
                              dropdownColor: isDark
                                  ? const Color(0xFF1E293B)
                                  : Colors.white,
                              style: TextStyle(
                                fontFamily: 'Fredoka',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.darkBG,
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 'cnpj',
                                  child: Text(
                                    'CNPJ',
                                    style: TextStyle(
                                      color: isDark ? Colors.white : AppColors.darkBG,
                                    ),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'email',
                                  child: Text(
                                    'E-mail',
                                    style: TextStyle(
                                      color: isDark ? Colors.white : AppColors.darkBG,
                                    ),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'telefone',
                                  child: Text(
                                    'Tel',
                                    style: TextStyle(
                                      color: isDark ? Colors.white : AppColors.darkBG,
                                    ),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'aleatoria',
                                  child: Text(
                                    'Aleat.',
                                    style: TextStyle(
                                      color: isDark ? Colors.white : AppColors.darkBG,
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedPixType = val;
                                    _pixKeyController.clear();
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // 6.1 Carteira Solana (Opcional - Hackathon & Doações Globais)
              _buildTextField(
                controller: _solanaWalletController,
                label: 'Endereço Solana da ONG (Opcional / Global)',
                hint: 'Ex: 7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU',
                isDark: isDark,
                prefixIcon: const Icon(
                  Icons.flash_on_rounded,
                  color: Color(0xFF9945FF),
                  size: 20,
                ),
              ),

              const SizedBox(height: 14),

              // 7. Descrição da Campanha
              _buildTextField(
                controller: _descController,
                label: 'Descrição & História',
                hint:
                    'Explique para os tutores o motivo da campanha e como o valor será utilizado...',
                maxLines: 4,
                isDark: isDark,
              ),

              const SizedBox(height: 22),

              // Botão Salvar
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          widget.existingCampaign != null
                              ? 'Salvar Alterações'
                              : 'Publicar Campanha de Doação',
                          style: const TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    int maxLines = 1,
    TextInputType? keyboardType,
    Widget? prefixIcon,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white30 : Colors.grey.shade400,
            ),
            prefixIcon: prefixIcon,
            filled: true,
            fillColor:
                isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.white12 : Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.white12 : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.pinkAccent,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
