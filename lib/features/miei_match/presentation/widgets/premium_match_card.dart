import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:app_campi/core/models/partita.dart';
import 'package:app_campi/features/miei_match/application/partite_utente_provider.dart';
import 'package:app_campi/core/theme/app_theme.dart';
import 'package:app_campi/features/miei_match/presentation/widgets/live_timer_widget.dart';
import 'package:app_campi/core/shared_widget/status_badge.dart';
import 'package:app_campi/core/shared_widget/urgenza_badge.dart';
import 'package:app_campi/core/shared_widget/animated_fill_bar.dart';
import 'package:app_campi/features/chat/match_chat_page.dart';

class PremiumMatchCard extends ConsumerWidget {
  final Partita partita;
  final VoidCallback onTap;

  const PremiumMatchCard({
    super.key,
    required this.partita,
    required this.onTap,
  });

  String _nomeSport(String sport) {
    switch (sport.trim().toLowerCase()) {
      case 'tennis_singolo':
        return 'Tennis singolo';
      case 'tennis_doppio':
        return 'Tennis doppio';
      case 'padel':
        return 'Padel';
      case 'calcio_5':
        return 'Calcio a 5';
      case 'calcio_6':
        return 'Calcio a 6';
      case 'calcio_7':
        return 'Calcio a 7';
      case 'calcio_8':
        return 'Calcio a 8';
      case 'calcio_11':
        return 'Calcio a 11';
      case 'basket':
        return 'Basket';
      case 'pallavolo':
      case 'volley':
        return 'Pallavolo';
      default:
        return sport;
    }
  }

  IconData _iconaSport(String sport) {
    final value = sport.trim().toLowerCase();

    if (value.startsWith('calcio_')) {
      return Icons.sports_soccer_rounded;
    }

    if (value == 'basket') {
      return Icons.sports_basketball_rounded;
    }

    if (value == 'pallavolo' || value == 'volley') {
      return Icons.sports_volleyball_rounded;
    }

    if (value == 'padel' || value.startsWith('tennis_')) {
      return Icons.sports_tennis_rounded;
    }

    return Icons.sports_rounded;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(partitaServiceProvider);
    final statoReale = service.getStatoRealePartita(partita);

    Color coloreTema;
    String badgeLabel;

    switch (statoReale) {
      case 'completa':
        coloreTema = AppTheme.statoSuccesso;
        badgeLabel = "COMPLETA";
        break;

      case 'aperta_a_rischio':
        coloreTema = AppTheme.accent;
        badgeLabel = "APERTA";
        break;

      case 'annullata':
        coloreTema = AppTheme.textDisabled;
        badgeLabel = "ANNULLATA";
        break;

      default:
        coloreTema = AppTheme.textPrimary;
        badgeLabel = "APERTA";
        break;
    }

    final int giocatoriAttuali = partita.numeroGiocatoriPrenotati;
    // 🔴 Usa il calcolo dinamico dei giocatori massimi!
    final int giocatoriMassimi = partita.maxGiocatoriReali;
    final int postiRimasti = (giocatoriMassimi - giocatoriAttuali).clamp(
      0,
      giocatoriMassimi,
    );
    final bool mostraUrgenza =
        statoReale != 'completa' && UrgenzaBadge.shouldShow(postiRimasti);

    final String giornoFormattato = DateFormat(
      'EEE d MMM',
      'it_IT',
    ).format(partita.dataPartita).toUpperCase();
    final String oraInizioFormattata = partita.orarioInizio.length >= 5
        ? partita.orarioInizio.substring(0, 5)
        : partita.orarioInizio;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppTheme.cardBg,
        border: Border.all(
          color: coloreTema == AppTheme.textPrimary
              ? AppTheme.cardBorder
              : coloreTema.withOpacity(0.4),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: coloreTema.withOpacity(0.05),
            blurRadius: 15,
            spreadRadius: 0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: coloreTema.withOpacity(0.1),
            highlightColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          StatusBadge(label: badgeLabel, color: coloreTema),
                          if (mostraUrgenza) ...[
                            const SizedBox(width: 8),
                            UrgenzaBadge(postiRimasti: postiRimasti),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              partita.campo.societa?.nomeSocieta ??
                                  "Centro Sportivo",
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    [
                                          [
                                                partita
                                                    .campo
                                                    .societa
                                                    ?.viaStrutturata,
                                                partita.campo.societa?.civico,
                                              ]
                                              .where(
                                                (e) =>
                                                    e != null &&
                                                    e
                                                        .toString()
                                                        .trim()
                                                        .isNotEmpty,
                                              )
                                              .map((e) => e.toString().trim())
                                              .join(' '),

                                          [
                                                partita.campo.societa?.comune,
                                                partita
                                                    .campo
                                                    .societa
                                                    ?.provincia,
                                              ]
                                              .where(
                                                (e) =>
                                                    e != null &&
                                                    e
                                                        .toString()
                                                        .trim()
                                                        .isNotEmpty,
                                              )
                                              .map((e) => e.toString().trim())
                                              .join(' '),
                                        ]
                                        .where((e) => e.trim().isNotEmpty)
                                        .join(', '),
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppTheme.accent.withOpacity(0.20),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _iconaSport(partita.sport ?? ''),
                                    color: AppTheme.accent,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _nomeSport(partita.sport ?? ''),
                                    style: const TextStyle(
                                      color: AppTheme.accent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.darkBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: Text(
                          "${partita.quotaSingolaGiocatore.toStringAsFixed(2)}€",
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.darkBg.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              color: AppTheme.textSecondary,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              giornoFormattato,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule,
                              color: AppTheme.accent,
                              size: 15,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              oraInizioFormattata,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  AnimatedFillBar(
                    label: "Posti occupati",
                    valoreAttuale: giocatoriAttuali,
                    valoreMassimo: giocatoriMassimi,
                    colore: coloreTema == AppTheme.textPrimary
                        ? AppTheme.accent
                        : coloreTema,
                  ),

                  if (statoReale != 'completa' &&
                      statoReale != 'annullata') ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.only(top: 12),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppTheme.cardBorder, width: 1),
                        ),
                      ),
                      child: LiveTimerWidget(
                        dataPartita: partita.dataPartita,
                        orarioInizio: partita.orarioInizio,
                      ),
                    ),
                  ],

                  // 🟢 PULSANTE CHAT: Visibile solo se la partita è di matchmaking (isPublic == true)
                  // e non è annullata (quindi sia aperta sia completata)
                  if (partita.isPublic && statoReale != 'annullata') ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppTheme.neonCyan.withOpacity(0.08),
                          foregroundColor: AppTheme.neonCyan,
                          side: BorderSide(
                            color: AppTheme.neonCyan.withOpacity(0.4),
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        icon: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 18,
                        ),
                        label: Text(
                          statoReale == 'completa'
                              ? "CHAT PARTITA"
                              : "APRI CHAT",
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            letterSpacing: 1.0,
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MatchChatPage(
                                matchId: partita.id,
                                nomeSocieta:
                                    partita.campo.societa?.nomeSocieta ??
                                    'Centro Sportivo',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
