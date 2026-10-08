import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:patas_web_app/app.dart';
import 'package:patas_web_app/src/constants/app_colors.dart';
import 'package:patas_web_app/src/features/acolhe/models/shelter_event_model.dart';
import 'package:patas_web_app/src/features/acolhe/services/shelter_service.dart';
import 'package:patas_web_app/src/features/acolhe/screens/ong_events_dashboard_screen.dart';
import 'package:patas_web_app/src/localization/localizations_ext.dart';

class EventsFeedHighlightWidget extends StatefulWidget {
  const EventsFeedHighlightWidget({super.key});

  @override
  State<EventsFeedHighlightWidget> createState() =>
      _EventsFeedHighlightWidgetState();
}

class _EventsFeedHighlightWidgetState extends State<EventsFeedHighlightWidget> {
  final _shelterService = ShelterService();
  List<ShelterEvent> _upcomingEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      final events = await _shelterService.getEvents(onlyUpcoming: true);
      if (mounted) {
        setState(() {
          _upcomingEvents = events;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleAttendance(ShelterEvent event) async {
    final newAttending = !event.isUserAttending;

    setState(() {
      final idx = _upcomingEvents.indexWhere((e) => e.id == event.id);
      if (idx != -1) {
        _upcomingEvents[idx] = event.copyWith(
          isUserAttending: newAttending,
          attendeesCount: newAttending
              ? event.attendeesCount + 1
              : (event.attendeesCount > 0 ? event.attendeesCount - 1 : 0),
        );
      }
    });

    try {
      await _shelterService.toggleEventAttendance(
        eventId: event.id,
        currentlyAttending: event.isUserAttending,
      );
    } catch (_) {
      _loadEvents();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _upcomingEvents.isEmpty) {
      return const SizedBox.shrink();
    }

    final thmode = Provider.of<DarkMode>(context);
    final isDark = thmode.darkMode;
    final event = _upcomingEvents.first;
    final dateFormat = DateFormat('dd/MM');
    final timeFormat = DateFormat('HH:mm');
    final dateStr =
        '${dateFormat.format(event.startDate)} ${context.tr('feed.event_at')} ${timeFormat.format(event.startDate)}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header com Badge e botão Ver Mais
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.deepPurpleAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.campaign_rounded,
                    color: Colors.deepPurpleAccent,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  context.tr('feed.confirmed_fair'),
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: isDark
                        ? const Color(0xFF93C5FD)
                        : const Color(0xFF1D4ED8),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OngEventsDashboardScreen(),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Text(
                        context.tr('feed.view_all_events', {'count': '${_upcomingEvents.length}'}),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.deepPurpleAccent,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: Colors.deepPurpleAccent,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Banner ou Foto se houver
          if (event.bannerUrl != null && event.bannerUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 21 / 9,
                  child: Image.network(
                    event.bannerUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título
                Text(
                  event.title,
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.darkBG,
                  ),
                ),
                const SizedBox(height: 6),

                // Data e Local
                Row(
                  children: [
                    Icon(
                      Icons.event_rounded,
                      size: 14,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.place_rounded,
                      size: 14,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.locationName,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Botão RSVP e Contador
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _toggleAttendance(event),
                        icon: Icon(
                          event.isUserAttending
                              ? Icons.check_circle_rounded
                              : Icons.celebration_rounded,
                          size: 15,
                        ),
                        label: Text(
                          event.isUserAttending
                              ? context.tr('feed.presence_confirmed')
                              : context.tr('feed.will_attend'),
                          style: const TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: event.isUserAttending
                              ? Colors.green
                              : Colors.deepPurpleAccent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F172A)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        context.tr('feed.confirmed_attendees', {'count': '${event.attendeesCount}'}),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
