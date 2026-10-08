import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:app_campi/core/models/partita.dart';
import 'package:app_campi/features/miei_match/application/partite_utente_provider.dart';
import 'package:app_campi/core/theme/app_theme.dart';

class CompactMatchCard extends ConsumerWidget {
  final Partita partita;
  final VoidCallback onTap;

  const CompactMatchCard({
    super.key,
    required this.partita,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(partitaServiceProvider);
    final statoReale = service.getStatoRealePartita(partita);

    final bool isARischio = statoReale == 'aperta_a_rischio';
    final Color coloreBaseCard = isARischio
        ? AppTheme.statoErrore
        : AppTheme.accent;

    final String mese = DateFormat(
      'MMM',
      'it_IT',
    ).format(partita.dataPartita).toUpperCase();
    final String giorno = DateFormat('d', 'it_IT').format(partita.dataPartita);
    final String oraInizio = partita.orarioInizio.length >= 5
        ? partita.orarioInizio.substring(0, 5)
        : partita.orarioInizio;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isARischio
                ? AppTheme.statoErrore.withOpacity(0.4)
                : AppTheme.cardBorder,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 85,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: coloreBaseCard.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                  border: Border(
                    right: BorderSide(
                      color: coloreBaseCard.withOpacity(0.2),
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      mese,
                      style: TextStyle(
                        color: coloreBaseCard,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      giorno,
                      style: TextStyle(
                        color: coloreBaseCard,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: coloreBaseCard.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        oraInizio,
                        style: TextStyle(
                          color: coloreBaseCard,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          fontFamily: AppTheme.fontMono,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isARischio ? "A RISCHIO" : "CONFERMATA",
                            style: TextStyle(
                              color: isARischio
                                  ? AppTheme.statoErrore
                                  : AppTheme.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
                            color: AppTheme.textSecondary.withOpacity(0.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        partita.campo.societa?.nomeSocieta ?? "Centro Sportivo",
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.sports_soccer,
                            size: 14,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              partita.campo.nomeCampo,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
