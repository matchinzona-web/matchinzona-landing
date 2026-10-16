import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_campi/core/theme/app_theme.dart';
import 'package:app_campi/core/theme/app_constants.dart';
import 'package:app_campi/core/models/utente.dart';
import 'package:app_campi/core/services/location_provider.dart';
import 'package:app_campi/features/auth/application/auth_provider.dart';
import 'package:app_campi/core/shared_widget/fade_slide_in.dart';
import 'package:app_campi/core/shared_widget/gps_banner.dart';
import '../../application/esplora_match_filter.dart';
import '../../application/esplora_match_providers.dart';
import '../widgets/esplora_match_card.dart';
import '../widgets/esplora_match_empty_state.dart';
import '../widgets/filtro_distanza_chips.dart';

class EsploraMatchPage extends ConsumerWidget {
  const EsploraMatchPage({super.key});

  String _labelCalcio(String sport) {
    switch (sport) {
      case 'calcio_5':
        return 'Calcio 5';
      case 'calcio_6':
        return 'Calcio 6';
      case 'calcio_7':
        return 'Calcio 7';
      case 'calcio_8':
        return 'Calcio 8';
      case 'calcio_11':
        return 'Calcio 11';
      default:
        return 'Calcio';
    }
  }

  String _labelTennis(String sport) {
    switch (sport) {
      case 'tennis_singolo':
        return 'Tennis • Singolo';
      case 'tennis_doppio':
        return 'Tennis • Doppio';
      default:
        return 'Tennis';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('🚨 SONO DENTRO EsploraMatchPage BUILD');
    final matchInZonaAsync = ref.watch(matchInZonaProvider);
    final filtro = ref.watch(filtroDistanzaProvider);
    final sportSelezionato = ref.watch(filtroSportProvider);
    final Utente? utenteLoggato = ref.watch(utenteCorrenteProvider).value;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 1, 5, 4),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accent.withOpacity(0.05),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: 8,
                    right: AppSpacing.screenPadding,
                    top: 12,
                    bottom: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppTheme.textPrimary,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "ESPLORA MATCH",
                        style: TextStyle(
                          color: AppTheme.textSecondary.withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),
                ),

                const FiltroDistanzaChips(),
                const SizedBox(height: 8),

                // 🟢 NUOVO FILTRO CHIPS PER SPORT
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _SportDropdownChip(
                        label: _labelCalcio(sportSelezionato),
                        selected:
                            sportSelezionato == 'calcio' ||
                            sportSelezionato.startsWith('calcio_'),
                        values: const {
                          'calcio': 'Tutto il calcio',
                          'calcio_5': 'Calcio a 5',
                          'calcio_6': 'Calcio a 6',
                          'calcio_7': 'Calcio a 7',
                          'calcio_8': 'Calcio a 8',
                          'calcio_11': 'Calcio a 11',
                        },
                        onSelected: (value) {
                          ref.read(filtroSportProvider.notifier).state = value;
                        },
                      ),

                      const SizedBox(width: 8),

                      _SportChip(
                        label: 'Padel',
                        selected: sportSelezionato == 'padel',
                        onTap: () {
                          ref.read(filtroSportProvider.notifier).state =
                              'padel';
                        },
                      ),

                      const SizedBox(width: 8),

                      _SportDropdownChip(
                        label: _labelTennis(sportSelezionato),
                        selected:
                            sportSelezionato == 'tennis' ||
                            sportSelezionato.startsWith('tennis_'),
                        values: const {
                          'tennis': 'Tutto il tennis',
                          'tennis_singolo': 'Singolo',
                          'tennis_doppio': 'Doppio',
                        },
                        onSelected: (value) {
                          ref.read(filtroSportProvider.notifier).state = value;
                        },
                      ),

                      const SizedBox(width: 8),

                      _SportChip(
                        label: 'Basket',
                        selected: sportSelezionato == 'basket',
                        onTap: () {
                          ref.read(filtroSportProvider.notifier).state =
                              'basket';
                        },
                      ),

                      const SizedBox(width: 8),

                      _SportChip(
                        label: 'Pallavolo',
                        selected: sportSelezionato == 'pallavolo',
                        onTap: () {
                          ref.read(filtroSportProvider.notifier).state =
                              'pallavolo';
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const GpsBanner(),

                Expanded(
                  child: matchInZonaAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: AppTheme.accent),
                    ),
                    error: (err, _) {
                      final messaggio = err.toString();

                      if (messaggio.contains('PERMESSO_POSIZIONE_NEGATO')) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_off_rounded,
                                  color: AppTheme.textSecondary,
                                  size: 42,
                                ),
                                SizedBox(height: 14),
                                Text(
                                  'POSIZIONE NON DISPONIBILE',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Per vedere i match vicino a te devi consentire l’accesso alla posizione.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      if (messaggio.contains('GPS_SPENTO')) {
                        return const Center(
                          child: Text(
                            'Attiva il GPS per vedere i match vicino a te.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        );
                      }

                      return const Center(
                        child: Text(
                          'Impossibile caricare i match in questo momento.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      );
                    },
                    data: (partite) {
                      debugPrint(
                        '🟢 ESPLOORA ricevute dal provider: ${partite.length}',
                      );
                      debugPrint('🟢 filtro distanza: $filtro');
                      debugPrint('🟢 filtro sport: $sportSelezionato');
                      debugPrint('🟢 utente: ${utenteLoggato?.id ?? "OSPITE"}');

                      var partiteDaEsplorare = filtraEOrdina(
                        partite,
                        utenteLoggato,
                        filtro,
                      );

                      debugPrint(
                        '🟠 dopo filtraEOrdina: ${partiteDaEsplorare.length}',
                      );
                      if (sportSelezionato != 'tutti') {
                        partiteDaEsplorare = partiteDaEsplorare.where((item) {
                          final sportPartita = item.partita.sportNormalizzato;

                          if (sportPartita.isEmpty) {
                            return false;
                          }

                          if (sportSelezionato == 'calcio') {
                            return sportPartita == 'calcio' ||
                                sportPartita.startsWith('calcio_');
                          }

                          if (sportSelezionato == 'tennis') {
                            return sportPartita == 'tennis' ||
                                sportPartita.startsWith('tennis_');
                          }

                          return sportPartita == sportSelezionato;
                        }).toList();
                      }

                      debugPrint(
                        '🔵 dopo filtro sport: ${partiteDaEsplorare.length}',
                      );

                      if (partiteDaEsplorare.isEmpty) {
                        return const EsploraMatchEmptyState();
                      }

                      return RefreshIndicator(
                        color: AppTheme.accent,
                        backgroundColor: AppTheme.cardBg,
                        onRefresh: () async {
                          ref.invalidate(matchInZonaProvider);
                          await ref.read(matchInZonaProvider.future);
                        },
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: const EdgeInsets.only(
                            top: 8,
                            left: AppSpacing.screenPadding,
                            right: AppSpacing.screenPadding,
                            bottom: 100,
                          ),
                          itemCount: partiteDaEsplorare.length,
                          itemBuilder: (context, index) {
                            final item = partiteDaEsplorare[index];
                            return FadeSlideIn(
                              delay: index * MatchThresholds.stepDelayLista,
                              child: EsploraMatchCard(
                                item: item,
                                giaIscritto: isGiaIscritto(
                                  item.partita,
                                  utenteLoggato,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
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

class _SportChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SportChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppTheme.accent,
      backgroundColor: AppTheme.cardBg,
      side: BorderSide(color: selected ? AppTheme.accent : AppTheme.cardBorder),
      labelStyle: TextStyle(
        color: selected ? AppTheme.darkBg : AppTheme.textPrimary,
        fontWeight: FontWeight.w800,
        fontSize: 12,
      ),
    );
  }
}

class _SportDropdownChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Map<String, String> values;
  final ValueChanged<String> onSelected;

  const _SportDropdownChip({
    required this.label,
    required this.selected,
    required this.values,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      color: AppTheme.cardBg,
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.cardBorder),
      ),
      itemBuilder: (context) {
        return values.entries.map((entry) {
          return PopupMenuItem<String>(
            value: entry.key,
            child: Text(
              entry.value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }).toList();
      },
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accent : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.accent : AppTheme.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? AppTheme.darkBg : AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 17,
              color: selected ? AppTheme.darkBg : AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
