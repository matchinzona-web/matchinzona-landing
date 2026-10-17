import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_campi/core/models/utente.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final SupabaseClient _supabase;

  AuthService({SupabaseClient? supabaseClient})
    : _supabase = supabaseClient ?? Supabase.instance.client;

  Future<String> registraProprietario({
    required String email,
    required String password,
    required String nomeProprietario,

    required String pIva,
    required String codiceFiscale,

    required String nomeSocieta,

    required String indirizzo,
    required String via,
    required String civico,
    required String cap,
    required String comune,
    required String provincia,

    String? codiceDestinatario,
    String? pec,

    required String telefonoFisso,
    required String cellulare,

    double? latitudine,
    double? longitudine,
  }) async {
    try {
      final emailPulita = email.trim().toLowerCase();
      final nomeProprietarioPulito = nomeProprietario.trim();

      final AuthResponse res = await _supabase.auth.signUp(
        email: emailPulita,
        password: password,
      );

      final User? utenteCreato = res.user;

      if (utenteCreato == null) {
        throw Exception("Errore: Impossibile creare l'account Auth.");
      }

      // -----------------------------
      // PROFILO GESTORE
      // Tipo 1 = Gestore
      // -----------------------------

      final partiNome = nomeProprietarioPulito
          .split(' ')
          .where((parte) => parte.trim().isNotEmpty)
          .toList();

      final nome = partiNome.isNotEmpty
          ? partiNome.first
          : nomeProprietarioPulito;

      final cognome = partiNome.length > 1
          ? partiNome.sublist(1).join(' ')
          : '';

      await _supabase.from('utenti').insert({
        'id': utenteCreato.id,
        'nome': nome,
        'cognome': cognome,
        'email': emailPulita,
        'telefono': cellulare.trim(),
        'tipo': 1,
      });

      // -----------------------------
      // DATI SOCIETÀ
      // -----------------------------

      final codiceDestinatarioPulito = codiceDestinatario?.trim().toUpperCase();

      final pecPulita = pec?.trim().toLowerCase();

      final telefonoFissoPulito = telefonoFisso.trim();

      final societaInserita = await _supabase
          .from('societa')
          .insert({
            'id_utente': utenteCreato.id,

            'p_iva': pIva.trim(),
            'codice_fiscale': codiceFiscale.trim().toUpperCase(),

            'nome_societa': nomeSocieta.trim(),

            // Manteniamo ancora anche
            // l'indirizzo completo.
            'indirizzo': indirizzo.trim(),

            // Nuovo indirizzo strutturato.
            'via': via.trim(),
            'civico': civico.trim(),
            'cap': cap.trim(),
            'comune': comune.trim(),
            'provincia': provincia.trim().toUpperCase(),

            // Dati fatturazione.
            'codice_destinatario':
                codiceDestinatarioPulito == null ||
                    codiceDestinatarioPulito.isEmpty
                ? null
                : codiceDestinatarioPulito,

            'pec': pecPulita == null || pecPulita.isEmpty ? null : pecPulita,

            'nome_proprietario': nomeProprietarioPulito,

            // CORREZIONE:
            // telefono = fisso
            // cellulare = mobile
            'telefono': telefonoFissoPulito.isEmpty
                ? null
                : telefonoFissoPulito,

            'cellulare': cellulare.trim(),

            'email': emailPulita,

            'latitudine': latitudine,
            'longitudine': longitudine,

            'piano_attuale': 'NESSUNO',

            'limite_campi': 0,

            'status_abbonamento': 'pending',
            'prova_inizio': null,
            'prova_fine': null,

            'stripe_customer_id': null,
          })
          .select('id')
          .single();

      return societaInserita['id'] as String;
    } on AuthException catch (e) {
      throw Exception('Errore di Autenticazione: ${e.message}');
    } catch (e) {
      throw Exception('Errore di sistema durante la registrazione');
    }
  }

  // REGISTRAZIONE GIOCATORE
  Future<void> registraGiocatore({
    required String email,
    required String password,
    required String nome,
    required String cognome,
    DateTime? dataNascita,
    String? telefono,
    String? indirizzo,
  }) async {
    try {
      final AuthResponse res = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      final User? supabaseUser = res.user;
      if (supabaseUser == null) {
        throw Exception("Errore critico: Impossibile generare l'utente Auth.");
      }

      // 2. CREAZIONE PROFILO UTENTE Giocatore
      final nuovoUtente = Utente(
        id: supabaseUser.id,
        nome: nome,
        cognome: cognome,
        email: email,
        dataNascita: dataNascita,
        telefono: telefono,
        indirizzo: indirizzo,
        createdAt: DateTime.now(),
      );

      await _supabase.from('utenti').insert(nuovoUtente.toJson());
    } on AuthException catch (e) {
      throw Exception('Errore di Autenticazione: ${e.message}');
    } catch (e) {
      throw Exception('Errore durante il salvataggio dei dati: $e');
    }
  }

  Future<void> completaProfiloSocial({
    required String nome,
    required String cognome,
    required DateTime dataNascita,
    required String telefono,
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Utente non autenticato.');
    }

    final telefonoPulito = telefono.trim();

    if (telefonoPulito.isEmpty) {
      throw Exception('Il numero di cellulare è obbligatorio.');
    }

    final esistente = await _supabase
        .from('utenti')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();

    final datiProfilo = {
      'nome': nome.trim(),
      'cognome': cognome.trim(),
      'email': user.email ?? '',
      'data_nascita':
          '${dataNascita.year}-'
          '${dataNascita.month.toString().padLeft(2, '0')}-'
          '${dataNascita.day.toString().padLeft(2, '0')}',
      'telefono': telefonoPulito,
      'tipo': 0,
    };

    if (esistente != null) {
      await _supabase.from('utenti').update(datiProfilo).eq('id', user.id);
    } else {
      await _supabase.from('utenti').insert({'id': user.id, ...datiProfilo});
    }
  }

  Future<void> accediConGoogle() async {
    try {
      final redirectUrl = kIsWeb
          ? '${Uri.base.origin}/'
          : 'myapp://login-callback';

      final avviato = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
        queryParams: {'prompt': 'select_account'},
        authScreenLaunchMode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      );

      if (!avviato) {
        throw Exception('Impossibile avviare l’accesso con Google.');
      }
    } on AuthException catch (e) {
      throw Exception('Errore accesso Google: ${e.message}');
    } catch (e) {
      throw Exception('Impossibile accedere con Google: $e');
    }
  }

  Future<Map<String, dynamic>?> recuperaProfiloUtenteCorrente() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      return null;
    }

    final response = await _supabase
        .from('utenti')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    return response;
  }

  Map<String, dynamic> datiSocialUtenteCorrente() {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      return {};
    }

    final metadata = user.userMetadata ?? {};

    String nome = '';
    String cognome = '';

    final fullName = (metadata['full_name'] ?? metadata['name'] ?? '')
        .toString()
        .trim();

    if (fullName.isNotEmpty) {
      final parti = fullName
          .split(' ')
          .where((e) => e.trim().isNotEmpty)
          .toList();

      if (parti.isNotEmpty) {
        nome = parti.first;

        if (parti.length > 1) {
          cognome = parti.sublist(1).join(' ');
        }
      }
    }

    nome = (metadata['given_name'] ?? nome).toString().trim();

    cognome = (metadata['family_name'] ?? cognome).toString().trim();

    return {
      'id': user.id,
      'email': user.email ?? '',
      'nome': nome,
      'cognome': cognome,
    };
  }
}
