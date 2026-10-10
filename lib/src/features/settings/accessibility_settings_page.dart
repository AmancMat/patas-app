import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/localization/localizations_ext.dart';
import 'package:patas_web_app/src/providers/accessibility_provider.dart';
import 'package:patas_web_app/src/providers/font_size_provider.dart';
import 'package:provider/provider.dart';

import '../../../app.dart';

class AccessibilitySettingsPanel extends StatelessWidget {
  const AccessibilitySettingsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context.tr('accessibility.section_view'), isDark),
          _buildFontSizeControl(context, isDark),
          const SizedBox(height: 16),
          _buildColorBlindControl(context, isDark),
          const SizedBox(height: 24),

          _buildSectionTitle(context.tr('accessibility.section_motion'), isDark),
          _buildReduceMotionControl(context, isDark),
          const SizedBox(height: 16),
          _buildExpandedSpacingControl(context, isDark),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, left: 8.0),
      child: Text(
        title,
        style: TextStyle(
          color: isDark ? AppColors.patasColor : AppColors.patasColor,
          fontWeight: FontWeight.bold,
          fontSize: 18,
          fontFamily: 'Fredoka',
        ),
      ),
    );
  }

  Widget _buildFontSizeControl(BuildContext context, bool isDark) {
    return Consumer<FontSizeProvider>(
      builder: (context, fontProvider, child) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBG : AppColors.bodyLight,
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('accessibility.font_size_title'),
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.darkBG,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFamily: 'Fredoka',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('accessibility.font_size_desc'),
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFontButton(
                    context,
                    'A',
                    0.85,
                    'small',
                    fontProvider,
                    isDark,
                    14.0,
                  ),
                  _buildFontButton(
                    context,
                    'A',
                    1.0,
                    'normal',
                    fontProvider,
                    isDark,
                    18.0,
                  ),
                  _buildFontButton(
                    context,
                    'A',
                    1.2,
                    'large',
                    fontProvider,
                    isDark,
                    24.0,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFontButton(
    BuildContext context,
    String label,
    double multiplier,
    String level,
    FontSizeProvider provider,
    bool isDark,
    double iconSize,
  ) {
    final isSelected = provider.multiplier == multiplier;

    return InkWell(
      onTap: () {
        if (level == 'small') {
          provider.setSmall();
        } else if (level == 'large') {
          provider.setLarge();
        } else {
          provider.setNormal();
        }
      },
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.patasColor.withValues(alpha: 0.2)
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? AppColors.patasColor
                : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: iconSize,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? AppColors.patasColor
                  : (isDark ? Colors.white : AppColors.darkBG),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReduceMotionControl(BuildContext context, bool isDark) {
    return Consumer<AccessibilityProvider>(
      builder: (context, accProvider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBG : AppColors.bodyLight,
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('accessibility.reduce_motion_title'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.darkBG,
                        fontSize: 16,
                        fontFamily: 'Fredoka',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('accessibility.reduce_motion_desc'),
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoSwitch(
                activeTrackColor: AppColors.patasColor,
                value: accProvider.reduceMotion,
                onChanged: (val) {
                  accProvider.setReduceMotion(val);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpandedSpacingControl(BuildContext context, bool isDark) {
    return Consumer<AccessibilityProvider>(
      builder: (context, accProvider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBG : AppColors.bodyLight,
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('accessibility.expanded_spacing_title'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.darkBG,
                        fontSize: 16,
                        fontFamily: 'Fredoka',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('accessibility.expanded_spacing_desc'),
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoSwitch(
                activeTrackColor: AppColors.patasColor,
                value: accProvider.expandedSpacing,
                onChanged: (val) {
                  accProvider.setExpandedSpacing(val);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildColorBlindControl(BuildContext context, bool isDark) {
    return Consumer<AccessibilityProvider>(
      builder: (context, accProvider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBG : AppColors.bodyLight,
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('accessibility.colorblind_title'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.darkBG,
                  fontSize: 16,
                  fontFamily: 'Fredoka',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.tr('accessibility.colorblind_desc'),
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.bodygray : Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ColorBlindMode>(
                    value: accProvider.colorBlindMode,
                    dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    isExpanded: true,
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: isDark ? Colors.white : AppColors.darkBG,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: ColorBlindMode.none,
                        child: Text(
                          context.tr('accessibility.colorblind_none'),
                          style: TextStyle(
                            color: isDark ? Colors.white : AppColors.darkBG,
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: ColorBlindMode.protanopia,
                        child: Text(
                          context.tr('accessibility.colorblind_protanopia'),
                          style: TextStyle(
                            color: isDark ? Colors.white : AppColors.darkBG,
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: ColorBlindMode.deuteranopia,
                        child: Text(
                          context.tr('accessibility.colorblind_deuteranopia'),
                          style: TextStyle(
                            color: isDark ? Colors.white : AppColors.darkBG,
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: ColorBlindMode.tritanopia,
                        child: Text(
                          context.tr('accessibility.colorblind_tritanopia'),
                          style: TextStyle(
                            color: isDark ? Colors.white : AppColors.darkBG,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (ColorBlindMode? newValue) {
                      if (newValue != null) {
                        accProvider.setColorBlindMode(newValue);
                      }
                    },
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.darkBG,
                      fontSize: 14,
                      fontFamily: 'Fredoka',
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
