import 'package:app_campi/core/models/orario_societa.dart';

class SlotUtils {
  static int orarioInMinuti(String orario) {
    final parti = orario.trim().split(':');

    if (parti.length < 2) {
      throw FormatException('Formato orario non valido: $orario');
    }

    return (int.parse(parti[0]) * 60) + int.parse(parti[1]);
  }

  static String minutiInOrario(int minuti) {
    final normalizzati = minuti % (24 * 60);

    final ore = normalizzati ~/ 60;
    final minutiRestanti = normalizzati % 60;

    return '${ore.toString().padLeft(2, '0')}:'
        '${minutiRestanti.toString().padLeft(2, '0')}';
  }

  static String calcolaOrarioFine(
    String orarioInizio, {
    int durataMinuti = 60,
  }) {
    final minuti = orarioInMinuti(orarioInizio) + durataMinuti;

    return '${minutiInOrario(minuti)}:00';
  }

  static List<String> generaSlotDoppioTurno(
    OrarioSocieta orari, {
    int durataMinuti = 60,
  }) {
    final slots = <String>[];

    void aggiungiTurno(String? apertura, String? chiusura) {
      if (apertura == null || chiusura == null) {
        return;
      }

      int corrente = orarioInMinuti(apertura);
      final limite = orarioInMinuti(chiusura);

      while (corrente + durataMinuti <= limite) {
        final slot = minutiInOrario(corrente);

        if (!slots.contains(slot)) {
          slots.add(slot);
        }

        corrente += durataMinuti;
      }
    }

    aggiungiTurno(orari.orarioApertura, orari.orarioChiusura);

    aggiungiTurno(orari.orarioApertura2, orari.orarioChiusura2);

    slots.sort((a, b) => orarioInMinuti(a).compareTo(orarioInMinuti(b)));

    return slots;
  }
}
