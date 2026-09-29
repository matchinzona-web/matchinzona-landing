import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_campi/core/theme/app_theme.dart';

final List<Map<String, String>> livelliDisponibili = [
  {
    'titolo': 'Principiante',
    'descrizione': 'Ho appena iniziato o gioco molto raramente.',
  },
  {
    'titolo': 'Amatoriale',
    'descrizione': 'Conosco le regole base e gioco ogni tanto.',
  },
  {
    'titolo': 'Intermedio',
    'descrizione': 'Gioco con continuità e ho una buona visione di gioco.',
  },
  {
    'titolo': 'Avanzato',
    'descrizione': 'Ritmo alto, ottima tecnica e padronanza del gioco.',
  },
  {
    'titolo': 'Esperto / Agonista',
    'descrizione': 'Livello competitivo elevato o tesserato agonista.',
  },
];

// Normalizza la chiave per il database (es. tennis_singolo e tennis_doppio diventano entrambi "tennis")
String _normalizzaChiaveSport(String sport) {
  if (sport.contains('tennis')) return 'tennis';
  return sport;
}

// Icona dinamica per il popup
IconData _getIconaSport(String sport) {
  if (sport.contains('calcio')) return Icons.sports_soccer;
  if (sport.contains('tennis')) return Icons.sports_tennis;
  if (sport.contains('padel')) return Icons.sports_tennis;
  if (sport.contains('basket')) return Icons.sports_basketball;
  if (sport.contains('pallavolo')) return Icons.sports_volleyball;
  return Icons.sports_score;
}

// Titolo leggibile nel popup
String _getTitoloSportPulito(String sportChiave) {
  switch (sportChiave) {
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
    case 'tennis':
      return 'Tennis';
    case 'padel':
      return 'Padel';
    case 'basket':
      return 'Basket';
    case 'volley':
      return 'Pallavolo';
    default:
      return sportChiave.toUpperCase();
  }
}

Future<void> verificaESelezionaLivello({
  required BuildContext context,
  required String userId,
  required Map<String, dynamic>? livelliSportAttuali,
  required String sport,
  required VoidCallback onCompletato,
}) async {
  Map<String, dynamic> mappaLivelli = Map.from(livelliSportAttuali ?? {});

  // Sia 'tennis_singolo' che 'tennis_doppio' useranno la chiave "tennis"
  final String chiaveSport = _normalizzaChiaveSport(sport);

  // Se ha già un livello impostato per questo sport, proseguiamo direttamente
  if (mappaLivelli.containsKey(chiaveSport) &&
      mappaLivelli[chiaveSport] != null) {
    onCompletato();
    return;
  }

  // Mostra il Bottom Sheet
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext sheetContext) {
      return Container(
        decoration: const BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getIconaSport(chiaveSport),
                      color: AppTheme.accent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Livello ${_getTitoloSportPulito(chiaveSport)}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          "Serve per bilanciare i match in zona.",
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: livelliDisponibili.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = livelliDisponibili[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        Navigator.pop(sheetContext);

                        // 1. Aggiorniamo la mappa locale
                        mappaLivelli[chiaveSport] = item['titolo'];

                        try {
                          debugPrint(
                            "Sto salvando su Supabase per $userId la mappa: $mappaLivelli",
                          );

                          // 2. Inviamo la mappa aggiornata a Supabase
                          await Supabase.instance.client
                              .from('utenti')
                              .update({
                                'livelli_sport':
                                    mappaLivelli, // Passiamo la Map aggiornata
                              })
                              .eq('id', userId);

                          debugPrint(
                            "Livello salvato con successo per $chiaveSport: ${item['titolo']}",
                          );
                        } catch (e) {
                          debugPrint(
                            "❌ Errore durante il salvataggio su Supabase",
                          );
                        }

                        // 3. Proseguiamo con il callback
                        onCompletato();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['titolo']!,
                                    style: const TextStyle(
                                      color: AppTheme.accent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    item['descrizione']!,
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppTheme.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
