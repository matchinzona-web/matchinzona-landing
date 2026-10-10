import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:app_campi/core/theme/app_theme.dart';

class WidgetCalendarioGestore extends StatelessWidget {
  final CalendarController controller;
  final bool isLoading;
  final List<Appointment> prenotazioniVisibili;
  final double startHour;
  final double endHour;
  final Function(CalendarTapDetails) onTap;
  final Function(ViewChangedDetails) onViewChanged;
  final ScrollController? mainScrollController;
  final bool giornoChiuso;
  final DateTime minDate;

  const WidgetCalendarioGestore({
    super.key,
    required this.controller,
    required this.isLoading,
    required this.prenotazioniVisibili,
    required this.startHour,
    required this.endHour,
    required this.onTap,
    required this.onViewChanged,
    this.mainScrollController,
    required this.giornoChiuso,
    required this.minDate,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.neonOrange),
      );
    }

    final double oreVisibili = giornoChiuso ? 3.0 : (endHour - startHour);

    final double altezzaCalendario = oreVisibili * 60 + 40;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        border: Border.all(color: Colors.white.withOpacity(0.055), width: 1),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        child: SizedBox(
          height: altezzaCalendario,
          child: Listener(
            onPointerMove: (pointerMoveEvent) {
              if (mainScrollController != null &&
                  mainScrollController!.hasClients) {
                mainScrollController!.position.jumpTo(
                  (mainScrollController!.offset - pointerMoveEvent.delta.dy)
                      .clamp(
                        0.0,
                        mainScrollController!.position.maxScrollExtent,
                      ),
                );
              }
            },
            child: Stack(
              children: [
                SfCalendar(
                  controller: controller,
                  view: CalendarView.day,
                  headerHeight: 0,
                  firstDayOfWeek: 1,
                  backgroundColor: AppTheme.cardBg,
                  viewNavigationMode: ViewNavigationMode.none,

                  minDate: minDate,

                  maxDate: DateTime(
                    DateTime.now().year,
                    DateTime.now().month,
                    DateTime.now().day,
                    23,
                    59,
                    59,
                  ).add(const Duration(days: 13)),

                  dataSource: _PartiteDataSource(prenotazioniVisibili),

                  onTap: onTap,

                  // =====================================================
                  // CARD PRENOTAZIONI
                  // =====================================================
                  appointmentBuilder:
                      (
                        BuildContext context,
                        CalendarAppointmentDetails details,
                      ) {
                        if (details.appointments.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        final Appointment appointment =
                            details.appointments.first;

                        return _AppointmentCard(appointment: appointment);
                      },

                  viewHeaderStyle: const ViewHeaderStyle(
                    dayTextStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                    dateTextStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  timeSlotViewSettings: TimeSlotViewSettings(
                    timeFormat: 'HH:mm',

                    timeTextStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),

                    startHour: giornoChiuso ? 8.0 : startHour,
                    endHour: giornoChiuso ? 11.0 : endHour,

                    timeInterval: const Duration(hours: 1),
                    timeIntervalHeight: 60,
                  ),

                  onViewChanged: onViewChanged,
                ),

                if (giornoChiuso)
                  const Positioned.fill(child: _GiornoChiusoOverlay()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// CARD PRENOTAZIONE
// ===========================================================================

class _AppointmentCard extends StatelessWidget {
  final Appointment appointment;

  const _AppointmentCard({required this.appointment});

  bool get isChiusuraStraordinaria {
    final String subject = appointment.subject.toUpperCase();

    return subject.contains('CHIUSO') || subject.contains('⛔');
  }

  String _formatTime(DateTime dateTime) {
    final String hour = dateTime.hour.toString().padLeft(2, '0');

    final String minute = dateTime.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    if (isChiusuraStraordinaria) {
      return _buildChiusuraCard();
    }

    final Color accentColor = appointment.color;

    final String start = _formatTime(appointment.startTime);

    final String end = _formatTime(appointment.endTime);

    final String subject = appointment.subject.trim();

    final String? notes = appointment.notes?.trim().isNotEmpty == true
        ? appointment.notes!.trim()
        : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.45), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 3,
              child: DecoratedBox(
                decoration: BoxDecoration(color: accentColor),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(10, 7, 8, 7),
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final bool compatto = constraints.maxHeight < 58;

                  if (compatto) {
                    return _buildCompactContent(
                      start: start,
                      end: end,
                      subject: subject,
                      accentColor: accentColor,
                    );
                  }

                  return _buildNormalContent(
                    start: start,
                    end: end,
                    subject: subject,
                    notes: notes,
                    accentColor: accentColor,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNormalContent({
    required String start,
    required String end,
    required String subject,
    required String? notes,
    required Color accentColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.18),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                '$start – $end',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ),

            const Spacer(),

            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withOpacity(0.25),
              size: 17,
            ),
          ],
        ),

        const SizedBox(height: 5),

        Text(
          subject.isEmpty ? 'Prenotazione' : subject,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),

        if (notes != null) ...[
          const SizedBox(height: 2),
          Text(
            notes,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.52),
              fontSize: 10.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompactContent({
    required String start,
    required String end,
    required String subject,
    required Color accentColor,
  }) {
    return Row(
      children: [
        Text(
          '$start – $end',
          style: TextStyle(
            color: accentColor,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(width: 7),

        Expanded(
          child: Text(
            subject.isEmpty ? 'Prenotazione' : subject,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChiusuraCard() {
    final String start = _formatTime(appointment.startTime);
    final String end = _formatTime(appointment.endTime);

    final int durataMinuti = appointment.endTime
        .difference(appointment.startTime)
        .inMinutes;

    final bool compatta = durataMinuti <= 60;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.035),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: Colors.white.withOpacity(0.10), width: 1),
      ),
      child: compatta
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  'CHIUSO $start – $end',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            )
          : Row(
              children: [
                Container(
                  width: 3,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(11),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    color: Colors.grey.shade500,
                    size: 15,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CHIUSO',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$start – $end',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// ===========================================================================
// GIORNO CHIUSO
// ===========================================================================

class _GiornoChiusoOverlay extends StatelessWidget {
  const _GiornoChiusoOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.cardBg.withOpacity(0.95),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.22),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.045),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.lock_clock_rounded,
                  color: Colors.grey.shade400,
                  size: 28,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'CENTRO CHIUSO',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 7),

              Text(
                'Nessun orario disponibile per questa giornata',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// DATA SOURCE
// ===========================================================================

class _PartiteDataSource extends CalendarDataSource {
  _PartiteDataSource(List<Appointment> source) {
    appointments = source;
  }
}
