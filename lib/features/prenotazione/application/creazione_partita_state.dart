import 'package:app_campi/core/models/campo.dart';
import 'package:app_campi/core/services/partita_service.dart';
import 'package:app_campi/core/models/societa.dart';

class CreazionePartitaState {
  final bool isLoading;
  final List<Societa> societaTrovate;
  final List<Campo> campiTrovati;
  final Campo? campoSelezionato;
  final DateTime dataSelezionata;
  final List<String> orariDisponibili;
  final List<String> orariOccupati;
  final List<String> orariChiusi;
  final List<DateTime> giorniChiusi;
  final Map<String, int> partiteApertePerSlot;
  final Map<String, String> mieiMatchApertiPerSlot;
  final String? oraInizioSelezionata;
  final int ospitiExtra;
  final bool isPartitaPrivata;
  final String sportSelezionato;
  final String fasciaOraria;
  final Map<String, double> prezziPerSocieta;
  final MetodoPagamento metodoPagamentoScelto;
  final bool pagamentiOnlineDisponibili;

  CreazionePartitaState({
    this.isLoading = false,
    this.societaTrovate = const [],
    this.campiTrovati = const [],
    this.campoSelezionato,
    DateTime? dataSelezionata, // Rimosso 'required' e reso opzionale
    this.orariDisponibili = const [],
    this.orariOccupati = const [],
    this.orariChiusi = const [],
    this.giorniChiusi = const [],
    this.partiteApertePerSlot = const {},
    this.mieiMatchApertiPerSlot = const {},
    this.oraInizioSelezionata,
    this.ospitiExtra = 0,
    this.isPartitaPrivata = true,
    this.sportSelezionato = 'calcio_5',
    this.fasciaOraria = 'tutto',
    this.prezziPerSocieta = const {},
    this.metodoPagamentoScelto = MetodoPagamento.inSede,
    this.pagamentiOnlineDisponibili = false,
  }) : dataSelezionata = dataSelezionata ?? DateTime.now();

  CreazionePartitaState copyWith({
    bool? isLoading,
    List<Societa>? societaTrovate,
    List<Campo>? campiTrovati,
    Campo? campoSelezionato,
    DateTime? dataSelezionata,
    List<String>? orariDisponibili,
    List<String>? orariOccupati,
    List<String>? orariChiusi,
    List<DateTime>? giorniChiusi,
    Map<String, int>? partiteApertePerSlot,
    Map<String, String>? mieiMatchApertiPerSlot,
    String? oraInizioSelezionata,
    int? ospitiExtra,
    bool? isPartitaPrivata,
    String? sportSelezionato, // <-- PARAMETRO NELLA FIRMA
    String? fasciaOraria, // <-- PARAMETRO NELLA FIRMA
    bool clearCampo = false,
    bool clearOrario = false,
    Map<String, double>? prezziPerSocieta,
    MetodoPagamento? metodoPagamentoScelto,
    bool? pagamentiOnlineDisponibili,
  }) {
    return CreazionePartitaState(
      isLoading: isLoading ?? this.isLoading,
      societaTrovate: societaTrovate ?? this.societaTrovate,
      campiTrovati: campiTrovati ?? this.campiTrovati,
      campoSelezionato: clearCampo
          ? null
          : (campoSelezionato ?? this.campoSelezionato),
      dataSelezionata: dataSelezionata ?? this.dataSelezionata,
      orariDisponibili: orariDisponibili ?? this.orariDisponibili,
      orariOccupati: orariOccupati ?? this.orariOccupati,
      orariChiusi: orariChiusi ?? this.orariChiusi,
      giorniChiusi: giorniChiusi ?? this.giorniChiusi,
      partiteApertePerSlot: partiteApertePerSlot ?? this.partiteApertePerSlot,
      mieiMatchApertiPerSlot:
          mieiMatchApertiPerSlot ?? this.mieiMatchApertiPerSlot,
      oraInizioSelezionata: clearOrario
          ? null
          : (oraInizioSelezionata ?? this.oraInizioSelezionata),
      ospitiExtra: ospitiExtra ?? this.ospitiExtra,
      isPartitaPrivata: isPartitaPrivata ?? this.isPartitaPrivata,
      sportSelezionato:
          sportSelezionato ??
          this.sportSelezionato, // <-- VALORE REALE ASSEGNATO QUI
      fasciaOraria:
          fasciaOraria ?? this.fasciaOraria, // <-- VALORE REALE ASSEGNATO QUI
      prezziPerSocieta: prezziPerSocieta ?? this.prezziPerSocieta,
      metodoPagamentoScelto:
          metodoPagamentoScelto ?? this.metodoPagamentoScelto,
      pagamentiOnlineDisponibili:
          pagamentiOnlineDisponibili ?? this.pagamentiOnlineDisponibili,
    );
  }

  int get giocatoriTotali => 1 + ospitiExtra;
}
