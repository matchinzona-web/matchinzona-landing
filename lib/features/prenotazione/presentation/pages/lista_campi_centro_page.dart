import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:app_campi/core/models/societa.dart';
import 'package:app_campi/features/prenotazione/application/creazione_partita_controller.dart';
import 'package:app_campi/core/theme/app_theme.dart';
import 'package:app_campi/features/prenotazione/presentation/widget/fade_slide_in.dart';
import 'package:app_campi/features/home/application/preferiti_provider.dart';
import 'package:app_campi/features/auth/application/auth_provider.dart';
import 'package:app_campi/core/shared_widget/selezione_livello_dialog.dart';
import 'package:app_campi/core/models/campo.dart';
import 'creazione_partita_page.dart';

class ListaCampiCentroPage extends ConsumerWidget {
  final Societa societa;

  const ListaCampiCentroPage({super.key, required this.societa});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(creazionePartitaProvider);
    final controller = ref.read(creazionePartitaProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      extendBodyBehindAppBar: true,
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
                _buildHeader(context, ref),
                Expanded(child: _buildBody(context, ref, state, controller)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final preferitiAsync = ref.watch(preferitiProvider);
    final isPreferito =
        preferitiAsync.value?.any((s) => s.id == societa.id) ?? false;
    final utente = ref.watch(utenteCorrenteProvider).value;
    final isOspite = utente == null;

    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 12, top: 12, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
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
                societa.nomeSocieta.toUpperCase(),
                style: TextStyle(
                  color: AppTheme.textSecondary.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              isPreferito
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: isPreferito
                  ? AppTheme.statoErrore
                  : AppTheme.textSecondary,
              size: 24,
            ),
            onPressed: () {
              if (isOspite) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Devi accedere per salvare i preferiti.'),
                    backgroundColor: AppTheme.statoErrore,
                  ),
                );
                return;
              }
              ref.read(preferitiProvider.notifier).togglePreferito(societa);
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isPreferito
                        ? 'Rimosso dai preferiti'
                        : 'Aggiunto ai preferiti!',
                    style: const TextStyle(
                      color: AppTheme.darkBg,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: isPreferito
                      ? AppTheme.textPrimary
                      : AppTheme.statoSuccesso,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    dynamic state,
    dynamic controller,
  ) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.accent),
      );
    }

    if (state.campiTrovati.isEmpty) {
      return Center(
        child: FadeSlideIn(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.04),
                ),
                child: const Icon(
                  Icons.sports_soccer_outlined,
                  size: 60,
                  color: AppTheme.textDisabled,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Nessun campo disponibile",
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: FadeSlideIn(
            child: Row(
              children: [
                const Icon(
                  Icons.stadium_rounded,
                  color: AppTheme.textSecondary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                const Text(
                  "Seleziona un campo",
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            itemCount: state.campiTrovati.length,
            itemBuilder: (context, index) {
              return FadeSlideIn(
                delay: index * 80,
                child: _buildCampoCard(
                  context,
                  ref,
                  state.campiTrovati[index] as Campo,
                  controller,
                  state.sportSelezionato,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _immagineFallbackCampo(dynamic campo) {
    final nomeCampo = campo.nomeCampo.toString().toLowerCase();

    if (nomeCampo.contains('padel')) {
      return 'assets/images/campi/padel.jpg';
    }

    if (nomeCampo.contains('tennis')) {
      return 'assets/images/campi/tennis.jpg';
    }

    if (nomeCampo.contains('calcio') || nomeCampo.contains('calcetto')) {
      return 'assets/images/campi/calcio.jpg';
    }

    if (nomeCampo.contains('basket')) {
      return 'assets/images/campi/basket.jpg';
    }

    if (nomeCampo.contains('pallavolo') || nomeCampo.contains('volley')) {
      return 'assets/images/campi/volley.jpg';
    }

    return 'assets/images/campi/generico.jpg';
  }

  Widget _buildCampoCard(
    BuildContext context,
    WidgetRef ref,
    Campo campo,
    dynamic controller,
    String sportSelezionato,
  ) {
    // 1. Estraiamo il prezzo specifico per lo sport selezionato dal campo JSONB
    double prezzoTotale = campo.prezzo;

    final String sportRichiesto = sportSelezionato.trim().toLowerCase();

    for (final t in campo.tariffeSport) {
      final String sportTariffa = t.sport.trim().toLowerCase();

      if (sportTariffa == sportRichiesto) {
        prezzoTotale = t.prezzo;
        break;
      }
    }

    final int numGiocatori = campo.numeroDiGiocatori;

    final double prezzoPerGiocatore = numGiocatori > 0
        ? prezzoTotale / numGiocatori
        : prezzoTotale;
    final String copertoCampo = campo.coperto ? "Al chiuso" : "All'aperto";
    final bool hasImage = campo.fotoUrl != null && campo.fotoUrl!.isNotEmpty;
    final fallbackImage = _immagineFallbackCampo(campo);

    final String sportCampo = _sportRealeCampo(campo, sportSelezionato);
    final List<String> sportLivelliCampo = campo.tariffeSport
        .map((tariffa) => tariffa.sport.trim().toLowerCase())
        .where((sport) => sport.isNotEmpty)
        .toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            splashColor: AppTheme.accent.withOpacity(0.1),
            highlightColor: Colors.transparent,
            onTap: () {
              final utente = ref.read(utenteCorrenteProvider).value;

              // Se l'utente è un ospite, lo fa accedere o va avanti
              if (utente == null) {
                controller.impostaSport(sportCampo);
                controller.selezionaCampo(campo);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreazionePartitaPage(),
                  ),
                );
                return;
              }

              // 🚀 Qui viene chiamato il nuovo Bottom Sheet!
              verificaESelezionaLivello(
                context: context,
                userId: utente.id,
                livelliSportAttuali: utente.livelliSport,
                sports: sportLivelliCampo,
                onCompletato: () {
                  // 🚀 AGGIUNGI QUESTA RIGA: Forza l'app a ricaricare l'utente con i nuovi livelli!
                  ref.invalidate(utenteCorrenteProvider);

                  controller.impostaSport(sportCampo);
                  controller.selezionaCampo(campo);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreazionePartitaPage(),
                    ),
                  );
                },
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 85,
                    height: 85,
                    decoration: BoxDecoration(
                      color: AppTheme.darkBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.accent.withOpacity(0.2),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: hasImage
                          ? CachedNetworkImage(
                              imageUrl: campo.fotoUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorWidget: (_, _, _) => Image.asset(
                                fallbackImage,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            )
                          : Container(
                              color: AppTheme.darkBg,
                              alignment: Alignment.center,
                              child: Icon(
                                _iconaFallbackCampo(campo),
                                color: AppTheme.accent,
                                size: 36,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          campo.nomeCampo,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildPill(
                              _iconaSportCampo(campo),
                              _sportDisponibiliCampo(campo),
                            ),

                            _buildPill(
                              Icons.people_alt_rounded,
                              "$numGiocatori Gioc.",
                            ),

                            _buildPill(
                              campo.coperto
                                  ? Icons.roofing_rounded
                                  : Icons.landscape_rounded,
                              copertoCampo,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Quota singola",
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "${prezzoPerGiocatore.toStringAsFixed(2)} €",
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              "Tot: ${prezzoTotale.toStringAsFixed(2)} €",
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
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
      ),
    );
  }

  String _sportDisponibiliCampo(dynamic campo) {
    final Set<String> sport = {};

    for (final tariffa in campo.tariffeSport) {
      final String valore = tariffa.sport.trim().toLowerCase();

      if (valore == 'tennis_singolo' || valore == 'tennis_doppio') {
        sport.add('Tennis');
      } else if (valore == 'padel') {
        sport.add('Padel');
      } else if (valore == 'calcio_5') {
        sport.add('Calcio a 5');
      } else if (valore == 'calcio_6') {
        sport.add('Calcio a 6');
      } else if (valore == 'calcio_7') {
        sport.add('Calcio a 7');
      } else if (valore == 'calcio_8') {
        sport.add('Calcio a 8');
      } else if (valore == 'calcio_11') {
        sport.add('Calcio a 11');
      } else if (valore == 'basket') {
        sport.add('Basket');
      } else if (valore == 'pallavolo' || valore == 'volley') {
        sport.add('Pallavolo');
      }
    }

    final lista = sport.toList();

    if (lista.length <= 2) {
      return lista.join(' • ');
    }

    final altri = lista.length - 2;

    return '${lista.take(2).join(' • ')}  +$altri';
  }

  IconData _iconaSportCampo(dynamic campo) {
    if (campo.tariffeSport.isEmpty) {
      return Icons.stadium_rounded;
    }

    final primo = campo.tariffeSport.first;

    final String sport = primo.sport.trim().toLowerCase();

    if (sport.startsWith('calcio_')) {
      return Icons.sports_soccer_rounded;
    }

    if (sport == 'basket') {
      return Icons.sports_basketball_rounded;
    }

    if (sport == 'pallavolo' || sport == 'volley') {
      return Icons.sports_volleyball_rounded;
    }

    if (sport == 'padel' ||
        sport == 'tennis_singolo' ||
        sport == 'tennis_doppio') {
      return Icons.sports_tennis_rounded;
    }

    return Icons.stadium_rounded;
  }

  Widget _buildPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.darkBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 12),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconaFallbackCampo(dynamic campo) {
    return _iconaSportCampo(campo);
  }

  String _sportRealeCampo(dynamic campo, String sportAttuale) {
    final nome = campo.nomeCampo.toString().toLowerCase();

    // Il tennis mantiene singolo/doppio se era già stato scelto.
    if (nome.contains('tennis')) {
      if (sportAttuale == 'tennis_singolo' || sportAttuale == 'tennis_doppio') {
        return sportAttuale;
      }

      // Se si entra su un tennis provenendo da un'altra ricerca,
      // non riutilizziamo mai calcio/padel/basket.
      return campo.numeroDiGiocatori == 2 ? 'tennis_singolo' : 'tennis_doppio';
    }

    if (nome.contains('padel')) return 'padel';

    if (nome.contains('calcio 11') || nome.contains('calcio a 11')) {
      return 'calcio_11';
    }

    if (nome.contains('calcio 8') || nome.contains('calcio a 8')) {
      return 'calcio_8';
    }

    if (nome.contains('calcio 7') || nome.contains('calcio a 7')) {
      return 'calcio_7';
    }

    if (nome.contains('calcio 6') || nome.contains('calcio a 6')) {
      return 'calcio_6';
    }

    if (nome.contains('calcio 5') ||
        nome.contains('calcio a 5') ||
        nome.contains('calcetto')) {
      return 'calcio_5';
    }

    if (nome.contains('basket')) return 'basket';

    if (nome.contains('pallavolo') || nome.contains('volley')) {
      return 'pallavolo';
    }

    return sportAttuale;
  }
}
