import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_campi/core/theme/app_theme.dart';
import 'package:app_campi/core/models/partita.dart';
import 'package:app_campi/core/services/partita_service.dart';
import 'package:app_campi/core/services/location_provider.dart';
import 'package:app_campi/core/shared_widget/selezione_livello_dialog.dart';
import 'package:app_campi/features/auth/application/auth_provider.dart';
import 'package:app_campi/features/home/presentation/widgets/auth_bottom_sheet.dart';
import 'package:app_campi/core/models/utente.dart';
import 'package:app_campi/features/miei_match/application/partite_utente_provider.dart';
import 'package:app_campi/features/home/presentation/home_page.dart';

void showJoinMatchSheet({
  required BuildContext context,
  required WidgetRef ref,
  required Map<String, dynamic> rawPartita,
  required Utente? utenteLoggato,
  required bool isOspite,
}) {
  final Map<String, dynamic> jsonNormalizzato = Map<String, dynamic>.from(
    rawPartita,
  );
  jsonNormalizzato['campo'] =
      jsonNormalizzato['campo'] ?? jsonNormalizzato['campi'];

  Partita partita;
  try {
    partita = Partita.fromJson(jsonNormalizzato);
  } catch (e, stack) {
    debugPrint('Errore parsing partita nel bottom sheet: $e\n$stack');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Dati partita non disponibili.")),
    );
    return;
  }

  bool giaIscritto = false;
  if (!isOspite) {
    giaIscritto = partita.listaGiocatoriIscritti.any(
      (g) => g.idUtente == utenteLoggato!.id,
    );
  }

  final int postiDisponibili =
      partita.campo.numeroDiGiocatori - partita.numeroGiocatoriPrenotati;
  final int maxOspitiAggiungibili = postiDisponibili > 0
      ? postiDisponibili - 1
      : 0;

  double prezzoCampoTotale = partita.campo.prezzo;

  final sport = partita.sportNormalizzato.trim().toLowerCase();

  for (final tariffa in partita.campo.tariffeSport) {
    if (tariffa.sport.trim().toLowerCase() == sport) {
      prezzoCampoTotale = tariffa.prezzo;
      break;
    }
  }

  try {
    final inizio = partita.orarioInizio.split(':');
    final fine = partita.orarioFine.split(':');

    final minutiInizio = int.parse(inizio[0]) * 60 + int.parse(inizio[1]);

    int minutiFine = int.parse(fine[0]) * 60 + int.parse(fine[1]);

    if (minutiFine == 0 && minutiInizio > 0) {
      minutiFine = 24 * 60;
    }

    final durataOre = (minutiFine - minutiInizio) / 60.0;

    prezzoCampoTotale *= durataOre;
  } catch (_) {}

  final bool isARischio =
      rawPartita['stato_partita'] == 'aperta_a_rischio' && !giaIscritto;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) {
      int numeroPersone = 1;
      bool isLoading = false;

      return StatefulBuilder(
        builder: (context, setSheetState) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.darkBg.withOpacity(0.85),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                  border: Border(
                    top: BorderSide(color: AppTheme.cardBorder, width: 1.5),
                  ),
                ),
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 30,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // HEADER: Titolo e Stato
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            partita.campo.nomeCampo,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ),
                        ),
                        if (isARischio)
                          Container(
                            margin: const EdgeInsets.only(left: 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.statoErrore.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              "A RISCHIO",
                              style: TextStyle(
                                color: AppTheme.statoErrore,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // DATA E ORARIO
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.cardBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_month_rounded,
                                color: AppTheme.textSecondary,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "${partita.dataPartita.day.toString().padLeft(2, '0')}/${partita.dataPartita.month.toString().padLeft(2, '0')}/${partita.dataPartita.year}",
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  "|",
                                  style: TextStyle(
                                    color: AppTheme.textDisabled,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.access_time_rounded,
                                color: AppTheme.accent,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                partita.orarioInizio.substring(0, 5),
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: AppTheme.fontMono,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // PREZZO CAMPO
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.euro_rounded,
                                color: AppTheme.accent,
                                size: 20,
                              ),
                              SizedBox(width: 10),
                              Text(
                                "Prezzo campo",
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            "${prezzoCampoTotale.toStringAsFixed(2)} €",
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              fontFamily: AppTheme.fontMono,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // POSTI DISPONIBILI
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.group_rounded,
                                color: AppTheme.textSecondary,
                                size: 20,
                              ),
                              SizedBox(width: 10),
                              Text(
                                "Posti disponibili",
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            "$postiDisponibili",
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              fontFamily: AppTheme.fontMono,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (isOspite) ...[
                      const Text(
                        "Devi accedere per poterti unire al match.",
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            showAuthBottomSheet(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accent,
                            foregroundColor: AppTheme.darkBg,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            "ACCEDI",
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ] else if (giaIscritto) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.accent.withOpacity(0.3),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: AppTheme.accent,
                              size: 22,
                            ),
                            SizedBox(width: 10),
                            Text(
                              "Sei già iscritto a questa partita!",
                              style: TextStyle(
                                color: AppTheme.accent,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (postiDisponibili <= 0) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.statoAttenzione.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.statoAttenzione.withOpacity(0.5),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.do_not_disturb_alt_rounded,
                              color: AppTheme.statoAttenzione,
                              size: 22,
                            ),
                            SizedBox(width: 10),
                            Text(
                              "La partita è al completo",
                              style: TextStyle(
                                color: AppTheme.statoAttenzione,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const Text(
                        "In quanti siete?",
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: numeroPersone > 1
                                  ? () => setSheetState(() => numeroPersone--)
                                  : null,
                              icon: Icon(
                                Icons.remove_circle_outline,
                                color: numeroPersone > 1
                                    ? AppTheme.accent
                                    : AppTheme.textDisabled,
                                size: 30,
                              ),
                            ),
                            Container(
                              width: 40,
                              alignment: Alignment.center,
                              child: Text(
                                "$numeroPersone ",
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed:
                                  numeroPersone < maxOspitiAggiungibili + 1
                                  ? () => setSheetState(() => numeroPersone++)
                                  : null,
                              icon: Icon(
                                Icons.add_circle_outline,
                                color: numeroPersone < maxOspitiAggiungibili + 1
                                    ? AppTheme.accent
                                    : AppTheme.textDisabled,
                                size: 30,
                              ),
                            ),
                            const Spacer(),
                            Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: Text(
                                "$numeroPersone ${numeroPersone == 1 ? 'persona' : 'persone'}",
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      // BOTTONE CONFERMA ISCRIZIONE
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  verificaESelezionaLivello(
                                    context: context,
                                    userId: utenteLoggato!.id,
                                    livelliSportAttuali:
                                        utenteLoggato.livelliSport,
                                    sports: [partita.sportNormalizzato],
                                    onCompletato: () async {
                                      ref.invalidate(utenteCorrenteProvider);

                                      if (!context.mounted) return;

                                      setSheetState(() => isLoading = true);

                                      final int nuovoTotale =
                                          partita.numeroGiocatoriPrenotati +
                                          numeroPersone;

                                      final bool diventaCompleta =
                                          nuovoTotale >=
                                          partita.maxGiocatoriReali;

                                      final service = PartitaService();

                                      final errore = await service
                                          .uniscitiAPartita(
                                            partita: partita,
                                            nuovoGiocatore: utenteLoggato,
                                            ospitiExtra: numeroPersone - 1,
                                          );

                                      if (!context.mounted) return;

                                      if (errore == null) {
                                        final navigator = Navigator.of(context);

                                        ref
                                            .read(
                                              filtroPartitaProvider.notifier,
                                            )
                                            .impostaFiltro(
                                              diventaCompleta
                                                  ? FiltroPartita.complete
                                                  : FiltroPartita.aperte,
                                            );

                                        ref.invalidate(matchInZonaProvider);
                                        ref.invalidate(
                                          partiteUtenteProvider(
                                            utenteLoggato.id,
                                          ),
                                        );

                                        await showDialog<void>(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (dialogContext) {
                                            return AlertDialog(
                                              backgroundColor: AppTheme.cardBg,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                side: BorderSide(
                                                  color: diventaCompleta
                                                      ? AppTheme.statoSuccesso
                                                            .withOpacity(0.5)
                                                      : AppTheme.accent
                                                            .withOpacity(0.5),
                                                ),
                                              ),
                                              title: Row(
                                                children: [
                                                  Icon(
                                                    diventaCompleta
                                                        ? Icons
                                                              .check_circle_rounded
                                                        : Icons
                                                              .info_outline_rounded,
                                                    color: diventaCompleta
                                                        ? AppTheme.statoSuccesso
                                                        : AppTheme.accent,
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Text(
                                                    diventaCompleta
                                                        ? "MATCH COMPLETO"
                                                        : "MATCH APERTO",
                                                    style: const TextStyle(
                                                      color:
                                                          AppTheme.textPrimary,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              content: Text(
                                                diventaCompleta
                                                    ? "Il campo è riservato esclusivamente a te e ai tuoi amici. "
                                                          "Potrai disdire la prenotazione fino a 30 minuti prima "
                                                          "dell'inizio della partita. Buona partita bomber 💪"
                                                    : "Se il match non raggiunge il numero necessario entro 2 ore "
                                                          "dall'inizio, verrà annullato.\n\n"
                                                          "Se il campo viene prenotato per intero, il match verrà annullato.",
                                                style: const TextStyle(
                                                  color: AppTheme.textSecondary,
                                                  fontSize: 14,
                                                  height: 1.5,
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        dialogContext,
                                                      ),
                                                  child: const Text(
                                                    "HO CAPITO",
                                                    style: TextStyle(
                                                      color: AppTheme.accent,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        );

                                        if (!context.mounted) return;

                                        navigator.pop();

                                        navigator.pushAndRemoveUntil(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const HomePage(initialIndex: 2),
                                          ),
                                          (route) => false,
                                        );
                                      } else {
                                        setSheetState(() => isLoading = false);

                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              errore,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            backgroundColor:
                                                AppTheme.statoErrore,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accent,
                            foregroundColor: AppTheme.darkBg,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: AppTheme.darkBg,
                                    strokeWidth: 3,
                                  ),
                                )
                              : const Text(
                                  "CONFERMA ISCRIZIONE",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
