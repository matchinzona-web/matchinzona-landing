import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class GeocodingService {
  static Future<Map<String, double>?> ottieniCoordinate(
    String indirizzo,
  ) async {
    final queryPulita = indirizzo.trim();
    if (queryPulita.isEmpty) return null;

    // 1. Chiamata a Photon
    try {
      final uriPhoton = Uri.parse(
        'https://photon.komoot.io/api/?q=${Uri.encodeComponent(queryPulita)}&limit=1&lang=it',
      );

      final responsePhoton = await http.get(uriPhoton);

      if (responsePhoton.statusCode == 200) {
        final dataPhoton = json.decode(utf8.decode(responsePhoton.bodyBytes));
        final features = dataPhoton['features'] as List?;
        if (features != null && features.isNotEmpty) {
          final List coordinates = features[0]['geometry']['coordinates'];
          return {
            'longitudine': (coordinates[0] as num).toDouble(),
            'latitudine': (coordinates[1] as num).toDouble(),
          };
        }
      } else {
        debugPrint("Photon status: ${responsePhoton.statusCode}");
      }
    } catch (e) {
      debugPrint("Errore Photon: $e");
    }

    // Piccola pausa prima del fallback per evitare rate limit
    await Future.delayed(const Duration(milliseconds: 1100));

    // 2. Chiamata di riserva a Nominatim
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(queryPulita)}&countrycodes=it&limit=1',
      );

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'AppCampi/1.0 (info@appcampi.it)',
          'Accept-Language': 'it-IT,it;q=0.9',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        if (data.isNotEmpty) {
          return {
            'latitudine': double.parse(data[0]['lat'].toString()),
            'longitudine': double.parse(data[0]['lon'].toString()),
          };
        }
      } else {
        debugPrint("Nominatim status: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Errore Nominatim: $e");
    }

    return null;
  }
}
