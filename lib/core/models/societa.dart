class Societa {
  final String id;
  final String pIva;
  final String nomeSocieta;

  // Indirizzo storico/completo, lo manteniamo per compatibilità.
  final String indirizzo;

  // Nuovi dati strutturati.
  final String? viaStrutturata;
  final String? civico;
  final String? cap;
  final String? comune;
  final String? provincia;

  // Dati fiscali.
  final String? codiceFiscale;
  final String? codiceDestinatario;
  final String? pec;

  final String? nomeProprietario;
  final String telefono;
  final String? cellulare;
  final String email;
  final DateTime? createdAt;
  final String? idUtente;
  final double? latitudine;
  final double? longitudine;
  final String? fotoUrl;
  final int limiteCampi;
  final DateTime? provaInizio;
  final DateTime? provaFine;
  final bool stripeChargesEnabled;
  final bool stripePayoutsEnabled;

  Societa({
    required this.id,
    required this.pIva,
    required this.nomeSocieta,
    required this.indirizzo,
    this.viaStrutturata,
    this.civico,
    this.cap,
    this.comune,
    this.provincia,
    this.codiceFiscale,
    this.codiceDestinatario,
    this.pec,
    this.nomeProprietario,
    required this.telefono,
    this.cellulare,
    required this.email,
    this.createdAt,
    this.idUtente,
    this.latitudine,
    this.longitudine,
    this.fotoUrl,
    required this.limiteCampi,
    this.provaInizio,
    this.provaFine,
    this.stripeChargesEnabled = false,
    this.stripePayoutsEnabled = false,
  });

  factory Societa.fromJson(Map<String, dynamic> json) {
    return Societa(
      id: json['id'] as String,
      pIva: (json['p_iva'] ?? '').toString(),
      nomeSocieta: (json['nome_societa'] ?? '').toString(),

      indirizzo: (json['indirizzo'] ?? '').toString(),

      viaStrutturata: json['via']?.toString(),
      civico: json['civico']?.toString(),
      cap: json['cap']?.toString(),
      comune: json['comune']?.toString(),
      provincia: json['provincia']?.toString(),

      codiceFiscale: json['codice_fiscale']?.toString(),
      codiceDestinatario: json['codice_destinatario']?.toString(),
      pec: json['pec']?.toString(),

      nomeProprietario: json['nome_proprietario'] as String?,
      telefono: (json['telefono'] ?? '').toString(),
      cellulare: json['cellulare'] as String?,
      email: (json['email'] ?? '').toString(),

      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : null,

      idUtente: json['id_utente'] as String?,

      latitudine: json['latitudine'] != null
          ? (json['latitudine'] as num).toDouble()
          : null,

      longitudine: json['longitudine'] != null
          ? (json['longitudine'] as num).toDouble()
          : null,

      fotoUrl: json['foto_url'] as String?,

      limiteCampi: json['limite_campi'] as int? ?? 1,
      provaInizio: json['prova_inizio'] != null
          ? DateTime.parse(json['prova_inizio'].toString())
          : null,

      provaFine: json['prova_fine'] != null
          ? DateTime.parse(json['prova_fine'].toString())
          : null,

      stripeChargesEnabled: json['stripe_charges_enabled'] == true,

      stripePayoutsEnabled: json['stripe_payouts_enabled'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'p_iva': pIva,
      'nome_societa': nomeSocieta,

      // Manteniamo ancora l'indirizzo completo.
      'indirizzo': indirizzo,

      // Nuovi campi strutturati.
      'via': viaStrutturata,
      'civico': civico,
      'cap': cap,
      'comune': comune,
      'provincia': provincia,

      // Dati fiscali.
      'codice_fiscale': codiceFiscale,
      'codice_destinatario': codiceDestinatario,
      'pec': pec,

      'nome_proprietario': nomeProprietario,
      'telefono': telefono,
      'cellulare': cellulare,
      'email': email,
      'id_utente': idUtente,
      'latitudine': latitudine,
      'longitudine': longitudine,
      'foto_url': fotoUrl,
      'limite_campi': limiteCampi,
      'prova_inizio': provaInizio?.toIso8601String(),
      'prova_fine': provaFine?.toIso8601String(),
      'stripe_charges_enabled': stripeChargesEnabled,
      'stripe_payouts_enabled': stripePayoutsEnabled,
    };
  }

  /// Comune + provincia.
  /// Usa i nuovi campi se presenti,
  /// altrimenti ripiega sul vecchio indirizzo.
  String get citta {
    final comunePulito = comune?.trim() ?? '';
    final provinciaPulita = provincia?.trim() ?? '';

    if (comunePulito.isNotEmpty) {
      if (provinciaPulita.isNotEmpty) {
        return '$comunePulito, $provinciaPulita';
      }

      return comunePulito;
    }

    if (indirizzo.isEmpty) {
      return 'Città non specificata';
    }

    final parti = indirizzo.split(',');

    if (parti.length >= 2) {
      final comuneLegacy = parti[parti.length - 2].trim();
      final provinciaLegacy = parti[parti.length - 1].trim();

      return '$comuneLegacy, $provinciaLegacy';
    }

    return indirizzo;
  }

  /// Via + civico.
  /// Manteniamo questo getter perché potrebbe
  /// essere già utilizzato in altre schermate.
  String get via {
    final viaPulita = viaStrutturata?.trim() ?? '';
    final civicoPulito = civico?.trim() ?? '';

    if (viaPulita.isNotEmpty) {
      if (civicoPulito.isNotEmpty) {
        return '$viaPulita $civicoPulito';
      }

      return viaPulita;
    }

    if (indirizzo.isEmpty) {
      return 'Via non specificata';
    }

    final parti = indirizzo.split(',');

    if (parti.length > 1) {
      return parti.first.trim();
    }

    return indirizzo;
  }

  /// Stringa completa da usare per visualizzazione
  /// e soprattutto per il geocoding.
  String get indirizzoCompleto {
    final viaPulita = viaStrutturata?.trim() ?? '';
    final civicoPulito = civico?.trim() ?? '';
    final capPulito = cap?.trim() ?? '';
    final comunePulito = comune?.trim() ?? '';
    final provinciaPulita = provincia?.trim() ?? '';

    final haDatiStrutturati = viaPulita.isNotEmpty || comunePulito.isNotEmpty;

    if (!haDatiStrutturati) {
      return indirizzo;
    }

    final strada = [
      viaPulita,
      civicoPulito,
    ].where((e) => e.isNotEmpty).join(' ');

    final localita = [
      capPulito,
      comunePulito,
    ].where((e) => e.isNotEmpty).join(' ');

    return [
      strada,
      localita,
      provinciaPulita,
    ].where((e) => e.isNotEmpty).join(', ');
  }
}
