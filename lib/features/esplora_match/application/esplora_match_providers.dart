import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/filtro_distanza.dart';

class FiltroDistanzaNotifier extends Notifier<FiltroDistanza> {
  @override
  FiltroDistanza build() {
    return FiltroDistanza.vicini;
  }

  void impostaFiltro(FiltroDistanza nuovoFiltro) {
    state = nuovoFiltro;
  }
}

final filtroDistanzaProvider =
    NotifierProvider<FiltroDistanzaNotifier, FiltroDistanza>(() {
      return FiltroDistanzaNotifier();
    });

class FiltroSportNotifier extends Notifier<String> {
  @override
  String build() => 'calcio';

  void impostaSport(String nuovoSport) {
    state = nuovoSport;
  }
}

final filtroSportProvider = NotifierProvider<FiltroSportNotifier, String>(() {
  return FiltroSportNotifier();
});
