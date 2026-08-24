import 'package:flutter/material.dart';
import 'package:app_campi/core/theme/app_theme.dart';

class DettagliPrenotazioneDialog extends StatelessWidget {
  final Map<String, dynamic> partita;

  const DettagliPrenotazioneDialog({super.key, required this.partita});

  @override
  Widget build(BuildContext context) {
    debugPrint("🟢 STRUTTURA PARTITA: $partita");
    final org = partita['organizzatore'] ?? {};
    final campo = partita['campo'] ?? {};
    final String nomeCampo = campo['nome_campo'] ?? 'Campo Sconosciuto';
    final String orarioInizio =
        partita['orario_inizio']?.toString().substring(0, 5) ?? '--:--';
    final String orarioFine =
        partita['orario_fine']?.toString().substring(0, 5) ?? '--:--';
    final bool isPagato = partita['is_pagato'] == true;

    // 🟢 1. CALCOLO GIOCATORI
    final int giocaroriPrenotati =
        partita['numero_giocatori_prenotati'] as int? ?? 1;
    final int maxGiocatoriDb = partita['max_giocatori'] as int? ?? 0;
    final int maxCampo = campo['numero_di_giocatori'] as int? ?? 2;

    int maxGiocatoriReali = maxGiocatoriDb > 0 ? maxGiocatoriDb : maxCampo;
    if (nomeCampo.toLowerCase().contains('tennis') && giocaroriPrenotati > 2) {
      maxGiocatoriReali = 4;
    }

    // 🟢 2. DETERMINA LO SPORT DISPUTATO
    String sportDisputato = "Calcio / Altro";
    final String nomeLower = nomeCampo.toLowerCase();
    if (nomeLower.contains('tennis')) {
      sportDisputato = maxGiocatoriReali == 4
          ? "Tennis Doppio"
          : "Tennis Singolo";
    } else if (nomeLower.contains('padel')) {
      sportDisputato = "Padel";
    } else if (nomeLower.contains('calcio')) {
      sportDisputato = "Calcio a 5";
    }

    // 🟢 3. CALCOLO DINAMICO DELL'INCASSO DAL DATABASE
    // 🟢 3. CALCOLO DINAMICO DELL'INCASSO (FALLBACK MULTIPLO)
    final List<dynamic> tariffeRaw =
        campo['tariffe_sport'] as List<dynamic>? ?? [];

    // Cerca il prezzo base prima nel campo, poi nella partita stessa
    double incassoTotale =
        (campo['prezzo'] as num?)?.toDouble() ??
        (partita['prezzo'] as num?)?.toDouble() ??
        (partita['prezzo_totale'] as num?)?.toDouble() ??
        0.0;

    // Se ci sono tariffe specifiche per sport, cerca quella per lo sport giocato
    if (tariffeRaw.isNotEmpty) {
      final tariffaTrovata = tariffeRaw.firstWhere((t) {
        final String sportName = (t['sport'] ?? '').toString().toLowerCase();
        return sportName == sportDisputato.toLowerCase() ||
            (sportDisputato == "Tennis Doppio" &&
                sportName.contains('doppio')) ||
            (sportDisputato == "Tennis Singolo" &&
                sportName.contains('singolo')) ||
            (sportDisputato == "Calcio a 5" &&
                (sportName.contains('calcio') || sportName.contains('5')));
      }, orElse: () => null);

      if (tariffaTrovata != null && tariffaTrovata['prezzo'] != null) {
        incassoTotale = (tariffaTrovata['prezzo'] as num).toDouble();
      }
    }

    return AlertDialog(
      backgroundColor: AppTheme.cardBg,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppTheme.neonOrange, width: 1.5),
        borderRadius: BorderRadius.circular(15),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Dettagli Prenotazione',
            style: TextStyle(
              color: AppTheme.neonOrange,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.neonOrange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "${incassoTotale.toStringAsFixed(2)}€",
              style: const TextStyle(
                color: AppTheme.neonOrange,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🟢 BADGE STATO PAGAMENTO
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: isPagato
                    ? AppTheme.neonGreen.withOpacity(0.12)
                    : AppTheme.statoErrore.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isPagato ? AppTheme.neonGreen : AppTheme.statoErrore,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isPagato
                        ? Icons.check_circle_rounded
                        : Icons.pending_actions_rounded,
                    color: isPagato ? AppTheme.neonGreen : AppTheme.statoErrore,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isPagato ? "PAGATO IN APP" : "DA PAGARE AL CAMPO",
                    style: TextStyle(
                      color: isPagato
                          ? AppTheme.neonGreen
                          : AppTheme.statoErrore,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.sports_tennis,
                color: Colors.white,
                size: 28,
              ),
              title: Text(
                nomeCampo,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: Text(
                'Dalle $orarioInizio alle $orarioFine',
                style: const TextStyle(color: AppTheme.neonOrange),
              ),
            ),
            const Divider(color: Colors.grey),

            // 🟢 RIQUADRO INFO SPORT E GIOCATORI
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "SPORT",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sportDisputato,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        "GIOCATORI",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "$giocaroriPrenotati / $maxGiocatoriReali",
                        style: const TextStyle(
                          color: AppTheme.neonGreen,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(color: Colors.grey),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person, color: Colors.grey),
              title: Text(
                '${org['nome'] ?? 'N/D'} ${org['cognome'] ?? ''}',
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Organizzatore',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.email, color: Colors.grey),
              title: Text(
                org['email'] ?? 'N/D',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.phone, color: Colors.grey),
              title: Text(
                org['telefono'] ?? 'N/D',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Chiudi',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      ],
    );
  }
}
