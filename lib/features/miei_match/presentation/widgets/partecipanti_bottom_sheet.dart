import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_campi/core/models/partita.dart';
import 'package:app_campi/core/models/utente.dart';
import 'package:app_campi/core/theme/app_theme.dart';
import 'package:app_campi/core/theme/app_constants.dart';
import 'package:app_campi/core/services/location_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_campi/features/miei_match/application/partite_utente_provider.dart';

void mostraBottomSheetPartecipanti(
  BuildContext context,
  WidgetRef ref,
  Partita partita,
  Utente? utenteLoggato,
) {
  final isIscritto =
      utenteLoggato != null &&
      partita.listaGiocatoriIscritti.any(
        (g) =>
            g.idUtente.toString().trim().toLowerCase() ==
            utenteLoggato.id.toString().trim().toLowerCase(),
      );

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: AppTheme.darkBg.withOpacity(0.92),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.sheet),
              ),
              border: const Border(top: BorderSide(color: Colors.white10)),
            ),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 5,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade700,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Icon(
                      Icons.people_alt_outlined,
                      color: AppTheme.neonCyan,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Partecipanti',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.neonCyan.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "${partita.numeroGiocatoriPrenotati} / ${partita.maxGiocatoriReali}",
                        style: const TextStyle(
                          color: AppTheme.neonCyan,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 12),
                if (partita.listaGiocatoriIscritti.isEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      "Nessun giocatore iscritto.",
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                ] else ...[
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: partita.listaGiocatoriIscritti.length,
                      itemBuilder: (context, index) {
                        final giocatore = partita.listaGiocatoriIscritti[index];
                        final nomeCompleto =
                            "${giocatore.nomeGiocatore ?? 'Utente'} ${giocatore.cognomeGiocatore ?? 'Sconosciuto'}";
                        final iniziale = nomeCompleto.isNotEmpty
                            ? nomeCompleto[0].toUpperCase()
                            : 'U';

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.02),
                            borderRadius: BorderRadius.circular(AppRadius.tile),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 2,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.cardBg,
                              child: Text(
                                iniziale,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              nomeCompleto,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: giocatore.ospitiExtra > 0
                                ? Text(
                                    "+ ${giocatore.ospitiExtra} ospiti",
                                    style: const TextStyle(
                                      color: AppTheme.neonOrange,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  )
                                : null,
                            trailing:
                                partita.organizzatore.id
                                        .toString()
                                        .trim()
                                        .toLowerCase() ==
                                    giocatore.idUtente
                                        .toString()
                                        .trim()
                                        .toLowerCase()
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.badge,
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                          size: 14,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          "ADMIN",
                                          style: TextStyle(
                                            color: Colors.amber,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                if (isIscritto) ...[
                  Builder(
                    builder: (context) {
                      final bool isOrganizzatore =
                          partita.organizzatore.id
                              .toString()
                              .trim()
                              .toLowerCase() ==
                          utenteLoggato.id.toString().trim().toLowerCase();
                      final bool haPagatoInApp =
                          partita.isPagato && isOrganizzatore;

                      return SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent.withOpacity(0.1),
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(
                              color: Colors.redAccent,
                              width: 1.2,
                            ),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppRadius.tile,
                              ),
                            ),
                          ),
                          onPressed: () => _gestisciAbbandono(
                            context,
                            ref,
                            partita,
                            utenteLoggato,
                            haPagatoInApp: haPagatoInApp,
                          ),
                          child: Text(
                            haPagatoInApp
                                ? 'Annulla Prenotazione e Rimborsa'
                                : 'Abbandona Partita',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.tile),
                      ),
                    ),
                    child: const Text(
                      'Chiudi',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      );
    },
  );
}

void _gestisciAbbandono(
  BuildContext context,
  WidgetRef ref,
  Partita partita,
  Utente utente, {
  bool haPagatoInApp = false,
}) {
  final double quotaCampo = partita.importoRimborsabileCentesimi != null
      ? partita.importoRimborsabileCentesimi! / 100.0
      : partita.campo.prezzo;

  showDialog(
    context: context,
    builder: (ctx) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child: AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: Colors.white10),
        ),
        title: Text(
          haPagatoInApp ? 'Annulla e Richiedi Rimborso' : 'Attenzione',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          haPagatoInApp
              ? 'Sei sicuro di voler annullare la prenotazione?\n\nTi verranno riaccreditati ${quotaCampo.toStringAsFixed(2)} € sulla carta utilizzata per il pagamento.\n\nNota: i costi di gestione e transazione del servizio non sono rimborsabili.'
              : 'Sei sicuro di voler abbandonare questa partita? Verranno rimossi anche i tuoi ospiti.',
          style: const TextStyle(color: AppTheme.testoSecondario, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Indietro',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.tile),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx); // Chiude il Dialog

              // Mostra un caricamento visivo
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(
                  child: CircularProgressIndicator(color: AppTheme.accent),
                ),
              );

              String? errore;

              try {
                if (haPagatoInApp) {
                  // 🟢 Chiamata alla Edge Function di rimborso parziale Stripe
                  final res = await Supabase.instance.client.functions.invoke(
                    'rimborsa-partita',
                    body: {'id_partita': partita.id},
                  );

                  if (res.status != 200 ||
                      res.data == null ||
                      res.data['error'] != null) {
                    errore =
                        res.data?['error'] ?? 'Errore durante il rimborso.';
                  }
                } else {
                  // Flusso classico di abbandono partita
                  final service = ref.read(partitaServiceProvider);
                  errore = await service.abbandonaPartita(
                    partita: partita,
                    giocatoreDaRimuovere: utente,
                  );
                }
              } catch (e) {
                errore = e.toString();
              }

              // Chiude il caricamento
              if (context.mounted) Navigator.pop(context);

              if (context.mounted) {
                if (errore != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(errore),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                } else {
                  Navigator.pop(context); // Chiude la Bottom Sheet
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        haPagatoInApp
                            ? 'Prenotazione annullata. Rimborso di ${quotaCampo.toStringAsFixed(2)} € inviato!'
                            : 'Hai abbandonato la partita.',
                      ),
                      backgroundColor: AppTheme.neonGreen,
                    ),
                  );
                  ref.invalidate(partiteUtenteProvider(utente.id));
                  ref.invalidate(matchInZonaProvider);
                }
              }
            },
            child: Text(
              haPagatoInApp ? 'Conferma Rimborso' : 'Conferma',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ),
  );
}
