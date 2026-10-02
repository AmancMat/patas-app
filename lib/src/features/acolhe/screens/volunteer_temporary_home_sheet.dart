import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/providers/active_account_provider.dart';
import '../services/shelter_service.dart';

class VolunteerTemporaryHomeSheet extends StatefulWidget {
  final String? initialOngId;
  final String? initialOngName;

  const VolunteerTemporaryHomeSheet({
    super.key,
    this.initialOngId,
    this.initialOngName,
  });

  static Future<bool?> show(
    BuildContext context, {
    String? initialOngId,
    String? initialOngName,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VolunteerTemporaryHomeSheet(
        initialOngId: initialOngId,
        initialOngName: initialOngName,
      ),
    );
  }

  @override
  State<VolunteerTemporaryHomeSheet> createState() =>
      _VolunteerTemporaryHomeSheetState();
}

class _VolunteerTemporaryHomeSheetState
    extends State<VolunteerTemporaryHomeSheet> {
  final ShelterService _service = ShelterService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _cityController;
  late TextEditingController _neighborhoodController;
  late TextEditingController _notesController;
  late TextEditingController _otherPetsDetailsController;

  String? _selectedOngId;
  String? _selectedOngName;
  List<Map<String, String>> _availableOngs = [];
  bool _isLoadingOngs = true;

  String _housingType = 'casa';
  bool _hasYard = true;
  bool _hasOtherPets = false;
  String _allowedSpecies = 'todos';
  final List<String> _allowedSizes = ['pequeno', 'medio'];
  bool _canAdministerMedication = true;
  int _maxCapacity = 1;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final activeAcc =
        Provider.of<ActiveAccountProvider>(context, listen: false).activeAccount;
    final currentUser = Supabase.instance.client.auth.currentUser;

    _nameController = TextEditingController(text: activeAcc?.name ?? '');
    _phoneController = TextEditingController();
    _emailController = TextEditingController(text: currentUser?.email ?? '');
    _cityController = TextEditingController(text: 'São Paulo, SP');
    _neighborhoodController = TextEditingController();
    _notesController = TextEditingController();
    _otherPetsDetailsController = TextEditingController();

    _selectedOngId = widget.initialOngId;
    _selectedOngName = widget.initialOngName;

    _loadOngs();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _neighborhoodController.dispose();
    _notesController.dispose();
    _otherPetsDetailsController.dispose();
    super.dispose();
  }

  Future<void> _loadOngs() async {
    setState(() => _isLoadingOngs = true);
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('accounts')
          .select('id, name')
          .eq('type', 'ong')
          .limit(20);

      final list = (response as List)
          .map((row) => {
                'id': row['id'].toString(),
                'name': (row['name'] ?? 'ONG Parceira').toString(),
              })
          .toList();

      if (list.isEmpty) {
        _availableOngs = [
          {'id': 'ong-1', 'name': 'Instituto Patas do Bem'},
          {'id': 'ong-2', 'name': 'Gatinhos da Vila'},
          {'id': 'ong-3', 'name': 'Abrigo Esperança Animal'},
        ];
      } else {
        _availableOngs = list;
      }

      if (_selectedOngId == null && _availableOngs.isNotEmpty) {
        _selectedOngId = _availableOngs.first['id'];
        _selectedOngName = _availableOngs.first['name'];
      }
    } catch (e) {
      _availableOngs = [
        {'id': 'ong-1', 'name': 'Instituto Patas do Bem'},
        {'id': 'ong-2', 'name': 'Gatinhos da Vila'},
      ];
      _selectedOngId ??= _availableOngs.first['id'];
      _selectedOngName ??= _availableOngs.first['name'];
    } finally {
      if (mounted) {
        setState(() => _isLoadingOngs = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedOngId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor, selecione a ONG que deseja apoiar.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await _service.volunteerAsTemporaryHome(
      targetOngId: _selectedOngId!,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : null,
      city: _cityController.text.trim().isNotEmpty
          ? _cityController.text.trim()
          : null,
      neighborhood: _neighborhoodController.text.trim().isNotEmpty
          ? _neighborhoodController.text.trim()
          : null,
      housingType: _housingType,
      hasYard: _hasYard,
      hasOtherPets: _hasOtherPets,
      otherPetsDetails: _hasOtherPets &&
              _otherPetsDetailsController.text.trim().isNotEmpty
          ? _otherPetsDetailsController.text.trim()
          : null,
      allowedSpecies: _allowedSpecies,
      allowedSizes: _allowedSizes,
      canAdministerMedication: _canAdministerMedication,
      maxCapacity: _maxCapacity,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Candidatura enviada para ${_selectedOngName ?? 'a ONG'}! Entraremos em contato via WhatsApp. 🏡🐾',
          ),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Erro ao enviar candidatura de voluntário.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;

    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.white12 : Colors.grey.shade300;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
        maxWidth: 620,
      ),
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: borderColor),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.volunteer_activism_rounded,
                      color: Colors.blueAccent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Seja um Lar Temporário 🏡',
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.darkBG,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Salve vidas acolhendo um pet de ONG até a adoção',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),

            // Formulário com Scroll
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  children: [
                    // Banner explicativo amigável
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.blueAccent.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: Colors.blueAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'O Lar Temporário oferece abrigo provisório, carinho e segurança para pets resgatados. A ONG parceira geralmente custeia alimentação e tratamentos de saúde!',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : Colors.black87,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 1. Escolha da ONG
                    _buildSectionHeader('ONG QUE VOCÊ DESEJA APOIAR',
                        isDark: isDark),
                    const SizedBox(height: 8),
                    _isLoadingOngs
                        ? const LinearProgressIndicator()
                        : DropdownButtonFormField<String>(
                            initialValue: _selectedOngId,
                            dropdownColor:
                                isDark ? const Color(0xFF1E293B) : Colors.white,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: isDark ? Colors.white : AppColors.darkBG,
                            ),
                            iconEnabledColor:
                                isDark ? Colors.white70 : Colors.black54,
                            decoration: _buildInputDecoration(
                              isDark: isDark,
                              hint: 'Selecione a ONG parceira',
                              icon: Icons.pets_rounded,
                            ),
                            items: _availableOngs.map((ong) {
                              return DropdownMenuItem<String>(
                                value: ong['id'],
                                child: Text(
                                  ong['name'] ?? '',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.darkBG,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedOngId = val;
                                _selectedOngName = _availableOngs.firstWhere(
                                  (o) => o['id'] == val,
                                  orElse: () => {'name': ''},
                                )['name'];
                              });
                            },
                          ),
                    const SizedBox(height: 18),

                    // 2. Dados Pessoais
                    _buildSectionHeader('SEUS DADOS DE CONTATO', isDark: isDark),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isDark ? Colors.white : AppColors.darkBG,
                      ),
                      decoration: _buildInputDecoration(
                        isDark: isDark,
                        hint: 'Seu nome completo',
                        icon: Icons.person_outline_rounded,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Informe seu nome'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: isDark ? Colors.white : AppColors.darkBG,
                            ),
                            decoration: _buildInputDecoration(
                              isDark: isDark,
                              hint: 'WhatsApp (com DDD)',
                              icon: Icons.phone_outlined,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Informe seu WhatsApp'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: isDark ? Colors.white : AppColors.darkBG,
                            ),
                            decoration: _buildInputDecoration(
                              isDark: isDark,
                              hint: 'E-mail (opcional)',
                              icon: Icons.email_outlined,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cityController,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: isDark ? Colors.white : AppColors.darkBG,
                            ),
                            decoration: _buildInputDecoration(
                              isDark: isDark,
                              hint: 'Cidade / UF',
                              icon: Icons.location_city_rounded,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _neighborhoodController,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: isDark ? Colors.white : AppColors.darkBG,
                            ),
                            decoration: _buildInputDecoration(
                              isDark: isDark,
                              hint: 'Bairro',
                              icon: Icons.map_outlined,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // 3. Estrutura do Lar
                    _buildSectionHeader('SOBRE SUA RESIDÊNCIA', isDark: isDark),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildChoiceChip(
                            label: 'Casa',
                            icon: Icons.home_rounded,
                            isSelected: _housingType == 'casa',
                            onTap: () => setState(() => _housingType = 'casa'),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildChoiceChip(
                            label: 'Apartamento',
                            icon: Icons.apartment_rounded,
                            isSelected: _housingType == 'apartamento',
                            onTap: () =>
                                setState(() => _housingType = 'apartamento'),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildChoiceChip(
                            label: 'Chácara/Sítio',
                            icon: Icons.landscape_rounded,
                            isSelected: _housingType == 'chacara',
                            onTap: () =>
                                setState(() => _housingType = 'chacara'),
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Possui quintal telado / muros altos / telas nas janelas?',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white : AppColors.darkBG,
                        ),
                      ),
                      value: _hasYard,
                      onChanged: (val) => setState(() => _hasYard = val),
                      activeThumbColor: Colors.blueAccent,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Já possui outros animais em casa?',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white : AppColors.darkBG,
                        ),
                      ),
                      value: _hasOtherPets,
                      onChanged: (val) => setState(() => _hasOtherPets = val),
                      activeThumbColor: Colors.blueAccent,
                    ),
                    if (_hasOtherPets) ...[
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _otherPetsDetailsController,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: isDark ? Colors.white : AppColors.darkBG,
                        ),
                        decoration: _buildInputDecoration(
                          isDark: isDark,
                          hint: 'Ex: 1 cão dócil castrado, 2 gatos tranquilos',
                          icon: Icons.pets_rounded,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),

                    // 4. Capacidade e Preferências
                    _buildSectionHeader(
                        'CAPACIDADE E PREFERÊNCIAS DE ACOLHIMENTO',
                        isDark: isDark),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildChoiceChip(
                            label: 'Apenas Cães',
                            icon: Icons.pets_rounded,
                            isSelected: _allowedSpecies == 'canino',
                            onTap: () =>
                                setState(() => _allowedSpecies = 'canino'),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildChoiceChip(
                            label: 'Apenas Gatos',
                            icon: Icons.cruelty_free_rounded,
                            isSelected: _allowedSpecies == 'felino',
                            onTap: () =>
                                setState(() => _allowedSpecies = 'felino'),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildChoiceChip(
                            label: 'Ambos',
                            icon: Icons.all_inclusive_rounded,
                            isSelected: _allowedSpecies == 'todos',
                            onTap: () =>
                                setState(() => _allowedSpecies = 'todos'),
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Capacidade Máxima
                    Row(
                      children: [
                        Text(
                          'Quantos pets pode acolher por vez?',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white : AppColors.darkBG,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: _maxCapacity > 1
                              ? () => setState(() => _maxCapacity--)
                              : null,
                          icon:
                              const Icon(Icons.remove_circle_outline_rounded),
                          color: Colors.blueAccent,
                        ),
                        Text(
                          '$_maxCapacity',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.darkBG,
                          ),
                        ),
                        IconButton(
                          onPressed: _maxCapacity < 10
                              ? () => setState(() => _maxCapacity++)
                              : null,
                          icon: const Icon(Icons.add_circle_outline_rounded),
                          color: Colors.blueAccent,
                        ),
                      ],
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Pode acolher pets que necessitam de medicação oral?',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white : AppColors.darkBG,
                        ),
                      ),
                      value: _canAdministerMedication,
                      onChanged: (val) =>
                          setState(() => _canAdministerMedication = val),
                      activeThumbColor: Colors.blueAccent,
                    ),
                    const SizedBox(height: 10),

                    // Observações
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isDark ? Colors.white : AppColors.darkBG,
                      ),
                      decoration: _buildInputDecoration(
                        isDark: isDark,
                        hint:
                            'Alguma observação, disponibilidade de tempo ou preferência extra?',
                        icon: Icons.note_alt_outlined,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1),

            // Botão Enviar Candidatura
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.volunteer_activism_rounded,
                          color: Colors.white),
                  label: Text(
                    _isSubmitting
                        ? 'Enviando...'
                        : 'Enviar Candidatura de Voluntário',
                    style: const TextStyle(
                      fontFamily: 'Fredoka',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String text, {required bool isDark}) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Fredoka',
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
        letterSpacing: 0.8,
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required bool isDark,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: 12,
        color: isDark ? Colors.white38 : Colors.black38,
      ),
      prefixIcon: Icon(
        icon,
        size: 20,
        color: isDark ? Colors.white60 : Colors.black54,
      ),
      filled: true,
      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? Colors.white12 : Colors.grey.shade300,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? Colors.white12 : Colors.grey.shade300,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.blueAccent,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blueAccent.withValues(alpha: 0.15)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.blueAccent
                : (isDark ? Colors.white12 : Colors.grey.shade300),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? Colors.blueAccent
                  : (isDark ? Colors.white60 : Colors.black54),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Colors.blueAccent
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
