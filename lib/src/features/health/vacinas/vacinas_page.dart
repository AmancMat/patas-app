import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/src/common_widgets/patas_essencial_app_bar.dart';
import 'package:patas_web_app/core/localization/app_localizations.dart';
import 'package:patas_web_app/src/features/health/models/vaccine_model.dart';
import 'package:patas_web_app/src/features/health/services/health_service.dart';
import 'package:patas_web_app/src/features/pets/active_pet_provider.dart';
import 'package:patas_web_app/src/features/pets/models/pet_model.dart';
import 'package:patas_web_app/src/features/notifications/notifications.dart';
import 'package:patas_web_app/src/utils/responsive_layout.dart';
import 'package:patas_web_app/app.dart';
import '../../../constants/app_colors.dart';

class VacinasPage extends StatefulWidget {
  final VoidCallback? onBack;
  const VacinasPage({super.key, this.onBack});

  @override
  State<VacinasPage> createState() => _VacinasPageState();
}

class _VacinasPageState extends State<VacinasPage> {
  final HealthService _healthService = HealthService();
  late Future<List<PetVaccine>> _vaccinesFuture;
  Pet? _currentPet;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final activePet = Provider.of<ActivePetProvider>(context).activePet;
    if (activePet?.id != _currentPet?.id) {
      _loadData();
    }
  }

  void _loadData() {
    final activePet =
        Provider.of<ActivePetProvider>(context, listen: false).activePet;
    if (activePet != null) {
      _currentPet = activePet;
      _vaccinesFuture = _healthService.getVaccines(activePet.id);
    } else {
      _vaccinesFuture = Future.value([]);
    }
  }

  void _refresh() {
    setState(() {
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobileLayout(context),
      desktop: _buildDesktopLayout(context),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final activePet = Provider.of<ActivePetProvider>(context).activePet;

    // Detectar troca de pet e recarregar
    if (activePet != _currentPet) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refresh();
      });
    }

    if (activePet == null) {
      return Scaffold(
        backgroundColor: thmode.darkMode ? AppColors.bodygray : const Color(0xFFF5F7FA),
        appBar: PatasEssencialAppBar(
          title: context.tr('health.vaccines_wallet_title'),
          subtitle: context.tr('health.vaccines_sub_empty'),
        ),
        body: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(
            child: Text(
              context.tr('health.vaccines_sub_empty'),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: thmode.darkMode ? AppColors.bodygray : const Color(0xFFF5F7FA),
      appBar: PatasEssencialAppBar(
        title: context.tr('health.vaccines_wallet_title'),
        subtitle: context.tr('health.vaccines_sub_pet', {'name': activePet.name}),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildStatusCard(activePet, thmode),
            _buildSuggestedTable(activePet, thmode),
            _buildWalletSection(activePet, thmode),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final activePet = Provider.of<ActivePetProvider>(context).activePet;
    final bgColor = thmode.darkMode ? AppColors.bodygray : const Color(0xFFF5F7FA);

    if (activePet != _currentPet) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refresh();
      });
    }

    if (activePet == null) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: PatasEssencialAppBar(
          title: context.tr('health.vaccines_wallet_title'),
          subtitle: context.tr('health.vaccines_sub_empty'),
        ),
        body: Center(
          child: Text(context.tr('health.vaccines_sub_empty')),
        ),
      );
    }

    final mainContent = Scaffold(
      backgroundColor: bgColor,
      appBar: PatasEssencialAppBar(
        title: context.tr('health.vaccines_wallet_title'),
        subtitle: context.tr('health.vaccines_sub_pet', {'name': activePet.name}),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Esquerda: Status do Pet
                      Expanded(
                        child: _buildStatusCard(activePet, thmode, isDesktop: true),
                      ),
                      const SizedBox(width: 30),
                      // Direita: Programa Sugerido
                      Expanded(
                        child: _buildSuggestedTable(activePet, thmode, isDesktop: true),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
                sliver: SliverToBoxAdapter(
                  child: _buildWalletSection(activePet, thmode, isDesktop: true),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return mainContent;
  }

  Widget _buildStatusCard(Pet pet, DarkMode thmode, {bool isDesktop = false}) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: EdgeInsets.only(
            top: isDesktop ? 0 : 16, 
            bottom: isDesktop ? 16 : 6, 
            left: isDesktop ? 0 : 23, 
            right: isDesktop ? 0 : 16,
          ),
          child: Text(
            context.tr('health.vaccine_status_title', {'name': pet.name}),
            style: TextStyle(
                color: thmode.darkMode ? Colors.white : AppColors.darkBG,
                fontWeight: FontWeight.bold,
                fontSize: 18),
          ),
        ),
        Container(
          width: double.infinity,
          margin: EdgeInsets.only(
            left: isDesktop ? 0 : 8, 
            right: isDesktop ? 0 : 16,
          ),
          child: Card(
            color: thmode.darkMode ? AppColors.darkBG : AppColors.bodyLight,
            elevation: isDesktop ? 10 : 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isDesktop ? 24 : 20),
              side: isDesktop 
                  ? BorderSide(color: (thmode.darkMode ? Colors.white : Colors.black).withValues(alpha: 0.05)) 
                  : BorderSide.none,
            ),
            child: Padding(
              padding: EdgeInsets.all(isDesktop ? 24 : 16),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Coluna da Esquerda: Detalhes do Pet
                    Expanded(
                      flex: 45,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundColor:
                                    AppColors.patasColor.withValues(alpha: 0.1),
                                backgroundImage: pet.photoUrl != null
                                    ? NetworkImage(pet.photoUrl!)
                                    : null,
                                child: pet.photoUrl == null
                                    ? const Icon(Icons.pets,
                                        color: AppColors.patasColor, size: 20)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  pet.name,
                                  style: TextStyle(
                                      color: thmode.darkMode
                                          ? Colors.white
                                          : AppColors.darkBG,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Divider(height: 1),
                          ),
                          _buildInfoRow(context.tr('health.breed_label'), pet.breed ?? 'N/I', thmode),
                          _buildInfoRow(
                              context.tr('health.age_label'), _calculateAge(pet.birthDate, context), thmode),
                          _buildInfoRow(
                              context.tr('health.birth_label'),
                              pet.birthDate != null
                                  ? DateFormat('dd/MM/yyyy')
                                      .format(pet.birthDate!)
                                  : '--/--/--',
                              thmode),
                          _buildInfoRow(
                              context.tr('health.blood_label'), pet.bloodType ?? 'N/I', thmode),
                          _buildInfoRow(
                              context.tr('health.weight_label'),
                              pet.weight != null ? '${pet.weight} kg' : 'N/I',
                              thmode),
                        ],
                      ),
                    ),
                    const VerticalDivider(width: 30, thickness: 1),
                    // Coluna da Direita: Status de Vacinação
                    Expanded(
                      flex: 55,
                      child: FutureBuilder<List<PetVaccine>>(
                        future: _vaccinesFuture,
                        builder: (context, snapshot) {
                          final vaccines = snapshot.data ?? [];
                          final hasVax = vaccines.isNotEmpty;

                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                hasVax
                                    ? context.tr('health.vaccine_status_updated')
                                    : context.tr('health.no_vaccines_saved'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: thmode.darkMode
                                        ? Colors.white
                                        : AppColors.darkBG,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              if (hasVax) ...[
                                Text(
                                  context.tr('health.last_dose'),
                                  style: TextStyle(
                                      color: thmode.darkMode
                                          ? Colors.white60
                                          : Colors.black54,
                                      fontSize: 11),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${vaccines.first.name}\n(${DateFormat('dd/MM/yy').format(vaccines.first.applicationDate)})',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: AppColors.patasColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  MaterialButton(
                                    onPressed: () =>
                                        _scheduleVaccineReminder(pet),
                                    color: AppColors.patasColor,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    height: 32,
                                    minWidth: 80,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: Text(context.tr('health.reminders_btn'),
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 10)),
                                  ),
                                  const SizedBox(width: 4),
                                  SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: IconButton(
                                      onPressed: _showActiveRemindersDialog,
                                      icon: const Icon(
                                          Icons.notifications_active,
                                          size: 18),
                                      padding: EdgeInsets.zero,
                                      color: AppColors.patasColor,
                                      tooltip: context.tr('health.view_reminders_tooltip'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, DarkMode thmode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
                fontSize: 12,
                color: thmode.darkMode ? Colors.white60 : Colors.black54,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 12,
                color: thmode.darkMode ? Colors.white : AppColors.darkBG,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _calculateAge(DateTime? birthDate, BuildContext context) {
    if (birthDate == null) return 'N/A';
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age <= 0
        ? context.tr('health.puppy_label')
        : context.tr('health.years_old', {'years': age.toString()});
  }

  Widget _buildSuggestedTable(Pet pet, DarkMode thmode, {bool isDesktop = false}) {
    bool isDog = pet.species.toLowerCase() == 'canino';

    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: EdgeInsets.only(
            top: isDesktop ? 0 : 40, 
            bottom: isDesktop ? 16 : 6,
            left: isDesktop ? 0 : 23,
            right: 16,
          ),
          child: Text(
            isDog
                ? context.tr('health.suggested_dog')
                : context.tr('health.suggested_cat'),
            textAlign: isDesktop ? TextAlign.left : TextAlign.center,
            style: TextStyle(
                color: thmode.darkMode ? Colors.white : AppColors.darkBG,
                fontWeight: FontWeight.bold,
                fontSize: 16),
          ),
        ),
        Container(
          height: isDesktop ? 250 : 230,
          width: double.infinity,
          margin: EdgeInsets.symmetric(horizontal: isDesktop ? 0 : 16),
          child: Card(
            color: thmode.darkMode ? AppColors.darkBG : AppColors.bodyLight,
            elevation: isDesktop ? 10 : 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isDesktop ? 24 : 12),
              side: isDesktop 
                  ? BorderSide(color: (thmode.darkMode ? Colors.white : Colors.black).withValues(alpha: 0.05)) 
                  : BorderSide.none,
            ),
            child: Row(
              children: [
                // Coluna Fixa de Labels
                _buildTableLabels(thmode, isDog),
                // Linha do tempo horizontal
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children:
                          isDog ? _buildDogTimeline() : _buildCatTimeline(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTableLabels(DarkMode thmode, bool isDog) {
    final vaxNames = isDog
        ? ['Múltipla (V8/V10)', 'Gripe', 'Raiva', 'Giardíase']
        : ['Tríplice/Quádrupla', 'Leucemia (FeLV)', 'Raiva', '-'];

    return Column(
      children: [
        Container(
          height: 40,
          width: 120,
          alignment: Alignment.center,
          child: Text(context.tr('health.vaccines_column_header'),
              style: TextStyle(
                  color: thmode.darkMode ? Colors.white : AppColors.darkBG,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
        ),
        ...vaxNames.map((name) => Container(
              height: 40,
              width: 120,
              color: AppColors.patasColor,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 11)),
            )),
      ],
    );
  }

  List<Widget> _buildDogTimeline() {
    return [
      _buildVaxColumn('6 Semanas', [true, false, false, false]),
      _buildVaxColumn('9 Semanas', [true, true, false, true]),
      _buildVaxColumn('12 Semanas', [true, true, true, true]),
      _buildVaxColumn('Anual', [true, true, true, true], isAnnual: true),
    ];
  }

  List<Widget> _buildCatTimeline() {
    return [
      _buildVaxColumn('8 Semanas', [true, true, false, false]),
      _buildVaxColumn('12 Semanas', [true, true, true, false]),
      _buildVaxColumn('Anual', [true, true, true, false], isAnnual: true),
    ];
  }

  Widget _buildVaxColumn(String title, List<bool> checks,
      {bool isAnnual = false}) {
    return Container(
      width: 100,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        children: [
          Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isAnnual ? Colors.green : AppColors.patasLightColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
          ...checks.map((check) => Container(
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12, width: 0.5),
                ),
                child: check
                    ? const Icon(Icons.check_circle,
                        color: AppColors.patasColor, size: 20)
                    : const SizedBox(),
              )),
        ],
      ),
    );
  }

  Widget _buildWalletSection(Pet pet, DarkMode thmode, {bool isDesktop = false}) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: EdgeInsets.only(
            top: isDesktop ? 40 : 40, 
            bottom: isDesktop ? 20 : 12,
            left: isDesktop ? 0 : 23,
          ),
          child: Text(
            context.tr('health.vaccination_record_section'),
            textAlign: isDesktop ? TextAlign.left : TextAlign.center,
            style: TextStyle(
                color: thmode.darkMode ? Colors.white : AppColors.darkBG,
                fontWeight: FontWeight.bold,
                fontSize: isDesktop ? 24 : 20),
          ),
        ),
        Container(
          width: double.infinity,
          margin: EdgeInsets.only(
            bottom: isDesktop ? 40 : 150, 
            left: isDesktop ? 0 : 16, 
            right: isDesktop ? 0 : 16,
          ),
          child: Card(
            color: thmode.darkMode ? AppColors.darkBG : AppColors.bodyLight,
            elevation: isDesktop ? 10 : 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isDesktop ? 24 : 15),
              side: isDesktop 
                  ? BorderSide(color: (thmode.darkMode ? Colors.white : Colors.black).withValues(alpha: 0.05)) 
                  : BorderSide.none,
            ),
            child: Column(
              children: [
                FutureBuilder<List<PetVaccine>>(
                  future: _vaccinesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (snapshot.hasError) {
                      return const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text('Erro ao carregar vacinas.'),
                      );
                    }

                    final vaccines = snapshot.data ?? [];
                    if (vaccines.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          context.tr('health.no_vaccine_applied_yet'),
                          style: TextStyle(
                            color: thmode.darkMode
                                ? Colors.white70
                                : Colors.black54,
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: vaccines.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final vax = vaccines[index];
                        return ListTile(
                          leading: const Icon(Icons.vaccines,
                              color: AppColors.patasColor),
                          title: Text(vax.name,
                              style: TextStyle(
                                  color: thmode.darkMode
                                      ? Colors.white
                                      : AppColors.darkBG,
                                  fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              DateFormat('dd/MM/yyyy')
                                  .format(vax.applicationDate),
                              style: TextStyle(
                                  color: thmode.darkMode
                                      ? Colors.white60
                                      : Colors.black54,
                                  fontSize: 12)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.redAccent, size: 20),
                            onPressed: () {
                              _deleteVaccine(vax.id);
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: MaterialButton(
                    onPressed: () => _showAddVaccineDialog(pet),
                    color: AppColors.patasColor,
                    minWidth: double.infinity,
                    height: 50,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    child: Text(context.tr('health.register_new_dose_btn'),
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _scheduleVaccineReminder(Pet pet) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      helpText: 'Data da próxima dose',
      builder: (context, child) {
        final thmode = Provider.of<DarkMode>(context, listen: false);
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.patasColor,
              onPrimary: Colors.white,
              onSurface: thmode.darkMode ? Colors.white : AppColors.darkBG,
              surface: thmode.darkMode ? AppColors.darkBG : Colors.white,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor:
                  thmode.darkMode ? AppColors.darkBG : Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 9, minute: 0),
        helpText: 'Horário do lembrete',
        builder: (context, child) {
          final thmode = Provider.of<DarkMode>(context, listen: false);
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: AppColors.patasColor,
                onPrimary: Colors.white,
                onSurface: thmode.darkMode ? Colors.white : AppColors.darkBG,
                surface: thmode.darkMode ? AppColors.darkBG : Colors.white,
              ),
              dialogTheme: DialogThemeData(
                backgroundColor:
                    thmode.darkMode ? AppColors.darkBG : Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null && mounted) {
        final scheduledDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        // Gerar um ID único baseado no tempo (limitando a 31 bits para Android)
        final int notificationId =
            DateTime.now().millisecondsSinceEpoch.remainder(100000);

        await NotificationService().scheduleNotification(
          id: notificationId,
          title: 'Lembrete de Vacina: ${pet.name}',
          body: 'Está na hora da próxima dose de vacinação do seu pet! 🐾💉',
          scheduledDate: scheduledDateTime,
          payload: 'health', // Payload para Deep Link
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lembrete agendado para ${DateFormat('dd/MM/yy HH:mm').format(scheduledDateTime)}!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _showAddVaccineDialog(Pet pet) {
    final nameController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(context.tr('health.register_vaccine_dialog_title')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nome da Vacina',
                  hintText: context.tr('health.vaccine_name_hint'),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                title: Text(context.tr('health.application_date_label')),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedDate = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.tr('common.cancel'))),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) return;

                final newVax = PetVaccine(
                  id: '',
                  petId: pet.id,
                  name: nameController.text.trim(),
                  applicationDate: selectedDate,
                );

                await _healthService.addVaccine(newVax);
                if (!context.mounted) return;
                Navigator.pop(context);
                _refresh();
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.patasColor),
              child:
                  const Text('Salvar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showActiveRemindersDialog() async {
    final reminders = await NotificationService().getScheduledReminders();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        final thmode = Provider.of<DarkMode>(context);
        return AlertDialog(
          backgroundColor: thmode.darkMode ? AppColors.darkBG : Colors.white,
          title: Text(
            'Meus Lembretes',
            style: TextStyle(
              color: thmode.darkMode ? Colors.white : AppColors.darkBG,
            ),
          ),
          content: reminders.isEmpty
              ? SizedBox(
                  height: 100,
                  child: Center(
                    child: Text(context.tr('health.no_reminders_scheduled'),
                        style: TextStyle(
                            color: thmode.darkMode
                                ? Colors.white54
                                : Colors.black54)),
                  ),
                )
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: reminders.length,
                    itemBuilder: (context, index) {
                      final reminder = reminders[index];
                      final date = DateTime.parse(reminder['date']);
                      return ListTile(
                        leading: const Icon(Icons.alarm,
                            color: AppColors.patasColor),
                        title: Text(
                          reminder['title'],
                          style: TextStyle(
                            fontSize: 13,
                            color: thmode.darkMode
                                ? Colors.white
                                : AppColors.darkBG,
                          ),
                        ),
                        subtitle: Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(date),
                          style: TextStyle(
                            fontSize: 11,
                            color: thmode.darkMode
                                ? Colors.white60
                                : Colors.black54,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.cancel,
                              color: Colors.red, size: 20),
                          onPressed: () async {
                            await NotificationService()
                                .cancelNotification(reminder['id']);
                            if (!context.mounted) return;
                            Navigator.pop(context);
                            _showActiveRemindersDialog(); // Recarregar
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Lembrete cancelado!'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr('common.close')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteVaccine(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Registro'),
        content:
            const Text('Deseja realmente excluir este registro de vacina?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.tr('common.cancel'))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Excluir', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await _healthService.deleteVaccine(id);
      _refresh();
    }
  }
}
