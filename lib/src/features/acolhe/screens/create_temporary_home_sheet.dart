import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import '../models/temporary_home_model.dart';
import '../services/shelter_service.dart';

class CreateTemporaryHomeSheet extends StatefulWidget {
  final String ongId;
  final TemporaryHome? homeToEdit;
  final VoidCallback onSaved;

  const CreateTemporaryHomeSheet({
    super.key,
    required this.ongId,
    this.homeToEdit,
    required this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    required String ongId,
    TemporaryHome? homeToEdit,
    required VoidCallback onSaved,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateTemporaryHomeSheet(
        ongId: ongId,
        homeToEdit: homeToEdit,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<CreateTemporaryHomeSheet> createState() =>
      _CreateTemporaryHomeSheetState();
}

class _CreateTemporaryHomeSheetState extends State<CreateTemporaryHomeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _cityController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _otherPetsController = TextEditingController();
  final _notesController = TextEditingController();

  String _housingType = 'casa';
  bool _hasYard = true;
  bool _hasOtherPets = false;
  String _allowedSpecies = 'ambos';
  bool _canAdministerMedication = false;
  int _maxCapacity = 1;
  String _status = 'disponivel';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.homeToEdit != null) {
      final h = widget.homeToEdit!;
      _nameController.text = h.name;
      _phoneController.text = h.phone;
      _emailController.text = h.email ?? '';
      _cityController.text = h.city ?? '';
      _neighborhoodController.text = h.neighborhood ?? '';
      _otherPetsController.text = h.otherPetsDetails ?? '';
      _notesController.text = h.notes ?? '';
      _housingType = h.housingType;
      _hasYard = h.hasYard;
      _hasOtherPets = h.hasOtherPets;
      _allowedSpecies = h.allowedSpecies;
      _canAdministerMedication = h.canAdministerMedication;
      _maxCapacity = h.maxCapacity;
      _status = h.status;
    } else {
      _cityController.text = 'São Paulo, SP';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _neighborhoodController.dispose();
    _otherPetsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final shelterService = ShelterService();

    final home = TemporaryHome(
      id: widget.homeToEdit?.id ?? '',
      ongId: widget.ongId,
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
              _otherPetsController.text.trim().isNotEmpty
          ? _otherPetsController.text.trim()
          : null,
      allowedSpecies: _allowedSpecies,
      allowedSizes: const ['pequeno', 'medio'],
      canAdministerMedication: _canAdministerMedication,
      maxCapacity: _maxCapacity,
      status: _status,
      isCommunityVolunteer:
          widget.homeToEdit?.isCommunityVolunteer ?? false,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      createdAt: widget.homeToEdit?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    bool ok;
    if (widget.homeToEdit != null) {
      ok = await shelterService.updateTemporaryHome(home);
    } else {
      final res = await shelterService.createTemporaryHome(home);
      ok = res != null;
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (ok) {
      widget.onSaved();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.homeToEdit != null
                ? 'Voluntário atualizado com sucesso!'
                : 'Novo voluntário cadastrado com sucesso!',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Erro ao salvar lar temporário.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
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
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.home_work_rounded,
                        color: Colors.blueAccent, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.homeToEdit != null
                              ? 'Editar Voluntário de LT'
                              : 'Cadastrar Voluntário de LT',
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.darkBG,
                          ),
                        ),
                        Text(
                          'Registre um tutor parceiro da rede de acolhimento.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // 1. Dados do Voluntário
                    _buildSectionHeader('DADOS DO VOLUNTÁRIO', isDark: isDark),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _nameController,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isDark ? Colors.white : AppColors.darkBG,
                      ),
                      decoration: _buildInputDecoration(
                        label: 'Nome do Voluntário / Família *',
                        hint: 'Ex: Família Souza, Maria da Silva...',
                        icon: Icons.person_outline_rounded,
                        isDark: isDark,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Informe o nome do voluntário'
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
                              label: 'WhatsApp / Telefone *',
                              hint: '(11) 99999-9999',
                              icon: Icons.phone_outlined,
                              isDark: isDark,
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Informe o WhatsApp'
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
                              label: 'E-mail (Opcional)',
                              hint: 'exemplo@email.com',
                              icon: Icons.email_outlined,
                              isDark: isDark,
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
                            controller: _neighborhoodController,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: isDark ? Colors.white : AppColors.darkBG,
                            ),
                            decoration: _buildInputDecoration(
                              label: 'Bairro',
                              hint: 'Ex: Pinheiros',
                              icon: Icons.place_outlined,
                              isDark: isDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _cityController,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: isDark ? Colors.white : AppColors.darkBG,
                            ),
                            decoration: _buildInputDecoration(
                              label: 'Cidade',
                              hint: 'Ex: São Paulo',
                              icon: Icons.location_city_outlined,
                              isDark: isDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 2. Características do Lar e Capacidade
                    _buildSectionHeader('CAPACIDADE E ESPAÇO FÍSICO', isDark: isDark),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _housingType,
                            dropdownColor:
                                isDark ? const Color(0xFF1E293B) : Colors.white,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: isDark ? Colors.white : AppColors.darkBG,
                            ),
                            iconEnabledColor:
                                isDark ? Colors.white70 : Colors.black54,
                            decoration: _buildInputDecoration(
                              label: 'Tipo de Residência',
                              icon: Icons.home_rounded,
                              isDark: isDark,
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'casa',
                                child: Text('Casa',
                                    style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : AppColors.darkBG)),
                              ),
                              DropdownMenuItem(
                                value: 'apartamento',
                                child: Text('Apartamento',
                                    style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : AppColors.darkBG)),
                              ),
                              DropdownMenuItem(
                                value: 'sitio',
                                child: Text('Sítio / Chácara',
                                    style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : AppColors.darkBG)),
                              ),
                            ],
                            onChanged: (v) =>
                                setState(() => _housingType = v ?? 'casa'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _maxCapacity,
                            dropdownColor:
                                isDark ? const Color(0xFF1E293B) : Colors.white,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: isDark ? Colors.white : AppColors.darkBG,
                            ),
                            iconEnabledColor:
                                isDark ? Colors.white70 : Colors.black54,
                            decoration: _buildInputDecoration(
                              label: 'Capacidade Máxima',
                              icon: Icons.event_seat_rounded,
                              isDark: isDark,
                            ),
                            items: [
                              for (int i = 1; i <= 6; i++)
                                DropdownMenuItem(
                                  value: i,
                                  child: Text('$i ${i == 1 ? 'pet' : 'pets'}',
                                      style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : AppColors.darkBG)),
                                ),
                            ],
                            onChanged: (v) =>
                                setState(() => _maxCapacity = v ?? 1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Espécies Aceitas
                    DropdownButtonFormField<String>(
                      initialValue: _allowedSpecies,
                      dropdownColor:
                          isDark ? const Color(0xFF1E293B) : Colors.white,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isDark ? Colors.white : AppColors.darkBG,
                      ),
                      iconEnabledColor:
                          isDark ? Colors.white70 : Colors.black54,
                      decoration: _buildInputDecoration(
                        label: 'Preferência de Espécie',
                        icon: Icons.pets_rounded,
                        isDark: isDark,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'ambos',
                          child: Text('Aceita Cães e Gatos',
                              style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.darkBG)),
                        ),
                        DropdownMenuItem(
                          value: 'canino',
                          child: Text('Aceita Apenas Cães',
                              style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.darkBG)),
                        ),
                        DropdownMenuItem(
                          value: 'felino',
                          child: Text('Aceita Apenas Gatos',
                              style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.darkBG)),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _allowedSpecies = v ?? 'ambos'),
                    ),
                    const SizedBox(height: 12),

                    // Checkboxes de Estrutura
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Possui quintal / área externa telada',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white : AppColors.darkBG,
                        ),
                      ),
                      value: _hasYard,
                      activeThumbColor: Colors.blueAccent,
                      onChanged: (v) => setState(() => _hasYard = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Pode administrar medicação / cuidados especiais',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white : AppColors.darkBG,
                        ),
                      ),
                      value: _canAdministerMedication,
                      activeThumbColor: Colors.blueAccent,
                      onChanged: (v) =>
                          setState(() => _canAdministerMedication = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Já possui outros animais na casa',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white : AppColors.darkBG,
                        ),
                      ),
                      value: _hasOtherPets,
                      activeThumbColor: Colors.blueAccent,
                      onChanged: (v) => setState(() => _hasOtherPets = v),
                    ),

                    if (_hasOtherPets) ...[
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _otherPetsController,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: isDark ? Colors.white : AppColors.darkBG,
                        ),
                        decoration: _buildInputDecoration(
                          label: 'Detalhes dos outros animais',
                          hint: 'Ex: 1 cão macho castrado dócil',
                          icon: Icons.info_outline_rounded,
                          isDark: isDark,
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // Status
                    DropdownButtonFormField<String>(
                      initialValue: _status,
                      dropdownColor:
                          isDark ? const Color(0xFF1E293B) : Colors.white,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isDark ? Colors.white : AppColors.darkBG,
                      ),
                      iconEnabledColor:
                          isDark ? Colors.white70 : Colors.black54,
                      decoration: _buildInputDecoration(
                        label: 'Status do Lar',
                        icon: Icons.toggle_on_outlined,
                        isDark: isDark,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'disponivel',
                          child: Text('🟢 Disponível',
                              style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.darkBG)),
                        ),
                        DropdownMenuItem(
                          value: 'pausado',
                          child: Text('⏸️ Pausado Temporariamente',
                              style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.darkBG)),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _status = v ?? 'disponivel'),
                    ),

                    const SizedBox(height: 12),

                    // Observações
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isDark ? Colors.white : AppColors.darkBG,
                      ),
                      decoration: _buildInputDecoration(
                        label: 'Observações Internas (opcional)',
                        hint: 'Ex: Disponibilidade para levar em veterinário aos sábados...',
                        icon: Icons.notes_rounded,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1),

            // Botão Salvar
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          widget.homeToEdit != null
                              ? 'Salvar Alterações'
                              : 'Cadastrar Voluntário',
                          style: const TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
    required String label,
    String? hint,
    required IconData icon,
    required bool isDark,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        fontSize: 13,
        color: isDark ? Colors.white70 : Colors.black87,
      ),
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
}
