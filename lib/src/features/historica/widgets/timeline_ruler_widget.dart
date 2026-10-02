import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../app.dart';
import '../../../constants/app_colors.dart';
import '../models/patas_historica_models.dart';

class TimelineRulerWidget extends StatefulWidget {
  final double initialZoom;
  final ValueChanged<TimelineGranularity> onGranularityChanged;
  final ValueChanged<double> onZoomChanged;

  const TimelineRulerWidget({
    super.key,
    this.initialZoom = 1.0,
    required this.onGranularityChanged,
    required this.onZoomChanged,
  });

  @override
  State<TimelineRulerWidget> createState() => _TimelineRulerWidgetState();
}

class _TimelineRulerWidgetState extends State<TimelineRulerWidget> {
  late double _zoomLevel;
  late TimelineGranularity _currentGranularity;

  @override
  void initState() {
    super.initState();
    _zoomLevel = widget.initialZoom;
    _currentGranularity = _calculateGranularity(_zoomLevel);
  }

  TimelineGranularity _calculateGranularity(double zoom) {
    if (zoom < 0.8) {
      return TimelineGranularity.years;
    } else if (zoom < 1.5) {
      return TimelineGranularity.months;
    } else if (zoom < 2.3) {
      return TimelineGranularity.weeks;
    } else {
      return TimelineGranularity.days;
    }
  }

  void _updateZoom(double newZoom) {
    final clampedZoom = newZoom.clamp(0.4, 3.2);
    if ((clampedZoom - _zoomLevel).abs() > 0.01) {
      final newGranularity = _calculateGranularity(clampedZoom);
      setState(() {
        _zoomLevel = clampedZoom;
      });

      widget.onZoomChanged(clampedZoom);

      if (newGranularity != _currentGranularity) {
        setState(() {
          _currentGranularity = newGranularity;
        });
        widget.onGranularityChanged(newGranularity);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;

    return Listener(
      onPointerSignal: (pointerSignal) {
        if (pointerSignal is PointerScrollEvent) {
          final isZoomHotkeyPressed = HardwareKeyboard.instance.isShiftPressed ||
              HardwareKeyboard.instance.isAltPressed ||
              HardwareKeyboard.instance.isControlPressed ||
              HardwareKeyboard.instance.isMetaPressed;

          if (isZoomHotkeyPressed || pointerSignal.scrollDelta.dy != 0) {
            final zoomDelta = pointerSignal.scrollDelta.dy < 0 ? 0.15 : -0.15;
            _updateZoom(_zoomLevel + zoomDelta);
          }
        }
      },
      child: GestureDetector(
        onScaleUpdate: (details) {
          if (details.scale != 1.0) {
            _updateZoom(_zoomLevel * details.scale);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: (isDark ? const Color(0xFF1E293B) : Colors.white).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.grey.shade200,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.patasColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.patasColor,
                      size: 15,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Escala: ${_currentGranularity.label}',
                      style: const TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.patasColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                onPressed: () => _updateZoom(_zoomLevel - 0.25),
                tooltip: 'Zoom Out (Afastar)',
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              const SizedBox(width: 4),
              Text(
                '${(_zoomLevel * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                onPressed: () => _updateZoom(_zoomLevel + 0.25),
                tooltip: 'Zoom In (Aproximar)',
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              if (MediaQuery.of(context).size.width > 600) ...[
                const SizedBox(width: 8),
                Text(
                  '💡 Touch: Pinch | Desktop: Shift + Scroll',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class CalendarTick {
  final String label;
  final double ratio; // 0.0 a 1.0

  CalendarTick({required this.label, required this.ratio});
}

class CenterRulerPainter extends CustomPainter {
  final TimelineGranularity granularity;
  final double zoomLevel;
  final bool isDark;
  final DateTime? minDate;
  final DateTime? maxDate;

  CenterRulerPainter({
    required this.granularity,
    required this.zoomLevel,
    required this.isDark,
    this.minDate,
    this.maxDate,
  });

  List<CalendarTick> _generateCalendarTicks(DateTime start, DateTime end) {
    final List<CalendarTick> ticks = [];
    final totalMs = end.millisecondsSinceEpoch - start.millisecondsSinceEpoch;
    if (totalMs <= 0) {
      return [CalendarTick(label: start.year.toString(), ratio: 0.5)];
    }

    const monthNames = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez'
    ];

    switch (granularity) {
      case TimelineGranularity.years:
        final startYear = start.year;
        final endYear = end.year;
        final totalYears = (endYear - startYear).clamp(1, 100);
        for (int i = 0; i <= totalYears; i++) {
          final year = startYear + i;
          final d = DateTime(year, 1, 1);
          final ratio = (d.millisecondsSinceEpoch - start.millisecondsSinceEpoch) / totalMs;
          if (ratio >= 0.0 && ratio <= 1.0) {
            ticks.add(CalendarTick(label: year.toString(), ratio: ratio));
          }
        }
        break;

      case TimelineGranularity.months:
        DateTime current = DateTime(start.year, start.month, 1);
        while (!current.isAfter(end)) {
          final ratio = (current.millisecondsSinceEpoch - start.millisecondsSinceEpoch) / totalMs;
          if (ratio >= 0.0 && ratio <= 1.0) {
            final label = '${monthNames[current.month - 1]}/${current.year.toString().substring(2)}';
            ticks.add(CalendarTick(label: label, ratio: ratio));
          }
          current = DateTime(current.year, current.month + 1, 1);
        }
        break;

      case TimelineGranularity.weeks:
        DateTime current = DateTime(start.year, start.month, start.day);
        while (!current.isAfter(end)) {
          final ratio = (current.millisecondsSinceEpoch - start.millisecondsSinceEpoch) / totalMs;
          if (ratio >= 0.0 && ratio <= 1.0) {
            final label = '${current.day.toString().padLeft(2, '0')}/${monthNames[current.month - 1]}';
            ticks.add(CalendarTick(label: label, ratio: ratio));
          }
          current = current.add(const Duration(days: 7));
        }
        break;

      case TimelineGranularity.days:
        DateTime current = DateTime(start.year, start.month, start.day);
        while (!current.isAfter(end)) {
          final ratio = (current.millisecondsSinceEpoch - start.millisecondsSinceEpoch) / totalMs;
          if (ratio >= 0.0 && ratio <= 1.0) {
            final label = '${current.day.toString().padLeft(2, '0')}/${current.month.toString().padLeft(2, '0')}';
            ticks.add(CalendarTick(label: label, ratio: ratio));
          }
          current = current.add(const Duration(days: 1));
        }
        break;
    }

    if (ticks.isEmpty) {
      ticks.add(CalendarTick(label: start.year.toString(), ratio: 0.0));
      ticks.add(CalendarTick(label: end.year.toString(), ratio: 1.0));
    }

    return ticks;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = isDark ? Colors.white38 : Colors.grey.shade400
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final accentPaint = Paint()
      ..color = AppColors.patasColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final textStyle = TextStyle(
      color: isDark ? Colors.white70 : AppColors.darkBG,
      fontSize: 11,
      fontFamily: 'Fredoka',
      fontWeight: FontWeight.bold,
    );

    final double centerY = size.height / 2;

    // Linha mestre central cortando a tela de ponta a ponta
    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      accentPaint,
    );

    final startDate = minDate ?? DateTime(2023, 1, 1);
    final endDate = maxDate ?? DateTime(2027, 12, 31);
    final ticks = _generateCalendarTicks(startDate, endDate);

    const double margin = 60.0;
    final double usableWidth = size.width - (margin * 2);

    for (int i = 0; i < ticks.length; i++) {
      final tick = ticks[i];
      final double x = margin + (tick.ratio * usableWidth);

      // Traço vertical central que cruza a linha mestre
      canvas.drawLine(
        Offset(x, centerY - 12),
        Offset(x, centerY + 12),
        accentPaint,
      );

      // Rótulo da data
      final textSpan = TextSpan(text: tick.label, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - (textPainter.width / 2), centerY + 16),
      );

      // Traços secundários entre marcas consecutivas
      if (i < ticks.length - 1) {
        final nextX = margin + (ticks[i + 1].ratio * usableWidth);
        final double distance = nextX - x;
        if (distance > 20) {
          final double subStep = distance / 4;
          for (int j = 1; j < 4; j++) {
            final double subX = x + (j * subStep);
            final double subHeight = (j == 2) ? 6.0 : 3.0;
            canvas.drawLine(
              Offset(subX, centerY - subHeight),
              Offset(subX, centerY + subHeight),
              linePaint,
            );
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CenterRulerPainter oldDelegate) {
    return oldDelegate.granularity != granularity ||
        oldDelegate.zoomLevel != zoomLevel ||
        oldDelegate.isDark != isDark ||
        oldDelegate.minDate != minDate ||
        oldDelegate.maxDate != maxDate;
  }
}
