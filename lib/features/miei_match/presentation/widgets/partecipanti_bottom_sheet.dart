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
      final partecipantiVisibili = partita.listaGiocatoriIscritti.where((g) {
        if (utenteLoggato == null) return true;

        return g.idUtente.toString().trim().toLowerCase() !=
            utenteLoggato.id.toString().trim().toLowerCase();
      }).toList();

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
                if (partecipantiVisibili.isEmpty &&
                    partita.statoPartita == 'aperta_a_rischio') ...[
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      "Nessun altro giocatore iscritto.",
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                ] else if (partecipantiVisibili.isNotEmpty) ...[
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: Scrollbar(
                      thumbVisibility: partecipantiVisibili.length > 4,
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        itemCount: partecipantiVisibili.length,
                        itemBuilder: (context, index) {
                          final giocatore = partecipantiVisibili[index];
                          final nomeCompleto =
                              "${giocatore.nomeGiocatore ?? 'Utente'} ${giocatore.cognomeGiocatore ?? 'Sconosciuto'}";
                          final iniziale = nomeCompleto.isNotEmpty
                              ? nomeCompleto[0].toUpperCase()
                              : 'U';

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.02),
                              borderRadius: BorderRadius.circular(
                                AppRadius.tile,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 2,
                              ),
                              onTap: () => _mostraDettagliGiocatore(
                                context,
                                giocatore.idUtente,
                                partita.sportNormalizzato,
                                giocatore.ospitiExtra,
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
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (giocatore.ospitiExtra > 0) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      "+ ${giocatore.ospitiExtra} ${giocatore.ospitiExtra == 1 ? 'ospite' : 'ospiti'}",
                                      style: const TextStyle(
                                        color: AppTheme.neonOrange,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 4),

                                  const Text(
                                    "Tocca per vedere il profilo",
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
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

Future<void> _mostraDettagliGiocatore(
  BuildContext context,
  String idUtente,
  String sportPartita,
  int ospitiExtra,
) async {
  try {
    final data = await Supabase.instance.client
        .from('utenti')
        .select()
        .eq('id', idUtente)
        .single();

    final utente = Utente.fromJson(data);

    final sportNormalizzato = sportPartita.trim().toLowerCase();

    String sportBase = sportNormalizzato;

    if (sportNormalizzato.startsWith('calcio')) {
      sportBase = 'calcio';
    } else if (sportNormalizzato.startsWith('tennis')) {
      sportBase = 'tennis';
    } else if (sportNormalizzato == 'pallavolo') {
      sportBase = 'pallavolo';
    } else if (sportNormalizzato == 'basket') {
      sportBase = 'basket';
    } else if (sportNormalizzato == 'padel') {
      sportBase = 'padel';
    }

    String livello = 'Non specificato';

    final livelli = utente.livelliSport;

    if (livelli != null && livelli.isNotEmpty) {
      for (final entry in livelli.entries) {
        final chiave = entry.key.toString().trim().toLowerCase();

        if (chiave == sportNormalizzato || chiave == sportBase) {
          livello = entry.value.toString();
          break;
        }
      }
    }

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
            decoration: BoxDecoration(
              color: AppTheme.darkBg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.sheet),
              ),
              border: const Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade700,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 24),

                CircleAvatar(
                  radius: 34,
                  backgroundColor: AppTheme.accent.withOpacity(0.15),
                  child: Text(
                    utente.nome.isNotEmpty ? utente.nome[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: AppTheme.accent,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  utente.nomeCompleto,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 22),

                _InfoGiocatoreTile(
                  icona: Icons.cake_outlined,
                  titolo: 'Età',
                  valore: utente.eta != null
                      ? '${utente.eta} anni'
                      : 'Non specificata',
                ),

                const SizedBox(height: 10),

                _InfoGiocatoreTile(
                  icona: Icons.sports_rounded,
                  titolo: 'Sport',
                  valore: _nomeSportDettaglio(sportPartita),
                ),

                const SizedBox(height: 10),

                _InfoGiocatoreTile(
                  icona: Icons.bar_chart_rounded,
                  titolo: 'Livello',
                  valore: livello,
                ),

                if (ospitiExtra > 0) ...[
                  const SizedBox(height: 10),
                  _InfoGiocatoreTile(
                    icona: Icons.group_add_rounded,
                    titolo: 'Ospiti',
                    valore:
                        '$ospitiExtra ${ospitiExtra == 1 ? 'ospite' : 'ospiti'}',
                  ),
                ],

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textPrimary,
                      side: const BorderSide(color: AppTheme.cardBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.tile),
                      ),
                    ),
                    child: const Text(
                      'Chiudi',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  } catch (e) {
    debugPrint('Errore caricamento dettagli giocatore: $e');

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Non è stato possibile caricare i dettagli del giocatore.',
        ),
        backgroundColor: AppTheme.statoErrore,
      ),
    );
  }
}

String _nomeSportDettaglio(String sport) {
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
      return 'Pallavolo';
    default:
      return sport;
  }
}

class _InfoGiocatoreTile extends StatelessWidget {
  final IconData icona;
  final String titolo;
  final String valore;

  const _InfoGiocatoreTile({
    required this.icona,
    required this.titolo,
    required this.valore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icona, color: AppTheme.accent, size: 20),
          const SizedBox(width: 12),
          Text(
            titolo,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              valore,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
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

              // CONTROLLO LIMITE ABBANDONO/RIMBORSO
              final inizioPartita = DateTime(
                partita.dataPartita.year,
                partita.dataPartita.month,
                partita.dataPartita.day,
                int.parse(partita.orarioInizio.split(':')[0]),
                int.parse(partita.orarioInizio.split(':')[1]),
              );

              final adesso = DateTime.now();

              if (adesso.isAfter(inizioPartita)) {
                await showDialog<void>(
                  context: context,
                  builder: (dialogContext) {
                    return AlertDialog(
                      backgroundColor: AppTheme.cardBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        side: BorderSide(
                          color: AppTheme.statoErrore.withOpacity(0.6),
                        ),
                      ),
                      title: const Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: AppTheme.statoErrore,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Operazione non disponibile',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      content: const Text(
                        'La partita è già iniziata e non può essere annullata.',
                        style: TextStyle(
                          color: AppTheme.testoSecondario,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      actions: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.neonOrange,
                            foregroundColor: Colors.black,
                          ),
                          child: const Text(
                            'HO CAPITO',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    );
                  },
                );

                return;
              }

              if (adesso.isAfter(
                inizioPartita.subtract(const Duration(minutes: 30)),
              )) {
                await showDialog<void>(
                  context: context,
                  builder: (dialogContext) {
                    return AlertDialog(
                      backgroundColor: AppTheme.cardBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        side: BorderSide(
                          color: AppTheme.statoErrore.withOpacity(0.6),
                        ),
                      ),
                      title: const Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: AppTheme.statoErrore,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Operazione non disponibile',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      content: const Text(
                        'Non puoi annullare la prenotazione quando mancano meno di 30 minuti all\'inizio.',
                        style: TextStyle(
                          color: AppTheme.testoSecondario,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      actions: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.neonOrange,
                            foregroundColor: Colors.black,
                          ),
                          child: const Text(
                            'HO CAPITO',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    );
                  },
                );

                return;
              }

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
                  await showDialog<void>(
                    context: context,
                    builder: (dialogContext) {
                      return AlertDialog(
                        backgroundColor: AppTheme.cardBg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          side: BorderSide(
                            color: AppTheme.statoErrore.withOpacity(0.6),
                          ),
                        ),
                        title: const Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: AppTheme.statoErrore,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Operazione non disponibile',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                        content: Text(
                          errore!,
                          style: const TextStyle(
                            color: AppTheme.testoSecondario,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        actions: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(dialogContext);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.neonOrange,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.tile,
                                ),
                              ),
                            ),
                            child: const Text(
                              'HO CAPITO',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      );
                    },
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
