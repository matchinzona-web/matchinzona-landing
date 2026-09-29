import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_campi/core/services/location_provider.dart';
import 'package:app_campi/core/theme/app_theme.dart';
import 'package:app_campi/features/prenotazione/presentation/pages/ricerca_centri_page.dart';
import 'package:app_campi/features/esplora_match/presentation/pages/esplora_match_page.dart';
import 'package:app_campi/core/models/partita.dart';
import 'package:app_campi/core/shared_widget/gps_banner.dart';
import 'package:app_campi/features/prenotazione/presentation/pages/lista_campi_centro_page.dart';
import 'package:app_campi/features/prenotazione/application/creazione_partita_controller.dart';

import 'package:app_campi/features/home/presentation/widgets/promo_banner.dart';
import 'package:app_campi/features/home/presentation/widgets/match_card.dart';
import 'package:app_campi/features/home/presentation/widgets/auth_bottom_sheet.dart';
import 'package:app_campi/features/home/presentation/widgets/join_match_sheet.dart';
import 'package:app_campi/features/home/presentation/widgets/compactMatchCard.dart';
import 'package:app_campi/core/shared_widget/fade_slide_in.dart';
import 'package:app_campi/features/miei_match/application/partite_utente_provider.dart';
import 'package:app_campi/core/models/utente.dart';
import 'package:app_campi/features/home/application/preferiti_provider.dart';
import 'package:app_campi/features/notifiche/presentation/pages/notifiche_page.dart';
import 'package:app_campi/features/notifiche/application/notifiche_provider.dart';
import 'package:app_campi/features/notifiche/presentation/widget/notifiche_bell.dart';

class HomeTab extends ConsumerWidget {
  final AsyncValue<Utente?> utenteAsyncValue;

  const HomeTab({super.key, required this.utenteAsyncValue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return utenteAsyncValue.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.accent),
      ),
      error: (_, _) => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Impossibile caricare la Home. Riprova tra poco.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      ),
      data: (utenteLoggato) => _PlayerDashboard(utenteLoggato: utenteLoggato),
    );
  }
}

class _PlayerDashboard extends ConsumerWidget {
  final Utente? utenteLoggato;

  const _PlayerDashboard({required this.utenteLoggato});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isOspite = utenteLoggato == null;
    final screenWidth = MediaQuery.of(context).size.width;

    final matchInZonaAsync = ref.watch(matchInZonaProvider);
    AsyncValue<List<Partita>>? miePartiteAsync;

    int notificheNonLette = 0;

    if (!isOspite) {
      miePartiteAsync = ref.watch(partiteUtenteProvider(utenteLoggato!.id));

      final notificheAsync = ref.watch(notificheStreamProvider);

      ref.listen(notificheStreamProvider, (previous, next) {
        if (previous == null) return;

        final precedenti = previous.value ?? [];
        final attuali = next.value ?? [];

        final idsAnnullatiPrecedenti = precedenti
            .where((n) => n.tipo == 'match_annullato')
            .map((n) => n.id)
            .toSet();

        final nuovaNotificaAnnullamento = attuali.any(
          (n) =>
              n.tipo == 'match_annullato' &&
              !idsAnnullatiPrecedenti.contains(n.id),
        );

        if (nuovaNotificaAnnullamento) {
          ref.invalidate(partiteUtenteProvider(utenteLoggato!.id));
        }
      });

      if (notificheAsync.value != null) {
        notificheNonLette = notificheAsync.value!.where((n) => !n.letto).length;
      }
    }

    return RefreshIndicator(
      color: AppTheme.accent,
      backgroundColor: AppTheme.cardBg,
      onRefresh: () async {
        ref.invalidate(matchInZonaProvider);
        if (!isOspite) {
          ref.invalidate(partiteUtenteProvider(utenteLoggato!.id));
          ref.invalidate(preferitiProvider);
          ref.invalidate(notificheStreamProvider);
        }
        try {
          await ref.read(matchInZonaProvider.future);
          if (!isOspite) {
            await ref.read(partiteUtenteProvider(utenteLoggato!.id).future);
            await ref.read(preferitiProvider.future);
          }
        } catch (_) {}
      },
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.only(bottom: 120, top: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeSlideIn(
                delay: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.zero,
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.accent.withOpacity(0.3),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/icon/logo_app.png',
                            fit: BoxFit.cover,
                            width: 40,
                            height: 40,
                          ),
                        ),
                      ),

                      Flexible(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (!isOspite)
                              Flexible(
                                child: Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  padding: const EdgeInsets.only(
                                    left: 12,
                                    right: 4,
                                    top: 4,
                                    bottom: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          utenteLoggato!.nome,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: AppTheme.accent,
                                        child: Text(
                                          utenteLoggato!.nome[0].toUpperCase(),
                                          style: const TextStyle(
                                            color: AppTheme.darkBg,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              // TASTO ACCEDI PER GLI OSPITI
                              GestureDetector(
                                onTap: () => showAuthBottomSheet(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accent.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppTheme.accent.withOpacity(0.5),
                                    ),
                                  ),
                                  child: const Text(
                                    "Accedi",
                                    style: TextStyle(
                                      color: AppTheme.accent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),

                            if (!isOspite)
                              NotificheBell(
                                count: notificheNonLette,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const NotifichePage(),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              FadeSlideIn(
                delay: 50,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _DashboardActionCard(
                          title: "Prenota Campo",
                          subtitle: "Scegli un centro",
                          icon: Icons.sports_soccer,
                          coloreTema: AppTheme.accent,
                          onTap: () {
                            if (isOspite) {
                              showAuthBottomSheet(context);
                            } else {
                              // Navigazione diretta alla ricerca centri
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RicercaCentriPage(),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _DashboardActionCard(
                          title: "Trova Match",
                          subtitle: "Unisciti ora",
                          icon: Icons.search_rounded,
                          coloreTema: AppTheme.textPrimary,
                          onTap: () {
                            ref.invalidate(matchInZonaProvider);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EsploraMatchPage(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 35),

              // MATCH IN ZONA
              FadeSlideIn(
                delay: 100,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        "Match in Zona",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          ref.invalidate(matchInZonaProvider);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EsploraMatchPage(),
                            ),
                          );
                        },
                        child: const Text(
                          "Vedi tutti",
                          style: TextStyle(
                            color: AppTheme.accent,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),
              const GpsBanner(),
              _buildMatchInZonaList(
                matchInZonaAsync,
                isOspite,
                screenWidth,
                ref,
              ),

              const SizedBox(height: 40),

              if (!isOspite && miePartiteAsync != null) ...[
                const FadeSlideIn(
                  delay: 150,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "La tua Agenda",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                FadeSlideIn(
                  delay: 170,
                  child: _buildProssimoMatchSection(miePartiteAsync),
                ),
                const SizedBox(height: 40),
              ] else ...[
                const FadeSlideIn(
                  delay: 150,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: PromoBanner(),
                  ),
                ),
                const SizedBox(height: 40),
              ],

              //PREFERITI (Solo se loggato)
              if (!isOspite) ...[
                const FadeSlideIn(
                  delay: 200,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Centri Preferiti",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                const _PreferitiSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProssimoMatchSection(AsyncValue<List<Partita>> miePartiteAsync) {
    return miePartiteAsync.when(
      data: (partite) {
        if (partite.isNotEmpty) {
          partite.sort((a, b) => a.dataPartita.compareTo(b.dataPartita));
          return CompactMatchCard(partita: partite.first);
        } else {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardBg.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.event_available_rounded,
                    color: AppTheme.textSecondary,
                    size: 28,
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Agenda Libera",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Non hai match in programma per ora.",
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
      loading: () => const SizedBox(
        height: 90,
        child: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildMatchInZonaList(
    AsyncValue<List<dynamic>> matchInZonaAsync,
    bool isOspite,
    double screenWidth,
    WidgetRef ref,
  ) {
    return matchInZonaAsync.when(
      loading: () => const SizedBox(
        height: 215,
        child: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
      ),
      error: (err, _) {
        final messaggio = err.toString();

        if (messaggio.contains('PERMESSO_POSIZIONE_NEGATO')) {
          return const SizedBox(
            height: 90,
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Consenti la posizione per vedere i match vicino a te.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ),
            ),
          );
        }

        if (messaggio.contains('GPS_SPENTO')) {
          return const SizedBox(
            height: 90,
            child: Center(
              child: Text(
                "Attiva il GPS per vedere i match vicino a te.",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ),
          );
        }

        return const SizedBox(
          height: 90,
          child: Center(
            child: Text(
              "Match in zona momentaneamente non disponibili.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ),
        );
      },
      data: (partiteList) {
        final partiteFiltrate = partiteList.where((p) {
          if (p['stato_partita'] != 'aperta_a_rischio') {
            return false;
          }

          if (isOspite) {
            return true;
          }

          try {
            final Map<String, dynamic> jsonNormalizzato =
                Map<String, dynamic>.from(p);

            jsonNormalizzato['campo'] =
                jsonNormalizzato['campo'] ?? jsonNormalizzato['campi'];

            final partita = Partita.fromJson(jsonNormalizzato);

            final bool giaDentro = partita.listaGiocatoriIscritti.any(
              (g) => g.idUtente == utenteLoggato!.id,
            );

            return !giaDentro;
          } catch (_) {
            return false;
          }
        }).toList();

        if (partiteFiltrate.isEmpty) return _buildEmptyState();

        final partiteDaMostrare = partiteFiltrate.take(5).toList();

        return SizedBox(
          height: 215,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: partiteDaMostrare.length,
            itemBuilder: (context, index) {
              final pRaw = partiteDaMostrare[index];
              final Map<String, dynamic> jsonNormalizzato =
                  Map<String, dynamic>.from(pRaw);
              jsonNormalizzato['campo'] =
                  jsonNormalizzato['campo'] ?? jsonNormalizzato['campi'];

              Partita? partitaModel;

              try {
                partitaModel = Partita.fromJson(jsonNormalizzato);
              } catch (e) {
                debugPrint('🔴 HOME Partita.fromJson FALLITA: $e');
                debugPrint('🔴 HOME RAW: $pRaw');
                return const SizedBox.shrink();
              }

              bool giaDentro =
                  !isOspite &&
                  partitaModel.listaGiocatoriIscritti.any(
                    (g) => g.idUtente == utenteLoggato!.id,
                  );

              final societa = partitaModel.campo.societa;

              final String indirizzoCentro = [
                [societa?.viaStrutturata, societa?.civico]
                    .where((e) => e != null && e.toString().trim().isNotEmpty)
                    .map((e) => e.toString().trim())
                    .join(' '),

                societa?.comune?.trim() ?? '',
              ].where((e) => e.isNotEmpty).join(', ');

              return FadeSlideIn(
                delay: 260 + (index * 70),
                horizontal: true,
                child: MatchCard(
                  screenWidth: screenWidth * 1.1,
                  rawPartita: pRaw,
                  dataOrario:
                      "${partitaModel.dataPartita.day}/${partitaModel.dataPartita.month} | ${partitaModel.orarioInizio.substring(0, 5)}",
                  nomeCentroSportivo:
                      partitaModel.campo.societa?.nomeSocieta ??
                      'Centro Sportivo',
                  indirizzoCentro: indirizzoCentro,
                  tipoSport: "Aperta",
                  distanzaKm: (pRaw['distanza_km'] as num?)?.toDouble() ?? 0.0,
                  giocatoriAttuali: partitaModel.numeroGiocatoriPrenotati,
                  giocatoriMassimi: partitaModel.maxGiocatoriReali,
                  coloreTema: AppTheme.accent,
                  isIscritto: giaDentro,
                  nomeOrganizzatore: partitaModel.organizzatore.nomeCompleto,
                  etaOrganizzatore: partitaModel.organizzatore.eta,
                  onTap: () => showJoinMatchSheet(
                    context: context,
                    ref: ref,
                    rawPartita: pRaw,
                    utenteLoggato: utenteLoggato,
                    isOspite: isOspite,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.cardBg.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.radar_rounded,
                size: 32,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Tutto tranquillo qui...",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Non ci sono partite aperte nei paraggi.\nSii il primo a scendere in campo!",
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
}

class _DashboardActionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color coloreTema;
  final VoidCallback onTap;

  const _DashboardActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.coloreTema,
    required this.onTap,
  });

  @override
  State<_DashboardActionCard> createState() => _DashboardActionCardState();
}

class _DashboardActionCardState extends State<_DashboardActionCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 165,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [widget.coloreTema.withOpacity(0.12), AppTheme.cardBg],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: widget.coloreTema.withOpacity(0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.coloreTema.withOpacity(0.08),
                blurRadius: 15,
                spreadRadius: -2,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.coloreTema.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: widget.coloreTema, size: 26),
              ),
              const Spacer(),
              Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.subtitle,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreferitiSection extends ConsumerWidget {
  const _PreferitiSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferitiAsync = ref.watch(preferitiProvider);

    return SizedBox(
      height: 95,
      child: preferitiAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.accent),
        ),
        error: (err, _) => const SizedBox.shrink(),
        data: (centri) {
          return ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              ...centri.map(
                (centro) => Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _AnimatedPreferitoItem(
                    nome: centro.nomeSocieta,
                    icon: Icons.stadium_rounded,
                    onTap: () {
                      ref
                          .read(creazionePartitaProvider.notifier)
                          .caricaCampiSocieta(centro.id);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ListaCampiCentroPage(societa: centro),
                        ),
                      );
                    },
                  ),
                ),
              ),
              _AnimatedPreferitoItem(
                nome: "Aggiungi",
                icon: Icons.add,
                isAdd: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RicercaCentriPage(),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AnimatedPreferitoItem extends StatefulWidget {
  final String nome;
  final IconData icon;
  final VoidCallback onTap;
  final bool isAdd;

  const _AnimatedPreferitoItem({
    required this.nome,
    required this.icon,
    required this.onTap,
    this.isAdd = false,
  });

  @override
  State<_AnimatedPreferitoItem> createState() => _AnimatedPreferitoItemState();
}

class _AnimatedPreferitoItemState extends State<_AnimatedPreferitoItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isPressed
                    ? AppTheme.accent.withOpacity(0.12)
                    : AppTheme.cardBg,
                border: Border.all(
                  color: widget.isAdd
                      ? Colors.white.withOpacity(0.15)
                      : (_isPressed
                            ? AppTheme.accent
                            : Colors.white.withOpacity(0.08)),
                  width: _isPressed ? 2.0 : 1.0,
                ),
                boxShadow: _isPressed && !widget.isAdd
                    ? [
                        BoxShadow(
                          color: AppTheme.accent.withOpacity(0.25),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Icon(
                widget.icon,
                color: widget.isAdd
                    ? Colors.white54
                    : (_isPressed ? AppTheme.accent : Colors.white),
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.nome.length > 10
                  ? '${widget.nome.substring(0, 8)}...'
                  : widget.nome,
              style: TextStyle(
                color: widget.isAdd
                    ? AppTheme.textSecondary
                    : AppTheme.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
