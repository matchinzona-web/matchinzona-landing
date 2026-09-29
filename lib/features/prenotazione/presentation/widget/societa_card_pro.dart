import 'package:flutter/material.dart';
import 'package:app_campi/core/models/societa.dart';
import 'package:app_campi/core/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:app_campi/core/shared_widget/app_image_placeholder.dart';

class SocietaCardPro extends StatelessWidget {
  final Societa societa;
  final String sport;
  final double prezzoPartenza;
  final String? distanzaKm;
  final VoidCallback onTap;

  const SocietaCardPro({
    super.key,
    required this.societa,
    required this.sport,
    required this.prezzoPartenza,
    this.distanzaKm,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 190,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      societa.fotoUrl != null && societa.fotoUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: societa.fotoUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, _) => Container(
                                color: AppTheme.darkBg,
                                alignment: Alignment.center,
                                child: const CircularProgressIndicator(
                                  color: AppTheme.accent,
                                  strokeWidth: 2,
                                ),
                              ),
                              errorWidget: (_, _, _) =>
                                  const AppImagePlaceholder(),
                            )
                          : const AppImagePlaceholder(),

                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.18),
                                Colors.black.withOpacity(0.92),
                              ],
                              stops: const [0.25, 0.55, 1],
                            ),
                          ),
                        ),
                      ),

                      Positioned(
                        top: 14,
                        left: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.12),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getSportIcon(sport),
                                color: AppTheme.accent,
                                size: 15,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatSport(sport),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                societa.nomeSocieta,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.1,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.accent,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'DA',
                                    style: TextStyle(
                                      color: AppTheme.darkBg,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  Text(
                                    '${prezzoPartenza.toStringAsFixed(0)} €/h',
                                    style: const TextStyle(
                                      color: AppTheme.darkBg,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: AppTheme.textSecondary,
                            size: 17,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${societa.citta} • ${societa.via}',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (distanzaKm != null) ...[
                            const SizedBox(width: 10),
                            Text(
                              distanzaKm!,
                              style: const TextStyle(
                                color: AppTheme.accent,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 14),

                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Scopri campi e disponibilità',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: AppTheme.accent,
                              size: 19,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getSportIcon(String sport) {
    final value = sport.toLowerCase();

    if (value.contains('calcio')) {
      return Icons.sports_soccer_rounded;
    }

    if (value.contains('padel') || value.contains('tennis')) {
      return Icons.sports_tennis_rounded;
    }

    if (value.contains('basket')) {
      return Icons.sports_basketball_rounded;
    }

    if (value.contains('pallavolo') || value.contains('volley')) {
      return Icons.sports_volleyball_rounded;
    }

    return Icons.sports_rounded;
  }

  String _formatSport(String sport) {
    switch (sport) {
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
      case 'tennis_singolo':
      case 'tennis_doppio':
        return 'Tennis';
      case 'padel':
        return 'Padel';
      case 'basket':
        return 'Basket';
      case 'pallavolo':
      case 'volley':
        return 'Pallavolo';
      default:
        return sport;
    }
  }
}
