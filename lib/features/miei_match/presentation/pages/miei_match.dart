import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_campi/core/models/utente.dart';
import 'package:app_campi/core/models/partita.dart';
import 'package:app_campi/core/theme/app_theme.dart';
import 'package:app_campi/core/theme/app_constants.dart';

import 'package:app_campi/features/miei_match/application/partite_utente_provider.dart';
import 'package:app_campi/features/miei_match/presentation/widgets/filtri_match_widget.dart';
import 'package:app_campi/features/miei_match/presentation/widgets/premium_match_card.dart';
import 'package:app_campi/features/miei_match/presentation/widgets/partecipanti_bottom_sheet.dart';
import 'package:app_campi/features/miei_match/presentation/widgets/leggenda_dialog.dart';
import 'package:app_campi/features/miei_match/presentation/widgets/empty_states.dart';
import 'package:app_campi/core/shared_widget/fade_slide_in.dart';

class MieiMatch extends ConsumerWidget {
  final Utente? utenteLoggato;

  const MieiMatch({super.key, required this.utenteLoggato});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final utente = utenteLoggato;
    if (utente == null) return const EmptyStateOspite();

    final partiteAsync = ref.watch(partiteUtenteProvider(utente.id));
    final filtroAttivo = ref.watch(filtroPartitaProvider);
    final service = ref.watch(partitaServiceProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,

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
                    left: AppSpacing.screenPadding,
                    right: 8,
                    top: 24,
                    bottom: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "LE TUE PRENOTAZIONI",
                        style: TextStyle(
                          color: AppTheme.textSecondary.withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                      IconButton(
                        onPressed: () => mostraLeggendaDialog(context),
                        icon: const Icon(
                          Icons.info_outline_rounded,
                          color: AppTheme.textSecondary,
                          size: 22,
                        ),
                        tooltip: "Leggenda stati",
                        splashRadius: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

                FiltriMatchWidget(
                  filtroAttivo: filtroAttivo,
                  onFiltroChanged: (valore) => ref
                      .read(filtroPartitaProvider.notifier)
                      .impostaFiltro(valore),
                ),

                const SizedBox(height: 8),

                Expanded(
                  child: partiteAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.accent,
                        strokeWidth: 3,
                      ),
                    ),
                    error: (err, stack) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: AppTheme.statoErrore.withOpacity(0.8),
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Impossibile caricare i match",
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () => ref.refresh(
                              partiteUtenteProvider(utente.id).future,
                            ),
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text("Riprova"),
                          ),
                        ],
                      ),
                    ),
                    data: (tutteLePartite) {
                      final partiteFiltrate = tutteLePartite.where((p) {
                        final statoReale = service.getStatoRealePartita(p);
                        if (statoReale == 'annullata') return false;
                        final isCompleta = statoReale == 'completa';
                        return filtroAttivo == FiltroPartita.complete
                            ? isCompleta
                            : !isCompleta;
                      }).toList();

                      return RefreshIndicator(
                        color: AppTheme.accent,
                        backgroundColor: AppTheme.cardBg,
                        onRefresh: () async {
                          ref.invalidate(partiteUtenteProvider(utente.id));
                          try {
                            await ref.read(
                              partiteUtenteProvider(utente.id).future,
                            );
                          } catch (_) {}
                        },
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          slivers: [
                            if (partiteFiltrate.isEmpty)
                              SliverFillRemaining(
                                hasScrollBody: true,
                                child: ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                          0.6,
                                      child: _buildEmptyState(tutteLePartite),
                                    ),
                                  ],
                                ),
                              )
                            else
                              SliverPadding(
                                padding: const EdgeInsets.only(
                                  top: 8,
                                  left: AppSpacing.screenPadding,
                                  right: AppSpacing.screenPadding,
                                  bottom: 100,
                                ),
                                sliver: _buildSliverList(
                                  partiteFiltrate,
                                  utente,
                                  ref,
                                ),
                              ),
                          ],
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

  Widget _buildSliverList(
    List<Partita> partiteFiltrate,
    Utente utente,
    WidgetRef ref,
  ) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final partita = partiteFiltrate[index];
        return Padding(
          key: ValueKey(partita.id),
          padding: const EdgeInsets.only(bottom: 16.0),
          child: FadeSlideIn(
            delay: index * 60,
            child: PremiumMatchCard(
              partita: partita,
              onTap: () =>
                  mostraBottomSheetPartecipanti(context, ref, partita, utente),
            ),
          ),
        );
      }, childCount: partiteFiltrate.length),
    );
  }

  Widget _buildEmptyState(List<Partita> partiteTotali) {
    if (partiteTotali.isEmpty) return const EmptyStateNessunaPartita();
    return const EmptyStateFiltro();
  }
}
