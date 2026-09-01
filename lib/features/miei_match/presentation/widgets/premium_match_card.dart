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
        coloreTema = AppTheme.statoErrore;
        badgeLabel = "A RISCHIO";
        break;
      case 'annullata':
        coloreTema = AppTheme.textDisabled;
        badgeLabel = "ANNULLATA";
        break;
      case 'aperta_protetta':
      default:
        coloreTema = AppTheme.textPrimary;
        badgeLabel = "PROTETTA";
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
                      if (statoReale == 'aperta_protetta')
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: coloreTema.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.shield_outlined,
                                size: 12,
                                color: coloreTema,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "Scade: ${service.tempoRimanenteProtezione(partita)}",
                                style: TextStyle(
                                  color: coloreTema,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
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
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    partita.campo.nomeCampo,
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
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
                                nomeCampo: partita.campo.nomeCampo,
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
