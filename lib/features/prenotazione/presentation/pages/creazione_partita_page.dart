import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_campi/features/prenotazione/application/creazione_partita_controller.dart';
import 'package:app_campi/features/prenotazione/application/creazione_partita_state.dart';
import 'package:app_campi/core/theme/app_theme.dart';
import 'package:app_campi/features/prenotazione/presentation/pages/successo_prenotazione_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:app_campi/core/services/partita_service.dart';
import 'package:app_campi/features/esplora_match/presentation/pages/esplora_match_page.dart';
import 'package:app_campi/features/miei_match/application/partite_utente_provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_campi/features/auth/application/auth_provider.dart';

class CreazionePartitaPage extends ConsumerWidget {
  const CreazionePartitaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(creazionePartitaProvider);
    final controller = ref.read(creazionePartitaProvider.notifier);

    if (state.campoSelezionato == null) {
      return const Scaffold(backgroundColor: AppTheme.darkBg);
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      extendBodyBehindAppBar: true,
      bottomNavigationBar: const _BuildStickyBottomBar(),
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
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: 8,
                    right: 20,
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
                        "CONFIGURA ORARIO",
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
                Expanded(
                  child: _BuildFaseConfigurazione(
                    state: state,
                    controller: controller,
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

class _BuildFaseConfigurazione extends StatelessWidget {
  final CreazionePartitaState state;
  final CreazionePartitaController controller;

  const _BuildFaseConfigurazione({
    required this.state,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        _RiepilogoCampoCard(state: state, controller: controller),

        if ((state.campoSelezionato?.tariffeSport.length ?? 0) > 1) ...[
          const SizedBox(height: 32),

          _SelettoreSportCampo(state: state, controller: controller),
        ],

        const SizedBox(height: 32),

        _SelettoreData(state: state, controller: controller),

        const SizedBox(height: 32),

        _SelettoreOrario(state: state, controller: controller),
        AnimatedSize(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          child:
              (state.oraInizioSelezionata != null &&
                  (state.partiteApertePerSlot[state.oraInizioSelezionata] ??
                          0) >
                      0)
              ? Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _SlotCompetitionBanner(
                    partiteAperte:
                        state.partiteApertePerSlot[state.oraInizioSelezionata]!,
                    isMioMatch: state.mieiMatchApertiPerSlot.containsKey(
                      state.oraInizioSelezionata,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 32),
        _SelettoreModalitaGioco(state: state, controller: controller),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: !state.isPartitaPrivata
              ? Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: _SelettorePartecipanti(
                    state: state,
                    controller: controller,
                  ),
                )
              : const SizedBox.shrink(),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: state.isPartitaPrivata
              ? Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: _SelettoreMetodoPagamento(
                    state: state,
                    controller: controller,
                  ),
                )
              : const SizedBox.shrink(),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          child: state.oraInizioSelezionata != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: _BannerInformativo(
                    statoInfo: controller.getInfoStatoPartita(),
                    colore:
                        controller.getColoreStato() ==
                                const Color(0xFF00E5FF) ||
                            controller.getColoreStato() ==
                                const Color(0xFF9457EB) ||
                            controller.getColoreStato() == AppTheme.neonGreen
                        ? AppTheme.accent
                        : controller.getColoreStato(),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _RiepilogoCampoCard extends StatelessWidget {
  final CreazionePartitaState state;
  final CreazionePartitaController controller;

  const _RiepilogoCampoCard({required this.state, required this.controller});

  String _nomeSport(String sport) {
    switch (sport.toLowerCase()) {
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
    final value = sport.toLowerCase();

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
  Widget build(BuildContext context) {
    final campo = state.campoSelezionato!;
    final hasFoto = campo.fotoUrl != null && campo.fotoUrl!.isNotEmpty;

    // 💶 Calcoliamo prezzo e giocatori in base allo sport
    final double prezzoTotale = controller.getPrezzoSportSelezionato();
    final int maxGiocatori = controller.getMaxGiocatori();
    final double quotaPersona = maxGiocatori > 0
        ? prezzoTotale / maxGiocatori
        : prezzoTotale;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: AppTheme.darkBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: hasFoto
                      ? CachedNetworkImage(
                          imageUrl: campo.fotoUrl!,
                          fit: BoxFit.cover,
                        )
                      : Icon(
                          _iconaSport(state.sportSelezionato),
                          color: AppTheme.accent,
                          size: 28,
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "STAI PRENOTANDO",
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 10,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      campo.nomeCampo,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _iconaSport(state.sportSelezionato),
                            color: AppTheme.accent,
                            size: 14,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _nomeSport(state.sportSelezionato),
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
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                  controller.selezionaCampo(null);
                },
                icon: const Icon(
                  Icons.edit_square,
                  color: AppTheme.textSecondary,
                  size: 20,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 12),

          // 🏷️ RIGA PREZZI REALI
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 16,
                    color: AppTheme.accent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Quota a persona: ${quotaPersona.toStringAsFixed(2)} €",
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Text(
                "Totale: ${prezzoTotale.toStringAsFixed(2)} €",
                style: const TextStyle(
                  color: AppTheme.accent,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelettoreSportCampo extends StatelessWidget {
  final CreazionePartitaState state;
  final CreazionePartitaController controller;

  const _SelettoreSportCampo({required this.state, required this.controller});

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
  Widget build(BuildContext context) {
    final campo = state.campoSelezionato!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SELEZIONA SPORT',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          'Scegli come vuoi utilizzare questo campo.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),

        const SizedBox(height: 14),

        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: campo.tariffeSport.map((tariffa) {
            final sport = tariffa.sport.trim().toLowerCase();

            final bool selezionato =
                state.sportSelezionato.trim().toLowerCase() == sport;

            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                controller.cambiaSportCampo(sport);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: selezionato
                      ? AppTheme.accent.withOpacity(0.14)
                      : AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selezionato ? AppTheme.accent : AppTheme.cardBorder,
                    width: selezionato ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _iconaSport(sport),
                      size: 18,
                      color: selezionato
                          ? AppTheme.accent
                          : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _nomeSport(sport),
                      style: TextStyle(
                        color: selezionato
                            ? AppTheme.accent
                            : AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _SelettoreData extends StatelessWidget {
  final CreazionePartitaState state;
  final CreazionePartitaController controller;

  const _SelettoreData({required this.state, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "QUANDO VUOI GIOCARE?",
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 85,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            itemCount: 14,
            itemBuilder: (context, index) {
              final dataCorrente = DateTime.now().add(Duration(days: index));
              final isSelected = DateUtils.isSameDay(
                state.dataSelezionata,
                dataCorrente,
              );
              final bool isChiuso = state.giorniChiusi.any(
                (d) => DateUtils.isSameDay(d, dataCorrente),
              );

              return GestureDetector(
                onTap: isChiuso
                    ? null
                    : () => controller.caricaOrari(dataCorrente),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 70,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isChiuso
                        ? Colors.white.withOpacity(0.02)
                        : (isSelected
                              ? AppTheme.accent.withOpacity(0.12)
                              : AppTheme.cardBg),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isChiuso
                          ? AppTheme.statoErrore.withOpacity(0.2)
                          : (isSelected
                                ? AppTheme.accent
                                : AppTheme.cardBorder),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _getGiornoSettimana(dataCorrente.weekday),
                            style: TextStyle(
                              color: isChiuso
                                  ? Colors.white24
                                  : (isSelected
                                        ? AppTheme.accent
                                        : AppTheme.textSecondary),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "${dataCorrente.day}",
                            style: TextStyle(
                              color: isChiuso
                                  ? Colors.white24
                                  : (isSelected
                                        ? AppTheme.textPrimary
                                        : AppTheme.textPrimary),
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      if (isChiuso)
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.darkBg.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.close_rounded,
                              color: AppTheme.statoErrore.withOpacity(0.7),
                              size: 40,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _getGiornoSettimana(int weekday) {
    const giorni = ["LUN", "MAR", "MER", "GIO", "VEN", "SAB", "DOM"];
    return giorni[weekday - 1];
  }
}

class _SelettoreOrario extends StatelessWidget {
  final CreazionePartitaState state;
  final CreazionePartitaController controller;

  const _SelettoreOrario({required this.state, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "SELEZIONA L'ORARIO",
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        if (state.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(color: AppTheme.accent),
            ),
          )
        else if (state.orariDisponibili.isEmpty)
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "Nessun orario disponibile in questa data.",
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: state.orariDisponibili.map((ora) {
              final isSelected = state.oraInizioSelezionata == ora;
              final isChiusura = state.orariChiusi.contains(ora);
              final isOccupato = state.orariOccupati.contains(ora);
              final isBloccato = isChiusura || isOccupato;
              final aperte = state.partiteApertePerSlot[ora] ?? 0;
              final hasCompetizione = !isBloccato && aperte > 0;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isBloccato
                      ? null
                      : () => controller.aggiornaOrario(ora),
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 90,
                    height: 65,
                    decoration: BoxDecoration(
                      color: isBloccato
                          ? Colors.white.withOpacity(0.02)
                          : (isSelected
                                ? AppTheme.accent.withOpacity(0.12)
                                : (hasCompetizione
                                      ? AppTheme.statoAttenzione.withOpacity(
                                          0.05,
                                        )
                                      : AppTheme.cardBg)),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isBloccato
                            ? Colors.white.withOpacity(0.05)
                            : (isSelected
                                  ? AppTheme.accent
                                  : (hasCompetizione
                                        ? AppTheme.statoAttenzione.withOpacity(
                                            0.5,
                                          )
                                        : AppTheme.cardBorder)),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              ora,
                              style: TextStyle(
                                color: isBloccato
                                    ? Colors.white30
                                    : (isSelected
                                          ? AppTheme.accent
                                          : AppTheme.textPrimary),
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                            if (!isBloccato) ...[
                              const SizedBox(height: 4),
                              if (hasCompetizione)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.accent.withOpacity(0.2)
                                        : AppTheme.statoAttenzione.withOpacity(
                                            0.15,
                                          ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.bolt,
                                        size: 10,
                                        color: isSelected
                                            ? AppTheme.accent
                                            : AppTheme.statoAttenzione,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        "$aperte",
                                        style: TextStyle(
                                          color: isSelected
                                              ? AppTheme.accent
                                              : AppTheme.statoAttenzione,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                const SizedBox.shrink(),
                            ],
                          ],
                        ),
                        if (isBloccato)
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.darkBg.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Icon(
                                isChiusura
                                    ? Icons.close_rounded
                                    : Icons.lock_rounded,
                                color: isChiusura
                                    ? AppTheme.statoErrore.withOpacity(0.8)
                                    : AppTheme.statoAttenzione.withOpacity(0.8),
                                size: 24,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        if (!state.isLoading && state.orariDisponibili.isNotEmpty) ...[
          const SizedBox(height: 20),
          const _LegendaSlot(),
        ],
      ],
    );
  }
}

class _SelettoreModalitaGioco extends StatelessWidget {
  final CreazionePartitaState state;
  final CreazionePartitaController controller;

  const _SelettoreModalitaGioco({
    required this.state,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "SELEZIONA MODALITÀ",
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _ModalitaCard(
                  titolo: "CAMPO\nINTERO",
                  descrizione: "Prenota per il tuo gruppo",
                  icona: Icons.stadium_outlined,
                  isSelected: state.isPartitaPrivata,
                  onTap: () => controller.aggiornaTipoPartita(true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ModalitaCard(
                  titolo: "CERCA\nGIOCATORI",
                  descrizione: "Apri un matchmaking",
                  icona: Icons.people_alt_outlined,
                  isSelected: !state.isPartitaPrivata,
                  onTap: () => controller.aggiornaTipoPartita(false),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModalitaCard extends StatelessWidget {
  final String titolo;
  final String descrizione;
  final IconData icona;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModalitaCard({
    required this.titolo,
    required this.descrizione,
    required this.icona,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accent.withOpacity(0.12)
              : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.accent : AppTheme.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.accent
                    : Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icona,
                color: isSelected ? AppTheme.darkBg : AppTheme.textSecondary,
                size: 24,
              ),
            ),
            const Spacer(),
            const SizedBox(height: 16),
            Text(
              titolo,
              style: TextStyle(
                color: isSelected ? AppTheme.accent : AppTheme.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              descrizione,
              style: TextStyle(
                color: isSelected
                    ? AppTheme.textPrimary
                    : AppTheme.textSecondary,
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelettorePartecipanti extends StatelessWidget {
  final CreazionePartitaState state;
  final CreazionePartitaController controller;

  const _SelettorePartecipanti({required this.state, required this.controller});

  @override
  Widget build(BuildContext context) {
    final maxGiocatori = _calcolaMaxGiocatoriPerSport(
      state.sportSelezionato,
      state.campoSelezionato?.numeroDiGiocatori ?? 0,
    );
    final int postiDisponibiliPerAmici = maxGiocatori - 1;
    final int mancanti = maxGiocatori - (state.ospitiExtra + 1);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "QUANTI AMICI PORTI CON TE?",
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.darkBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Text(
                  "${state.ospitiExtra + 1} / $maxGiocatori",
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            mancanti > 0
                ? "Indica se vieni con amici. Troveremo noi i restanti $mancanti giocatori."
                : "Hai occupato tutti i posti. Il match diventerà un Campo Intero (Completo).",
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.4,
              fontWeight: mancanti == 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPulsanteRotondo(
                icona: Icons.remove,
                attivo: state.ospitiExtra > 0,
                onTap: () => controller.aggiornaOspiti(state.ospitiExtra - 1),
              ),
              const SizedBox(width: 32),
              SizedBox(
                width: 50,
                child: Text(
                  "${state.ospitiExtra}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 32),
              _buildPulsanteRotondo(
                icona: Icons.add,
                attivo: state.ospitiExtra < postiDisponibiliPerAmici,
                onTap: () => controller.aggiornaOspiti(state.ospitiExtra + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPulsanteRotondo({
    required IconData icona,
    required bool attivo,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: attivo ? onTap : null,
        borderRadius: BorderRadius.circular(30),
        child: Ink(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: attivo ? AppTheme.accent : Colors.white.withOpacity(0.05),
          ),
          child: Icon(
            icona,
            color: attivo ? AppTheme.darkBg : Colors.white24,
            size: 28,
          ),
        ),
      ),
    );
  }
}

class _LegendaSlot extends StatelessWidget {
  const _LegendaSlot();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 10,
      children: const [
        _LegendaItem(
          color: AppTheme.accent,
          icon: Icons.check_circle_outline,
          label: "Libero",
        ),
        _LegendaItem(
          color: AppTheme.statoAttenzione,
          icon: Icons.bolt,
          label: "In gara",
        ),
        _LegendaItem(
          color: AppTheme.statoAttenzione,
          icon: Icons.lock_rounded,
          label: "Occupato",
        ),
        _LegendaItem(
          color: AppTheme.statoErrore,
          icon: Icons.close_rounded,
          label: "Chiuso",
        ),
      ],
    );
  }
}

class _LegendaItem extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;

  const _LegendaItem({
    required this.color,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SlotCompetitionBanner extends StatelessWidget {
  final int partiteAperte;
  final bool isMioMatch;

  const _SlotCompetitionBanner({
    required this.partiteAperte,
    required this.isMioMatch,
  });

  @override
  Widget build(BuildContext context) {
    final String titolo = isMioMatch
        ? "Hai già un match aperto in questo orario"
        : partiteAperte == 1
        ? "C'è già 1 gruppo in questo slot"
        : "Ci sono già $partiteAperte gruppi in questo slot";

    final String corpo = isMioMatch
        ? "Hai già creato un match per questo campo e questo orario. "
              "Non puoi aprirne un altro finché quello esistente è ancora attivo."
        : "Puoi comunque aprire il tuo match oppure unirti a uno di quelli già esistenti. "
              "Lo slot verrà assegnato al primo match che raggiunge il numero completo di giocatori.";

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.statoAttenzione.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.statoAttenzione.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.groups_rounded,
              color: AppTheme.statoAttenzione,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titolo,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  corpo,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "$partiteAperte match aperti in questo orario",
                  style: const TextStyle(
                    color: AppTheme.statoAttenzione,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!isMioMatch) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EsploraMatchPage(),
                        ),
                      ),
                      icon: const Icon(Icons.search, size: 18),
                      label: const Text("Esplora Match Esistenti"),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerInformativo extends StatelessWidget {
  final String statoInfo;
  final Color colore;

  const _BannerInformativo({required this.statoInfo, required this.colore});

  String _getSpiegazioneStato(String stato) {
    if (stato.contains("PRIVATA")) {
      return "Hai prenotato l'intero campo per il tuo gruppo. Nessun altro potrà unirsi.";
    }

    if (stato == "PARTITA AL COMPLETO") {
      return "Siete al completo. Il campo è assegnato al vostro match e lo slot è bloccato.";
    }

    if (stato == "PARTITA APERTA") {
      return "Il match è aperto e altri giocatori possono unirsi. Finché non è completo, lo slot può essere assegnato a una prenotazione completa.";
    }

    return "Configura il match e aprilo alla ricerca di giocatori.";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colore.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colore.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.info_outline, color: colore, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statoInfo,
                  style: TextStyle(
                    color: colore,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _getSpiegazioneStato(statoInfo),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    height: 1.4,
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

class _BuildStickyBottomBar extends ConsumerWidget {
  const _BuildStickyBottomBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(creazionePartitaProvider);
    final controller = ref.read(creazionePartitaProvider.notifier);

    final maxGiocatori = _calcolaMaxGiocatoriPerSport(
      state.sportSelezionato,
      state.campoSelezionato?.numeroDiGiocatori ?? 0,
    );

    final isVirtualmenteCompleta =
        state.isPartitaPrivata || ((state.ospitiExtra + 1) >= maxGiocatori);
    final bool haGiaUnMatchNelloSlot =
        state.oraInizioSelezionata != null &&
        state.mieiMatchApertiPerSlot.containsKey(state.oraInizioSelezionata);

    final isValido =
        controller.isNumeroGiocatoriValido() &&
        state.oraInizioSelezionata != null &&
        !haGiaUnMatchNelloSlot;

    String buttonText = "APRI MATCHMAKING";
    IconData buttonIcon = Icons.check_circle_outline;
    Color buttonColor = AppTheme.accent;

    if (isVirtualmenteCompleta) {
      buttonText = "PRENOTA CAMPO";
    }
    if (haGiaUnMatchNelloSlot && !isVirtualmenteCompleta) {
      buttonText = "MATCH GIÀ APERTO";
      buttonIcon = Icons.lock_outline_rounded;
    } else if (isVirtualmenteCompleta) {
      buttonText = "PRENOTA CAMPO";
    }

    return Container(
      padding: const EdgeInsets.only(top: 16, left: 20, right: 20, bottom: 32),
      decoration: BoxDecoration(
        color: AppTheme.darkBg,
        border: const Border(top: BorderSide(color: AppTheme.cardBorder)),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 60),
          backgroundColor: isValido ? buttonColor : AppTheme.cardBg,
          foregroundColor: isValido ? AppTheme.darkBg : Colors.white54,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: isValido ? 8 : 0,
        ),
        onPressed: state.isLoading || !isValido
            ? null
            : () {
                _gestisciConferma(context, ref, state, controller);
              },
        child: state.isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: AppTheme.darkBg,
                  strokeWidth: 3,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    buttonText,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(buttonIcon, size: 20),
                ],
              ),
      ),
    );
  }

  Future<void> _gestisciConferma(
    BuildContext context,
    WidgetRef ref,
    CreazionePartitaState state,
    CreazionePartitaController controller,
  ) async {
    try {
      final utente = ref.read(utenteCorrenteProvider).value;
      if (utente == null) throw Exception('Utente non autenticato.');
      final bool isMaggiorenne = utente.eta != null && utente.eta! >= 18;

      String? stripePaymentIntentId;
      int? importoRimborsabileCentesimi;

      // 🟢 SE L'UTENTE SCEGLIE DI PAGARE IN APP (Valido solo per Campo Intero/Privata):
      if (state.isPartitaPrivata &&
          state.metodoPagamentoScelto == MetodoPagamento.pagaOra) {
        if (!isMaggiorenne) {
          throw Exception(
            'Il pagamento online è disponibile solo per utenti maggiorenni. '
            'Puoi pagare direttamente al centro sportivo.',
          );
        }
        if (!state.pagamentiOnlineDisponibili) {
          throw Exception('Il centro sportivo non accetta pagamenti online.');
        }

        final double prezzoBase = controller.getPrezzoSportSelezionato();

        // 1. Invoca Edge Function per ottenere PaymentIntent da Stripe
        final res = await Supabase.instance.client.functions.invoke(
          'crea-pagamento-partita',
          body: {
            'id_campo': state.campoSelezionato!.id,
            'prezzo_base_euro': prezzoBase,
          },
        );

        if (res.status != 200 ||
            res.data == null ||
            res.data['error'] != null) {
          throw Exception(
            res.data?['error'] ?? 'Impossibile inizializzare il pagamento',
          );
        }

        final String clientSecret = res.data['paymentIntent'];

        // Estraiamo l'ID univoco di Stripe e i centesimi del prezzo base
        stripePaymentIntentId =
            res.data['paymentIntentId'] ?? clientSecret.split('_secret_').first;
        importoRimborsabileCentesimi =
            res.data['prezzoBaseCentesimi'] ?? (prezzoBase * 100).round();

        // 2. Inizializza il PaymentSheet Stripe
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            merchantDisplayName: state.campoSelezionato!.nomeCampo,
            style: ThemeMode.dark,
          ),
        );

        // 3. Mostra la schermata nativa di pagamento Stripe
        await Stripe.instance.presentPaymentSheet();
      }

      // 4. Conclusione: registra la partita a database
      final maxGiocatori = _calcolaMaxGiocatoriPerSport(
        state.sportSelezionato,
        state.campoSelezionato!.numeroDiGiocatori,
      );
      final ospitiAttuali = state.ospitiExtra + 1;
      final isPrivata = state.isPartitaPrivata;
      final isCompleta = isPrivata || (ospitiAttuali >= maxGiocatori);

      final nomeCampo = state.campoSelezionato!.nomeCampo;
      final data = state.dataSelezionata;
      final ora = state.oraInizioSelezionata!;

      final String idPartitaCreata = await controller.confermaMatch(
        utente,
        stripePaymentIntentId: stripePaymentIntentId,
        importoRimborsabileCentesimi: importoRimborsabileCentesimi,
      );
      await Future.delayed(const Duration(milliseconds: 600));

      ref
          .read(filtroPartitaProvider.notifier)
          .impostaFiltro(
            isCompleta ? FiltroPartita.complete : FiltroPartita.aperte,
          );
      ref.invalidate(partiteUtenteProvider(utente.id));

      if (!context.mounted) return;

      final nomeSocieta =
          ref
              .read(creazionePartitaProvider)
              .campoSelezionato
              ?.societa
              ?.nomeSocieta ??
          'Centro Sportivo';

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => SuccessoPrenotazionePage(
            idPartita: idPartitaCreata,
            nomeCampo: nomeCampo,
            nomeSocieta: nomeSocieta,
            sport: ref.read(creazionePartitaProvider).sportSelezionato,
            data: data,
            ora: ora,
            isPrivata: isPrivata,
          ),
        ),
        (route) => route.isFirst,
      );

      controller.svuotaTutto();
    } on StripeException catch (e) {
      if (context.mounted) {
        if (e.error.code != FailureCode.Canceled) {
          _gestioneErroriUI(
            context,
            e.error.localizedMessage ?? 'Pagamento fallito',
          );
        }
      }
    } catch (e) {
      if (context.mounted) _gestioneErroriUI(context, e.toString());
    }
  }

  void _gestioneErroriUI(BuildContext context, String erroreStr) {
    String titolo = "Errore";
    String descrizione = erroreStr.replaceAll('Exception: ', '');

    if (erroreStr.contains('SLOT_GIA_OCCUPATO')) {
      titolo = "Orario Occupato";
      descrizione =
          "Il campo è già stato prenotato per intero in questo orario.";
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          titolo,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          descrizione,
          style: const TextStyle(color: AppTheme.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Chiudi",
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelettoreMetodoPagamento extends ConsumerWidget {
  final CreazionePartitaState state;
  final CreazionePartitaController controller;

  const _SelettoreMetodoPagamento({
    required this.state,
    required this.controller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final utente = ref.watch(utenteCorrenteProvider).value;

    final bool isMaggiorenne = utente?.eta != null && utente!.eta! >= 18;

    final bool pagamentoOnlineConsentito =
        state.pagamentiOnlineDisponibili && isMaggiorenne;
    final double prezzoBase = controller.getPrezzoSportSelezionato();
    final double fee = (prezzoBase * 0.035) + 0.35;
    final double totaleApp = prezzoBase + fee;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "METODO DI PAGAMENTO",
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _OpzionePagamentoCard(
                titolo: "PAGA AL CAMPO",
                sottotitolo:
                    "${prezzoBase.toStringAsFixed(2)} € in contanti/POS",
                icona: Icons.storefront_outlined,
                isSelected:
                    state.metodoPagamentoScelto == MetodoPagamento.inSede,
                onTap: () =>
                    controller.selezionaMetodoPagamento(MetodoPagamento.inSede),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _OpzionePagamentoCard(
                titolo: !isMaggiorenne
                    ? "ONLINE DAI 18 ANNI"
                    : pagamentoOnlineConsentito
                    ? "PAGA IN APP"
                    : "ONLINE NON DISPONIBILE",
                sottotitolo: !isMaggiorenne
                    ? "Pagamento online disponibile dai 18 anni"
                    : pagamentoOnlineConsentito
                    ? "${totaleApp.toStringAsFixed(2)} € (Stripe)"
                    : "Pagamento disponibile al centro",
                icona: pagamentoOnlineConsentito
                    ? Icons.credit_card_rounded
                    : Icons.lock_outline_rounded,
                isSelected:
                    pagamentoOnlineConsentito &&
                    state.metodoPagamentoScelto == MetodoPagamento.pagaOra,
                enabled: pagamentoOnlineConsentito,
                onTap: () => controller.selezionaMetodoPagamento(
                  MetodoPagamento.pagaOra,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OpzionePagamentoCard extends StatelessWidget {
  final String titolo;
  final String sottotitolo;
  final IconData icona;
  final bool isSelected;
  final VoidCallback onTap;
  final bool enabled;

  const _OpzionePagamentoCard({
    required this.titolo,
    required this.sottotitolo,
    required this.icona,
    required this.isSelected,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accent.withOpacity(0.12)
              : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.accent : AppTheme.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icona,
              color: !enabled
                  ? Colors.white30
                  : isSelected
                  ? AppTheme.accent
                  : AppTheme.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 12),
            Text(
              titolo,
              style: TextStyle(
                color: !enabled
                    ? Colors.white38
                    : isSelected
                    ? AppTheme.accent
                    : AppTheme.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sottotitolo,
              style: TextStyle(
                color: isSelected
                    ? AppTheme.textPrimary
                    : AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

int _calcolaMaxGiocatoriPerSport(String sport, int defaultCampo) {
  final value = sport.trim().toLowerCase();

  if (value == 'tennis_singolo') return 2;

  if (value == 'tennis_doppio' || value == 'padel') return 4;

  if (value == 'calcio_5') return 10;

  if (value == 'calcio_6') return 12;

  if (value == 'calcio_7') return 14;

  if (value == 'calcio_8') return 16;

  if (value == 'calcio_11') return 22;

  if (value == 'basket') return 10;

  if (value == 'pallavolo' || value == 'volley') return 12;

  return defaultCampo;
}
