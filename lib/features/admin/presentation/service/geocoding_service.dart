import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GeocodingService {
  static Future<Map<String, double>?> ottieniCoordinate({
    required String via,
    required String civico,
    required String cap,
    required String citta,
    required String provincia,
  }) async {
    try {
      final viaPulita = via.trim();
      final civicoPulito = civico.trim();
      final capPulito = cap.trim();
      final cittaPulita = citta.trim();
      final provinciaPulita = provincia.trim().toUpperCase();

      if (viaPulita.isEmpty || cittaPulita.isEmpty) {
        debugPrint('Geocoding: via o città mancanti.');

        return null;
      }

      debugPrint(
        'Geocoding Geoapify: '
        '$viaPulita $civicoPulito, '
        '$capPulito $cittaPulita, '
        '$provinciaPulita',
      );

      final response = await Supabase.instance.client.functions.invoke(
        'geocodifica-indirizzo',
        body: {
          'via': viaPulita,
          'civico': civicoPulito,
          'cap': capPulito,
          'citta': cittaPulita,
          'provincia': provinciaPulita,
        },
      );

      final data = response.data;

      debugPrint('Risposta geocodifica: $data');

      if (data is! Map) {
        debugPrint('Geocoding: risposta non valida.');

        return null;
      }

      if (data['success'] != true) {
        debugPrint('Geocoding fallito: ${data['error']}');

        return null;
      }

      final latitudine = double.tryParse(data['latitudine']?.toString() ?? '');

      final longitudine = double.tryParse(
        data['longitudine']?.toString() ?? '',
      );

      if (latitudine == null || longitudine == null) {
        debugPrint('Geocoding: coordinate non valide.');

        return null;
      }

      debugPrint(
        'Coordinate trovate: '
        '$latitudine, $longitudine',
      );

      return {'latitudine': latitudine, 'longitudine': longitudine};
    } on FunctionException catch (e) {
      debugPrint(
        'Errore Edge Function geocodifica: '
        '${e.status} - ${e.details}',
      );

      return null;
    } catch (e) {
      debugPrint('Errore GeocodingService: $e');

      return null;
    }
  }
}
