import '../repositories/campi_repository.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CampiService {
  final CampiRepository _repository;

  CampiService({CampiRepository? repository})
    : _repository = repository ?? CampiRepository();

  // GESTIONE ORARI SOCIETÀ
  Future<void> salvaOrariSocieta({
    required String idSocieta,
    required List<Map<String, dynamic>> listaOrari,
  }) async {
    try {
      String? formattaOra(dynamic tempo, bool isChiuso) {
        if (isChiuso || tempo == null) return null;
        if (tempo is TimeOfDay) {
          return '${tempo.hour.toString().padLeft(2, '0')}:${tempo.minute.toString().padLeft(2, '0')}:00';
        }
        String str = tempo.toString();
        if (str.length == 5) return '$str:00';
        return str;
      }

      final List<Map<String, dynamic>> datiDaInviare = listaOrari.map((giorno) {
        final bool isChiuso = giorno['is_chiuso'] == true;
        final bool hasSecondoTurno = giorno['has_secondo_turno'] == true;

        return {
          'id_societa': idSocieta,
          'giorno_settimana': giorno['giorno_settimana'],
          'is_chiuso': isChiuso,
          'orario_apertura': formattaOra(giorno['orario_apertura'], isChiuso),
          'orario_chiusura': formattaOra(giorno['orario_chiusura'], isChiuso),
          'orario_apertura_2': hasSecondoTurno
              ? formattaOra(giorno['orario_apertura_2'], isChiuso)
              : null,
          'orario_chiusura_2': hasSecondoTurno
              ? formattaOra(giorno['orario_chiusura_2'], isChiuso)
              : null,
        };
      }).toList();

      await _repository.upsertOrariSocieta(datiDaInviare);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> salvaCampo({
    required String idSocieta,
    required String nomeCampo,
    required int numeroGiocatori,
    required double prezzo,
    required bool isCoperto,
  }) async {
    try {
      final capienzaTotale = numeroGiocatori * 2;

      await _repository.insertCampo({
        'id_societa': idSocieta,
        'nome_campo': nomeCampo,
        'numero_di_giocatori': capienzaTotale,
        'prezzo': prezzo,
        'coperto': isCoperto,
      });
    } catch (e) {
      throw Exception('Impossibile salvare il campo');
    }
  }

  Future<List<Map<String, dynamic>>> ottieniCampiSocieta(
    String idSocieta,
  ) async {
    try {
      return await _repository.fetchCampiSocieta(idSocieta);
    } catch (e) {
      throw Exception('Impossibile recuperare la lista dei campi');
    }
  }

  Future<void> aggiornaCampo({
    required String idCampo,
    required String nomeCampo,
    required int numeroGiocatori,
    required double prezzo,
    required bool isCoperto,
  }) async {
    try {
      final capienzaTotale = numeroGiocatori * 2;

      await _repository.updateCampo(idCampo, {
        'nome_campo': nomeCampo,
        'numero_di_giocatori': capienzaTotale,
        'prezzo': prezzo,
        'coperto': isCoperto,
      });
    } catch (e) {
      throw Exception('Impossibile aggiornare il campo');
    }
  }

  Future<void> eliminaCampo(String idCampo) async {
    try {
      await Supabase.instance.client.rpc(
        'elimina_campo_e_notifica',
        params: {'p_id_campo': idCampo},
      );
    } catch (e) {
      throw Exception('Errore durante la chiusura del campo e notifica utenti');
    }
  }
}
