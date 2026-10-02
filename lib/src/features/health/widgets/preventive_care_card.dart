import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/features/pets/models/pet_model.dart';
import 'package:patas_web_app/src/common_widgets/patas_button.dart';

class PreventiveCareCard extends StatefulWidget {
  final Pet activePet;
  const PreventiveCareCard({super.key, required this.activePet});

  @override
  State<PreventiveCareCard> createState() => _PreventiveCareCardState();
}

class _PreventiveCareCardState extends State<PreventiveCareCard> {
  DateTime? _lastDewormerDate;
  int _dewormerMonthsInterval = 3; // Padrão: 3 meses
  String _dewormerProductName = '';

  DateTime? _lastFleaDate;
  int _fleaDaysInterval = 30; // Padrão: 30 dias (1 mês)
  String _fleaProductName = '';

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreventiveData();
  }

  @override
  void didUpdateWidget(covariant PreventiveCareCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activePet.id != widget.activePet.id) {
      _loadPreventiveData();
    }
  }

  Future<void> _loadPreventiveData() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final petId = widget.activePet.id;

    final dewormerMs = prefs.getInt('dewormer_date_$petId');
    final dewormerInterval = prefs.getInt('dewormer_interval_$petId') ?? 3;
    final dewormerProduct = prefs.getString('dewormer_product_$petId') ?? '';

    final fleaMs = prefs.getInt('flea_date_$petId');
    final fleaInterval = prefs.getInt('flea_interval_$petId') ?? 30;
    final fleaProduct = prefs.getString('flea_product_$petId') ?? '';

    if (mounted) {
      setState(() {
        _lastDewormerDate = dewormerMs != null ? DateTime.fromMillisecondsSinceEpoch(dewormerMs) : null;
        _dewormerMonthsInterval = dewormerInterval;
        _dewormerProductName = dewormerProduct;

        _lastFleaDate = fleaMs != null ? DateTime.fromMillisecondsSinceEpoch(fleaMs) : null;
        _fleaDaysInterval = fleaInterval;
        _fleaProductName = fleaProduct;

        _isLoading = false;
      });
    }
  }

  Future<void> _saveDewormerDate(DateTime date, int intervalMonths, String productName) async {
    final prefs = await SharedPreferences.getInstance();
    final petId = widget.activePet.id;
    await prefs.setInt('dewormer_date_$petId', date.millisecondsSinceEpoch);
    await prefs.setInt('dewormer_interval_$petId', intervalMonths);
    await prefs.setString('dewormer_product_$petId', productName);

    setState(() {
      _lastDewormerDate = date;
      _dewormerMonthsInterval = intervalMonths;
      _dewormerProductName = productName;
    });
  }

  Future<void> _saveFleaDate(DateTime date, int intervalDays, String productName) async {
    final prefs = await SharedPreferences.getInstance();
    final petId = widget.activePet.id;
    await prefs.setInt('flea_date_$petId', date.millisecondsSinceEpoch);
    await prefs.setInt('flea_interval_$petId', intervalDays);
    await prefs.setString('flea_product_$petId', productName);

    setState(() {
      _lastFleaDate = date;
      _fleaDaysInterval = intervalDays;
      _fleaProductName = productName;
    });
  }

  void _openGoogleCalendar(String title, DateTime date, String details) async {
    final startTimeStr = DateFormat("yyyyMMdd'T'HHmmss'Z'").format(date.toUtc());
    final endTimeStr = DateFormat("yyyyMMdd'T'HHmmss'Z'").format(date.add(const Duration(hours: 1)).toUtc());

    final url = Uri.parse(
      'https://calendar.google.com/calendar/render?action=TEMPLATE&text=${Uri.encodeComponent(title)}&dates=$startTimeStr/$endTimeStr&details=${Uri.encodeComponent(details)}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _showRecordDialog({required bool isDewormer}) {
    DateTime selectedDate = DateTime.now();
    int interval = isDewormer ? _dewormerMonthsInterval : _fleaDaysInterval;
    TextEditingController productController = TextEditingController(
      text: isDewormer ? _dewormerProductName : _fleaProductName,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final thmode = Provider.of<DarkMode>(context);
        final isDark = thmode.darkMode;
        final title = isDewormer ? 'Registrar Vermifugação' : 'Registrar Antipulgas / Carrapatos';

        return StatefulBuilder(
          builder: (context, setModalState) {
            final mq = MediaQuery.of(context);
            return Padding(
              padding: EdgeInsets.only(
                bottom: mq.viewInsets.bottom + mq.viewPadding.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.darkBG,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Nome do Produto
                    TextField(
                      controller: productController,
                      style: TextStyle(color: isDark ? Colors.white : AppColors.darkBG),
                      decoration: InputDecoration(
                        labelText: 'Nome do Produto (Opcional)',
                        hintText: isDewormer ? 'Ex: Drontal, Endogard' : 'Ex: Bravecto, Simparica',
                        prefixIcon: Icon(
                          Icons.shopping_bag_outlined,
                          color: isDewormer ? Colors.teal : Colors.purple,
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Seletor de Data
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                        ),
                      ),
                      leading: Icon(
                        isDewormer ? Icons.medication_rounded : Icons.shield_rounded,
                        color: isDewormer ? Colors.teal : Colors.purple,
                      ),
                      title: const Text('Data da Aplicação'),
                      subtitle: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                      trailing: const Icon(Icons.calendar_today_rounded, size: 20),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setModalState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 14),

                    // Frequência
                    Text(
                      isDewormer ? 'Intervalo de Reaplicação' : 'Duração da Proteção',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 8),

                    if (isDewormer)
                      Wrap(
                        spacing: 8,
                        children: [3, 4, 6].map((m) {
                          final isSel = interval == m;
                          return ChoiceChip(
                            label: Text('$m Meses'),
                            selected: isSel,
                            selectedColor: Colors.teal,
                            onSelected: (val) {
                              if (val) setModalState(() => interval = m);
                            },
                          );
                        }).toList(),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        children: [30, 60, 90, 180].map((d) {
                          final isSel = interval == d;
                          final label = d >= 30 ? '${(d / 30).round()} M' : '$d Dias';
                          return ChoiceChip(
                            label: Text(label),
                            selected: isSel,
                            selectedColor: Colors.purple,
                            onSelected: (val) {
                              if (val) setModalState(() => interval = d);
                            },
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: PatasButton(
                        text: 'Salvar Registro',
                        onPressed: () {
                          final prodName = productController.text.trim();
                          if (isDewormer) {
                            _saveDewormerDate(selectedDate, interval, prodName);
                          } else {
                            _saveFleaDate(selectedDate, interval, prodName);
                          }
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Registro preventivo salvo com sucesso! 🛡️'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;
    final now = DateTime.now();

    // Cálculos de Vermífugo
    DateTime? nextDewormerDate;
    int dewormerDaysRemaining = 0;
    double dewormerRatio = 0.0;
    bool dewormerOverdue = false;

    if (_lastDewormerDate != null) {
      nextDewormerDate = DateTime(
        _lastDewormerDate!.year,
        _lastDewormerDate!.month + _dewormerMonthsInterval,
        _lastDewormerDate!.day,
      );
      dewormerDaysRemaining = nextDewormerDate.difference(now).inDays;
      dewormerOverdue = now.isAfter(nextDewormerDate);

      final totalDays = nextDewormerDate.difference(_lastDewormerDate!).inDays;
      final passedDays = now.difference(_lastDewormerDate!).inDays;
      dewormerRatio = totalDays > 0 ? (passedDays / totalDays).clamp(0.0, 1.0) : 1.0;
    }

    // Cálculos de Antipulgas
    DateTime? nextFleaDate;
    int fleaDaysRemaining = 0;
    double fleaRatio = 0.0;
    bool fleaOverdue = false;

    if (_lastFleaDate != null) {
      nextFleaDate = _lastFleaDate!.add(Duration(days: _fleaDaysInterval));
      fleaDaysRemaining = nextFleaDate.difference(now).inDays;
      fleaOverdue = now.isAfter(nextFleaDate);

      final totalDays = nextFleaDate.difference(_lastFleaDate!).inDays;
      final passedDays = now.difference(_lastFleaDate!).inDays;
      fleaRatio = totalDays > 0 ? (passedDays / totalDays).clamp(0.0, 1.0) : 1.0;
    }

    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBG : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: Colors.teal,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Controle Preventivo',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.darkBG,
                    ),
                  ),
                  Text(
                    'Vermífugos, Antipulgas & Carrapatos',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else ...[
            // Card 1: Vermífugo
            _buildPreventiveTile(
              isDark: isDark,
              title: 'Vermifugação',
              productName: _dewormerProductName,
              icon: Icons.medication_rounded,
              color: Colors.teal,
              lastDate: _lastDewormerDate != null ? dateFormat.format(_lastDewormerDate!) : 'Não informado',
              nextDate: nextDewormerDate != null ? dateFormat.format(nextDewormerDate) : 'Sem previsão',
              nextDateTime: nextDewormerDate,
              daysRemaining: dewormerDaysRemaining,
              progressRatio: dewormerRatio,
              isOverdue: dewormerOverdue,
              onTap: () => _showRecordDialog(isDewormer: true),
            ),

            const SizedBox(height: 14),

            // Card 2: Antipulgas
            _buildPreventiveTile(
              isDark: isDark,
              title: 'Antipulgas / Carrapatos',
              productName: _fleaProductName,
              icon: Icons.bug_report_rounded,
              color: Colors.purple,
              lastDate: _lastFleaDate != null ? dateFormat.format(_lastFleaDate!) : 'Não informado',
              nextDate: nextFleaDate != null ? dateFormat.format(nextFleaDate) : 'Sem previsão',
              nextDateTime: nextFleaDate,
              daysRemaining: fleaDaysRemaining,
              progressRatio: fleaRatio,
              isOverdue: fleaOverdue,
              onTap: () => _showRecordDialog(isDewormer: false),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreventiveTile({
    required bool isDark,
    required String title,
    required String productName,
    required IconData icon,
    required Color color,
    required String lastDate,
    required String nextDate,
    required DateTime? nextDateTime,
    required int daysRemaining,
    required double progressRatio,
    required bool isOverdue,
    required VoidCallback onTap,
  }) {
    String statusBadgeText;
    Color badgeColor;

    if (nextDateTime == null) {
      statusBadgeText = 'Não configurado';
      badgeColor = Colors.grey;
    } else if (isOverdue) {
      final daysPast = daysRemaining.abs();
      statusBadgeText = 'Atrasado há $daysPast dia${daysPast == 1 ? "" : "s"}';
      badgeColor = Colors.red;
    } else if (daysRemaining <= 7) {
      statusBadgeText = 'Vence em $daysRemaining dia${daysRemaining == 1 ? "" : "s"}!';
      badgeColor = Colors.orange;
    } else {
      statusBadgeText = 'Faltam $daysRemaining dias';
      badgeColor = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isOverdue ? Colors.red : color).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.darkBG,
                          ),
                        ),
                        if (productName.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            '($productName)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Última: $lastDate  •  Próxima: $nextDate',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, size: 22),
                color: color,
                onPressed: onTap,
                tooltip: 'Registrar Dose',
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Barra de Progresso do Ciclo
          if (nextDateTime != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progressRatio,
                minHeight: 5,
                backgroundColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(badgeColor),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Footer Status & Botão de Agenda
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOverdue ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                      size: 14,
                      color: badgeColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      statusBadgeText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ),

              if (nextDateTime != null)
                InkWell(
                  onTap: () {
                    final details = 'Dose de $title do pet ${widget.activePet.name}${productName.isNotEmpty ? " ($productName)" : ""}';
                    _openGoogleCalendar('Dose de $title — ${widget.activePet.name}', nextDateTime, details);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, size: 14, color: Colors.blue),
                        const SizedBox(width: 4),
                        const Text(
                          'Agenda 📅',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
