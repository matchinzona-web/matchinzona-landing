import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_campi/core/models/utente.dart';
import 'package:app_campi/features/admin/presentation/service/geocoding_service.dart';
import 'package:app_campi/features/profilo/data/profilo_repository.dart';

class ProfiloState {
  final bool isLoading;
  final bool isSaving;
  final String? fotoUrl;
  final Uint8List? fotoBytesLocali;
  final String? estensioneFotoLocale;
  final String telefonoCompleto;
  final String initialPhoneNumber;
  final String? errorMessage;

  const ProfiloState({
    this.isLoading = true,
    this.isSaving = false,
    this.fotoUrl,
    this.fotoBytesLocali,
    this.estensioneFotoLocale,
    this.telefonoCompleto = '',
    this.initialPhoneNumber = '',
    this.errorMessage,
  });

  ProfiloState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? fotoUrl,
    bool clearFotoUrl = false,
    Uint8List? fotoBytesLocali,
    bool clearFotoBytes = false,
    String? estensioneFotoLocale,
    bool clearEstensione = false,
    String? telefonoCompleto,
    String? initialPhoneNumber,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProfiloState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      fotoUrl: clearFotoUrl ? null : (fotoUrl ?? this.fotoUrl),
      fotoBytesLocali: clearFotoBytes
          ? null
          : (fotoBytesLocali ?? this.fotoBytesLocali),
      estensioneFotoLocale: clearEstensione
          ? null
          : (estensioneFotoLocale ?? this.estensioneFotoLocale),
      telefonoCompleto: telefonoCompleto ?? this.telefonoCompleto,
      initialPhoneNumber: initialPhoneNumber ?? this.initialPhoneNumber,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  bool get urlValido =>
      fotoUrl != null && fotoUrl!.trim().isNotEmpty && fotoUrl != 'null';
  bool get haImmagine => fotoBytesLocali != null || urlValido;
}

class ProfiloNotifier extends Notifier<ProfiloState> {
  late final ProfiloRepository _repository;

  @override
  ProfiloState build() {
    _repository = ref.watch(profiloRepositoryProvider);
    return const ProfiloState();
  }

  Future<void> caricaDatiSocieta(String idUtente) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final data = await _repository.getDatiSocieta(idUtente);

      if (data != null) {
        final tel = data['cellulare']?.toString() ?? '';
        state = state.copyWith(
          fotoUrl: data['foto_url']?.toString(),
          telefonoCompleto: tel,
          initialPhoneNumber: tel,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      debugPrint("Errore caricamento società: $e");
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Impossibile caricare i dati del profilo.',
      );
    }
  }

  void setFoto(Uint8List bytes, String estensione) {
    state = state.copyWith(
      fotoBytesLocali: bytes,
      estensioneFotoLocale: estensione,
      clearError: true,
    );
  }

  void rimuoviFoto() {
    state = state.copyWith(
      clearFotoUrl: true,
      clearFotoBytes: true,
      clearEstensione: true,
    );
  }

  void setTelefono(String numero) {
    state = state.copyWith(telefonoCompleto: numero);
  }

  Future<bool> salvaProfilo({
    required Utente utenteLoggato,
    required String via,
    required String civico,
    required String cap,
    required String citta,
    required String provincia,
    required String telefonoFisso,
    required String nome,
    required String cognome,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final String indirizzoUnito =
          '${via.trim()} ${civico.trim()}, '
          '${cap.trim()} ${citta.trim()}, '
          '${provincia.trim().toUpperCase()}';

      Map<String, double>? coord = await GeocodingService.ottieniCoordinate(
        via: via,
        civico: civico,
        cap: cap,
        citta: citta,
        provincia: provincia,
      );

      if (coord == null) {
        state = state.copyWith(
          isSaving: false,
          errorMessage: 'Indirizzo non trovato. Verifica la via o la città.',
        );
        return false;
      }

      double lat = coord['latitudine'] ?? 0.0;
      double lng = coord['longitudine'] ?? 0.0;

      if (lat == 0.0 || lng == 0.0) {
        Map<String, double>? coordFallback =
            await GeocodingService.ottieniCoordinate(
              via: via,
              civico: civico,
              cap: cap,
              citta: citta,
              provincia: provincia,
            );
        lat = coordFallback?['latitudine'] ?? 0.0;
        lng = coordFallback?['longitudine'] ?? 0.0;
      }

      String? finalFotoUrl = state.fotoUrl;
      if (state.fotoBytesLocali != null && state.estensioneFotoLocale != null) {
        final fileName =
            '${utenteLoggato.id}_${DateTime.now().millisecondsSinceEpoch}.${state.estensioneFotoLocale}';
        finalFotoUrl = await _repository.uploadAvatarSocieta(
          fileName: fileName,
          bytes: state.fotoBytesLocali!,
        );
      }

      await _repository.updateDatiUtenteBase(utenteLoggato.id, {
        'nome': nome,
        'cognome': cognome,
        'telefono': state.telefonoCompleto,
        'indirizzo': indirizzoUnito,
      });

      await _repository.updateDatiSocieta(utenteLoggato.id, {
        'nome_proprietario': '${nome.trim()} ${cognome.trim()}'.trim(),

        // telefono = fisso
        'telefono': telefonoFisso.trim().isEmpty ? null : telefonoFisso.trim(),

        // cellulare = mobile
        'cellulare': state.telefonoCompleto.trim(),

        // Manteniamo ancora l'indirizzo completo.
        'indirizzo': indirizzoUnito,

        // Nuovi campi strutturati.
        'via': via.trim(),
        'civico': civico.trim(),
        'cap': cap.trim(),
        'comune': citta.trim(),
        'provincia': provincia.trim().toUpperCase(),

        'latitudine': lat,
        'longitudine': lng,
        'foto_url': finalFotoUrl,
      });

      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      debugPrint("Errore salvataggio: $e");
      state = state.copyWith(
        isSaving: false,
        errorMessage:
            'Si è verificato un errore durante il salvataggio dei dati.',
      );
      return false;
    }
  }

  Future<bool> cambiaPassword(String nuovaPassword) async {
    try {
      await _repository.updatePassword(nuovaPassword);
      return true;
    } catch (e) {
      debugPrint("Errore cambio password: $e");
      state = state.copyWith(
        errorMessage: 'Impossibile aggiornare la password.',
      );
      return false;
    }
  }
}

final profiloProvider = NotifierProvider<ProfiloNotifier, ProfiloState>(
  ProfiloNotifier.new,
);
