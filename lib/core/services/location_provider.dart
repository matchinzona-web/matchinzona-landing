import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:app_campi/core/repositories/partita_repository.dart';
import 'package:app_campi/core/theme/app_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

final gpsAttivoProvider = StreamProvider<bool>((ref) async* {
  try {
    yield await Geolocator.isLocationServiceEnabled();
  } catch (e) {
    yield false;
  }

  try {
    await for (var status in Geolocator.getServiceStatusStream()) {
      yield status == ServiceStatus.enabled;
    }
  } catch (e) {
    // Se lo stream nativo fallisce (es. piattaforma non supportata)
    // resta semplicemente sull'ultimo valore noto, senza crashare.
  }
});

final posizioneAttualeProvider = FutureProvider<Position?>((ref) async {
  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return null;
    }

    final permission = await Geolocator.checkPermission();

    // IMPORTANTE:
    // qui NON chiediamo mai il permesso automaticamente.
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 5));
    } catch (_) {
      return await Geolocator.getLastKnownPosition();
    }
  } catch (_) {
    return null;
  }
});

final permessoPosizioneProvider = FutureProvider<LocationPermission>((
  ref,
) async {
  try {
    return await Geolocator.checkPermission();
  } catch (_) {
    return LocationPermission.denied;
  }
});

Future<LocationPermission> richiediPermessoPosizione() async {
  try {
    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission;
  } catch (_) {
    return LocationPermission.denied;
  }
}

Future<LocationPermission> richiediPermessoPosizionePrimaVolta() async {
  try {
    final prefs = await SharedPreferences.getInstance();

    final bool richiestaGiaMostrata =
        prefs.getBool('permesso_posizione_richiesto') ?? false;

    var permission = await Geolocator.checkPermission();

    // Se è già concesso, non dobbiamo fare nulla.
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      return permission;
    }

    // Se abbiamo già mostrato la richiesta automatica in passato,
    // NON la mostriamo di nuovo.
    if (richiestaGiaMostrata) {
      return permission;
    }

    // Segniamo subito che la richiesta automatica è stata fatta.
    await prefs.setBool('permesso_posizione_richiesto', true);

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission;
  } catch (_) {
    return LocationPermission.denied;
  }
}

final matchInZonaProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final gpsAttivo = await ref.watch(gpsAttivoProvider.future);

  if (!gpsAttivo) {
    throw Exception('GPS_SPENTO');
  }

  final permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    throw Exception('PERMESSO_POSIZIONE_NEGATO');
  }

  final posizione = await ref.watch(posizioneAttualeProvider.future);

  if (posizione == null) {
    throw Exception('POSIZIONE_NON_DISPONIBILE');
  }

  final repository = PartitaRepository();

  try {
    final datiGrezzi = await repository.getMatchPubbliciApertiGeolocalizzati(
      latUtente: posizione.latitude,
      lonUtente: posizione.longitude,
      raggioKm: MatchThresholds.distanzaEstesa,
    );

    return datiGrezzi;
  } catch (e, stackTrace) {
    debugPrint('Errore caricamento Match in Zona: $e');
    Error.throwWithStackTrace(e, stackTrace);
  }
});
