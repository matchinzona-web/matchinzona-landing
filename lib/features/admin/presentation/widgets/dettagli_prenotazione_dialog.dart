import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app_campi/core/theme/app_theme.dart';

class DettagliPrenotazioneDialog extends StatelessWidget {
  final Map<String, dynamic> partita;

  const DettagliPrenotazioneDialog({super.key, required this.partita});

  Future<void> _annullaPrenotazioneManuale(BuildContext context) async {
    final idPartita = partita['id']?.toString();

    if (idPartita == null || idPartita.isEmpty) {
      _mostraErrore(context, 'Impossibile identificare la prenotazione.');
      return;
    }

    final conferma = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: AppTheme.statoErrore.withOpacity(0.6)),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.statoErrore),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Annulla prenotazione',
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
            'Vuoi davvero annullare questa prenotazione manuale?\n\n'
            'Lo slot tornerà disponibile per nuove prenotazioni.',
            style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'NO, MANTIENI',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.statoErrore,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'SÌ, ANNULLA',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
    );

    if (conferma != true || !context.mounted) {
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('partite')
          .update({'stato_partita': 'annullata'})
          .eq('id', idPartita)
          .eq('origine_prenotazione', 'gestore')
          .select('id');

      if (!context.mounted) return;

      if (response.isEmpty) {
        _mostraErrore(context, 'La prenotazione non può essere annullata.');
        return;
      }

      Navigator.of(context).pop(true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Prenotazione annullata. Lo slot è nuovamente disponibile.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppTheme.statoSuccesso,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      debugPrint('Errore annullamento prenotazione manuale: $e');

      _mostraErrore(
        context,
        'Errore durante l’annullamento della prenotazione.',
      );
    }
  }

  void _mostraErrore(BuildContext context, String messaggio) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          messaggio,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.statoErrore,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
    debugPrint("🟢 STRUTTURA PARTITA: $partita");
    final org = partita['organizzatore'] ?? {};
    final campo = partita['campo'] ?? {};
    final bool isPrenotazioneManuale =
        partita['origine_prenotazione'] == 'gestore';

    final String nomeClienteManuale = (partita['nome_cliente_manual'] ?? '')
        .toString()
        .trim();

    final String telefonoClienteManuale =
        (partita['telefono_cliente_manual'] ?? '').toString().trim();
    final String notaGestore = (partita['nota_gestore'] ?? '')
        .toString()
        .trim();
    final String nomeCampo = campo['nome_campo'] ?? 'Campo Sconosciuto';
    final String orarioInizio =
        partita['orario_inizio']?.toString().substring(0, 5) ?? '--:--';
    final String orarioFine =
        partita['orario_fine']?.toString().substring(0, 5) ?? '--:--';
    final bool isPagato = partita['is_pagato'] == true;

    final int giocatoriPrenotati =
        partita['numero_giocatori_prenotati'] as int? ?? 1;

    final int maxGiocatoriDb = partita['max_giocatori'] as int? ?? 0;

    final int maxCampo = campo['numero_di_giocatori'] as int? ?? 2;

    final int maxGiocatoriReali = maxGiocatoriDb > 0
        ? maxGiocatoriDb
        : maxCampo;

    final String sportRaw = (partita['sport'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    String sportDisputato;

    switch (sportRaw) {
      case 'tennis_singolo':
        sportDisputato = 'Tennis singolo';
        break;
      case 'tennis_doppio':
        sportDisputato = 'Tennis doppio';
        break;
      case 'padel':
        sportDisputato = 'Padel';
        break;
      case 'calcio_5':
        sportDisputato = 'Calcio a 5';
        break;
      case 'calcio_6':
        sportDisputato = 'Calcio a 6';
        break;
      case 'calcio_7':
        sportDisputato = 'Calcio a 7';
        break;
      case 'calcio_8':
        sportDisputato = 'Calcio a 8';
        break;
      case 'calcio_11':
        sportDisputato = 'Calcio a 11';
        break;
      case 'basket':
        sportDisputato = 'Basket';
        break;
      case 'pallavolo':
      case 'volley':
        sportDisputato = 'Pallavolo';
        break;
      default:
        sportDisputato = 'Sport';
    }

    // Prezzo storico fissato al momento della prenotazione.
    final double incassoTotale =
        (partita['importo_totale'] as num?)?.toDouble() ?? 0.0;

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
              leading: Icon(
                _iconaSport(sportRaw),
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
                        "$giocatoriPrenotati / $maxGiocatoriReali",
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
            // NOME
            if (isPrenotazioneManuale) ...[
              if (nomeClienteManuale.isNotEmpty)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person, color: Colors.grey),
                  title: Text(
                    nomeClienteManuale,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Cliente',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
            ] else ...[
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
            ],

            // EMAIL
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.email, color: Colors.grey),
              title: Text(
                org['email'] ?? 'N/D',
                style: const TextStyle(color: Colors.white),
              ),
            ),

            // TELEFONO
            if (isPrenotazioneManuale) ...[
              if (telefonoClienteManuale.isNotEmpty)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.phone, color: Colors.grey),
                  title: Text(
                    telefonoClienteManuale,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
            ] else ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.phone, color: Colors.grey),
                title: Text(
                  org['telefono'] ?? 'N/D',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
            if (isPrenotazioneManuale && notaGestore.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.sticky_note_2_outlined,
                          color: AppTheme.neonOrange,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Nota interna',
                          style: TextStyle(
                            color: AppTheme.neonOrange,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      notaGestore,
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
      actions: [
        if (isPrenotazioneManuale && partita['stato_partita'] != 'annullata')
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => _annullaPrenotazioneManuale(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.statoErrore,
                side: const BorderSide(color: AppTheme.statoErrore),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.event_busy_rounded, size: 20),
              label: const Text(
                'ANNULLA PRENOTAZIONE',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
              ),
            ),
          ),

        const SizedBox(width: 6),

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
