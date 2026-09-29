import 'package:flutter/material.dart';
import 'package:app_campi/core/theme/app_theme.dart';

class MatchCard extends StatelessWidget {
  final double screenWidth;
  final Map<String, dynamic> rawPartita;
  final String dataOrario;
  final String nomeCentroSportivo;
  final String indirizzoCentro;
  final String tipoSport;
  final double distanzaKm;
  final int giocatoriAttuali;
  final int giocatoriMassimi;
  final Color coloreTema;
  final bool isIscritto;
  final String nomeOrganizzatore;
  final int? etaOrganizzatore;
  final VoidCallback onTap;

  const MatchCard({
    super.key,
    required this.screenWidth,
    required this.rawPartita,
    required this.dataOrario,
    required this.nomeCentroSportivo,
    required this.indirizzoCentro,
    required this.tipoSport,
    required this.distanzaKm,
    required this.giocatoriAttuali,
    required this.giocatoriMassimi,
    required this.coloreTema,
    required this.isIscritto,
    this.nomeOrganizzatore = '',
    this.etaOrganizzatore,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final int segmentiTotali = giocatoriMassimi > 0 ? giocatoriMassimi : 10;
    final int segmentiPieni = giocatoriAttuali.clamp(0, segmentiTotali);

    final bool isARischio = tipoSport == "A Rischio" && !isIscritto;

    final Color coloreBordo = isIscritto
        ? AppTheme.accent.withOpacity(0.3)
        : (isARischio
              ? AppTheme.statoErrore.withOpacity(0.6)
              : AppTheme.cardBorder);

    return Container(
      width: screenWidth * 0.72,
      margin: const EdgeInsets.only(right: 16, bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppTheme.cardBg,
        border: Border.all(
          color: coloreBordo,
          width: isARischio || isIscritto ? 1.5 : 1,
        ),
        boxShadow: isARischio
            ? [
                BoxShadow(
                  color: AppTheme.statoErrore.withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : (isIscritto
                  ? [
                      BoxShadow(
                        color: AppTheme.accent.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : []),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 3,
                color: isIscritto ? AppTheme.accent : coloreTema,
              ),
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (isIscritto)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withOpacity(0.13),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_rounded,
                                  color: AppTheme.accent,
                                  size: 12,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  "SEI DENTRO",
                                  style: TextStyle(
                                    color: AppTheme.accent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: coloreTema.withOpacity(0.13),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              tipoSport,
                              style: TextStyle(
                                color: coloreTema,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 13,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              "${distanzaKm.toStringAsFixed(1)} km",
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                fontFamily: AppTheme.fontMono,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Text(
                      nomeCentroSportivo,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (indirizzoCentro.isNotEmpty) ...[
                      const SizedBox(height: 4),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              indirizzoCentro,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 5),

                    Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 12,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          dataOrario,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            fontFamily: AppTheme.fontMono,
                          ),
                        ),
                      ],
                    ),
                    if (nomeOrganizzatore.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline_rounded,
                            size: 11,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              etaOrganizzatore != null
                                  ? "Organizzato da $nomeOrganizzatore · $etaOrganizzatore anni"
                                  : "Organizzato da $nomeOrganizzatore",
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                                fontFamily: AppTheme.fontMono,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ] else
                      const SizedBox(height: 14),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Posti occupati",
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          "$giocatoriAttuali/$giocatoriMassimi",
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: AppTheme.fontMono,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: List.generate(segmentiTotali, (i) {
                        final bool pieno = i < segmentiPieni;
                        return Expanded(
                          child: Container(
                            height: 6,
                            margin: EdgeInsets.only(
                              right: i == segmentiTotali - 1 ? 0 : 3,
                            ),
                            decoration: BoxDecoration(
                              color: pieno
                                  ? (isIscritto
                                        ? AppTheme.accent
                                        : (isARischio
                                              ? AppTheme.statoErrore
                                              : AppTheme.accent))
                                  : Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
