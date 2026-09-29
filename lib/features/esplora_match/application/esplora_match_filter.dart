import 'package:app_campi/core/models/partita.dart';
import 'package:app_campi/core/models/utente.dart';
import 'package:app_campi/core/theme/app_constants.dart';
import '../domain/filtro_distanza.dart';
import '../domain/partita_con_dati.dart';
import 'package:flutter/foundation.dart';

/// Restituisce true se l'utente loggato è già iscritto alla [partita].
bool isGiaIscritto(Partita partita, Utente? utenteLoggato) {
  if (utenteLoggato == null) return false;
  final idLoggato = utenteLoggato.id.toString().trim().toLowerCase();
  return partita.listaGiocatoriIscritti.any(
    (g) => g.idUtente.toString().trim().toLowerCase() == idLoggato,
  );
}

List<PartitaConDati> filtraEOrdina(
  List<Map<String, dynamic>> partite,
  Utente? utenteLoggato,
  FiltroDistanza filtro,
) {
  final List<PartitaConDati> normalizzate = [];

  for (final raw in partite) {
    final jsonNorm = Map<String, dynamic>.from(raw);
    jsonNorm['campo'] = jsonNorm['campo'] ?? jsonNorm['campi'];
    try {
      normalizzate.add(
        PartitaConDati(raw: raw, partita: Partita.fromJson(jsonNorm)),
      );
    } catch (e) {
      debugPrint('🔴 ERRORE Partita.fromJson in Esplora Match: $e');
      debugPrint('🔴 RAW PARTITA: $raw');
      continue;
    }
  }

  final filtrate = normalizzate.where((item) {
    if (isGiaIscritto(item.partita, utenteLoggato)) return false;
    final distanza = (item.raw['distanza_km'] as num?)?.toDouble() ?? 0.0;
    return switch (filtro) {
      FiltroDistanza.vicini => distanza <= MatchThresholds.distanzaVicino,
      FiltroDistanza.estesa => distanza <= MatchThresholds.distanzaEstesa,
    };
  }).toList();

  filtrate.sort((a, b) {
    final da = (a.raw['distanza_km'] as num?)?.toDouble() ?? 0;
    final db = (b.raw['distanza_km'] as num?)?.toDouble() ?? 0;
    return da.compareTo(db);
  });

  return filtrate;
}
