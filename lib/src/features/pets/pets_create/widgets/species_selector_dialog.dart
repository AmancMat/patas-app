import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/core/localization/app_localizations.dart';

class SpeciesSelectorDialog extends StatefulWidget {
  final String title;
  final List<String> popularSpecies;
  final IconData itemIcon;

  const SpeciesSelectorDialog({
    super.key,
    required this.title,
    required this.popularSpecies,
    this.itemIcon = Icons.pets,
  });

  @override
  State<SpeciesSelectorDialog> createState() => _SpeciesSelectorDialogState();
}

class _SpeciesSelectorDialogState extends State<SpeciesSelectorDialog> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customController = TextEditingController();
  List<String> _filteredSpecies = [];
  bool _showCustomInput = false;

  @override
  void initState() {
    super.initState();
    _filteredSpecies = widget.popularSpecies;
    _searchController.addListener(_filterList);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customController.dispose();
    super.dispose();
  }

  void _filterList() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSpecies = widget.popularSpecies
          .where((species) => species.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;
    final textColor = isDark ? Colors.white : AppColors.darkBG;
    final dialogBg = isDark ? AppColors.darkBG : Colors.white;
    final cardColor = isDark 
        ? Colors.white.withValues(alpha: 0.05) 
        : const Color(0xFFF6F6F8); // Cinza claro moderno para destacar os cards no fundo branco

    return Dialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: textColor,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: textColor.withValues(alpha: 0.6)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!_showCustomInput) ...[
              TextField(
                controller: _searchController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: context.tr('pet_create.search_species_hint'),
                  hintStyle: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54),
                  prefixIcon: const Icon(Icons.search, color: AppColors.patasColor),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filteredSpecies.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _filteredSpecies.length) {
                      // Opção para digitar espécie customizada no final da lista
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _showCustomInput = true;
                            });
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.patasColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.edit, color: AppColors.patasColor),
                                const SizedBox(width: 12),
                                Text(
                                  context.tr('pet_create.custom_species_btn'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.patasColor,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    final species = _filteredSpecies[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: InkWell(
                        onTap: () => Navigator.pop(context, species),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(widget.itemIcon,
                                  size: 16, color: AppColors.patasColor),
                              const SizedBox(width: 12),
                              Text(
                                species,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else ...[
              // Input para digitar espécie manualmente
              Text(
                context.tr('pet_create.type_species_name'),
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _customController,
                autofocus: true,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Ex: Calopsita Cara Branca, Hamster Anão...',
                  hintStyle: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showCustomInput = false;
                      });
                    },
                    child: Text(
                      context.tr('common.back'),
                      style: TextStyle(color: textColor.withValues(alpha: 0.6)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      final val = _customController.text.trim();
                      if (val.isNotEmpty) {
                        Navigator.pop(context, val);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.patasColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    child: Text(
                      context.tr('pet_create.confirm_species'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
