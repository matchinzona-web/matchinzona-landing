import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_campi/core/theme/app_theme.dart';

class ModificaOrari extends StatefulWidget {
  final String idSocieta;

  const ModificaOrari({super.key, required this.idSocieta});

  @override
  State<ModificaOrari> createState() => _ModificaOrariState();
}

class _ModificaOrariState extends State<ModificaOrari> {
  List<Map<String, dynamic>> _orari = [];
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _nomiGiorni = [
    '',
    'Lunedì',
    'Martedì',
    'Mercoledì',
    'Giovedì',
    'Venerdì',
    'Sabato',
    'Domenica',
  ];

  @override
  void initState() {
    super.initState();
    _caricaOrari();
  }

  Future<void> _caricaOrari() async {
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client
          .from('orari_societa')
          .select()
          .eq('id_societa', widget.idSocieta)
          .order('giorno_settimana', ascending: true);

      setState(() {
        _orari = (data as List)
            .map(
              (o) => {
                'id': o['id'],
                'id_societa': o['id_societa'],
                'giorno_settimana': o['giorno_settimana'],
                'is_chiuso': o['is_chiuso'] ?? false,
                'orario_apertura': o['orario_apertura'] ?? '08:00:00',
                'orario_chiusura': o['orario_chiusura'] ?? '13:00:00',
                'has_secondo_turno': o['orario_apertura_2'] != null,
                'orario_apertura_2': o['orario_apertura_2'] ?? '16:00:00',
                'orario_chiusura_2': o['orario_chiusura_2'] ?? '21:00:00',
              },
            )
            .toList();
      });
    } catch (e) {
      debugPrint("Errore orari: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore caricamento orari'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  TimeOfDay _convertiInTimeOfDay(dynamic orario) {
    if (orario is TimeOfDay) return orario;
    if (orario is String) {
      final parti = orario.split(':');
      if (parti.length >= 2) {
        return TimeOfDay(
          hour: int.parse(parti[0]),
          minute: int.parse(parti[1]),
        );
      }
    }
    return const TimeOfDay(hour: 8, minute: 0);
  }

  Future<void> _selezionaOra(
    int index,
    bool isApertura,
    bool isSecondoTurno,
  ) async {
    final chiave = isSecondoTurno
        ? (isApertura ? 'orario_apertura_2' : 'orario_chiusura_2')
        : (isApertura ? 'orario_apertura' : 'orario_chiusura');

    final TimeOfDay orarioAttuale = _convertiInTimeOfDay(_orari[index][chiave]);

    final picked = await showTimePicker(
      context: context,
      initialTime: orarioAttuale,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.neonOrange,
            onSurface: Colors.white,
          ),
        ),
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        ),
      ),
    );

    if (picked != null) {
      final String nuovaOraStr =
          "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00";
      setState(() => _orari[index][chiave] = nuovaOraStr);
    }
  }

  bool _orarioValido(int index) {
    final o = _orari[index];
    if (o['is_chiuso'] == true) return true;

    final ap1 = _convertiInTimeOfDay(o['orario_apertura']);
    final ch1 = _convertiInTimeOfDay(o['orario_chiusura']);
    final int minAp1 = ap1.hour * 60 + ap1.minute;
    // mezzanotte = 24:00, non 00:00
    final int minCh1 = (ch1.hour == 0 && ch1.minute == 0)
        ? 24 * 60
        : ch1.hour * 60 + ch1.minute;

    if (minCh1 <= minAp1) return false;

    if (o['has_secondo_turno'] == true) {
      final ap2 = _convertiInTimeOfDay(o['orario_apertura_2']);
      final ch2 = _convertiInTimeOfDay(o['orario_chiusura_2']);
      final int minAp2 = ap2.hour * 60 + ap2.minute;
      final int minCh2 = (ch2.hour == 0 && ch2.minute == 0)
          ? 24 * 60
          : ch2.hour * 60 + ch2.minute;

      if (minAp2 <= minCh1) return false;
      if (minCh2 <= minAp2) return false;
    }

    return true;
  }

  void _copiaOrarioATutti(int sorgenteIndex) {
    final sorgente = _orari[sorgenteIndex];
    setState(() {
      for (int i = 0; i < _orari.length; i++) {
        if (i == sorgenteIndex) continue;
        _orari[i]['is_chiuso'] = sorgente['is_chiuso'];
        _orari[i]['orario_apertura'] = sorgente['orario_apertura'];
        _orari[i]['orario_chiusura'] = sorgente['orario_chiusura'];
        _orari[i]['has_secondo_turno'] = sorgente['has_secondo_turno'];
        _orari[i]['orario_apertura_2'] = sorgente['orario_apertura_2'];
        _orari[i]['orario_chiusura_2'] = sorgente['orario_chiusura_2'];
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Orari di ${_nomiGiorni[sorgente['giorno_settimana']]} copiati su tutta la settimana! 📋',
        ),
        backgroundColor: AppTheme.neonOrange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _salvaTutto() async {
    setState(() => _isSaving = true);

    for (int i = 0; i < _orari.length; i++) {
      if (!_orarioValido(i)) {
        setState(() => _isSaving = false);
        final int giornoNum = _orari[i]['giorno_settimana'] as int;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Orari non validi per ${_nomiGiorni[giornoNum]}: verifica che l\'apertura sia prima della chiusura.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }

    try {
      final supabase = Supabase.instance.client;

      for (var o in _orari) {
        final hasSecondo = o['has_secondo_turno'] == true;

        await supabase
            .from('orari_societa')
            .update({
              'is_chiuso': o['is_chiuso'],
              'orario_apertura': o['orario_apertura'],
              'orario_chiusura': o['orario_chiusura'],
              'orario_apertura_2': hasSecondo ? o['orario_apertura_2'] : null,
              'orario_chiusura_2': hasSecondo ? o['orario_chiusura_2'] : null,
            })
            .eq('id', o['id']);

        await supabase.rpc(
          'annulla_partite_fuori_orario',
          params: {
            'p_id_societa': widget.idSocieta,
            'p_giorno_settimana': o['giorno_settimana'],
            'p_orario_apertura': o['orario_apertura'],
            'p_orario_chiusura': hasSecondo
                ? o['orario_chiusura_2']
                : o['orario_chiusura'],
          },
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Orari aggiornati e partite verificate con successo! 🗓️',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Errore durante il salvataggio: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore durante il salvataggio'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _webPulsanteOra(
    int index,
    bool apertura,
    bool secondoTurno,
    TimeOfDay ora,
  ) {
    return OutlinedButton.icon(
      onPressed: () => _selezionaOra(index, apertura, secondoTurno),
      icon: const Icon(Icons.schedule_rounded, size: 16),
      label: Text(
        '${ora.hour.toString().padLeft(2, '0')}:'
        '${ora.minute.toString().padLeft(2, '0')}',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF192532),
        side: const BorderSide(color: Colors.white12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _webRigaGiorno(int index) {
    final o = _orari[index];

    final int giornoNum = o['giorno_settimana'] ?? 1;
    final bool isChiuso = o['is_chiuso'] ?? false;
    final bool hasSecondoTurno = o['has_secondo_turno'] ?? false;

    final tApertura1 = _convertiInTimeOfDay(o['orario_apertura']);
    final tChiusura1 = _convertiInTimeOfDay(o['orario_chiusura']);
    final tApertura2 = _convertiInTimeOfDay(o['orario_apertura_2']);
    final tChiusura2 = _convertiInTimeOfDay(o['orario_chiusura_2']);

    Widget intervallo(bool secondo, TimeOfDay apertura, TimeOfDay chiusura) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: _webPulsanteOra(index, true, secondo, apertura)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text('—', style: TextStyle(color: Colors.white38)),
          ),
          Flexible(child: _webPulsanteOra(index, false, secondo, chiusura)),
        ],
      );
    }

    final stato = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Switch(
          value: !isChiuso,
          activeThumbColor: AppTheme.neonOrange,
          onChanged: (valore) =>
              setState(() => _orari[index]['is_chiuso'] = !valore),
        ),
        Text(
          isChiuso ? 'Chiuso' : 'Aperto',
          style: TextStyle(
            color: isChiuso ? Colors.redAccent : Colors.greenAccent,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );

    final orari = isChiuso
        ? const Text(
            'Chiuso tutto il giorno',
            style: TextStyle(color: Colors.white38, fontSize: 14),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasSecondoTurno)
                const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text(
                    'PRIMO TURNO',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),

              intervallo(false, tApertura1, tChiusura1),

              if (hasSecondoTurno) ...[
                const SizedBox(height: 15),
                const Text(
                  'SECONDO TURNO',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                intervallo(true, tApertura2, tChiusura2),
              ],

              const SizedBox(height: 10),

              TextButton.icon(
                onPressed: () => setState(
                  () => _orari[index]['has_secondo_turno'] = !hasSecondoTurno,
                ),
                icon: Icon(
                  hasSecondoTurno
                      ? Icons.remove_circle_outline
                      : Icons.add_circle_outline,
                  size: 17,
                ),
                label: Text(
                  hasSecondoTurno ? 'Rimuovi pausa' : 'Aggiungi pausa',
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.neonOrange,
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          );

    final copia = !isChiuso
        ? Tooltip(
            message: 'Applica questi orari a tutta la settimana',
            child: IconButton(
              onPressed: () => _copiaOrarioATutti(index),
              icon: const Icon(Icons.copy_all_outlined, color: Colors.white54),
            ),
          )
        : const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final compatto = constraints.maxWidth < 720;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: EdgeInsets.all(compatto ? 14 : 20),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isChiuso
                  ? Colors.redAccent.withOpacity(0.22)
                  : Colors.white.withOpacity(0.08),
            ),
          ),
          child: compatto
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _nomiGiorni[giornoNum],
                            style: TextStyle(
                              color: isChiuso ? Colors.white54 : Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (!isChiuso) copia,
                      ],
                    ),
                    const SizedBox(height: 4),
                    stato,
                    if (!isChiuso) ...[
                      const Divider(color: Colors.white12, height: 24),
                      orari,
                    ] else ...[
                      const SizedBox(height: 8),
                      orari,
                    ],
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 145,
                      child: Text(
                        _nomiGiorni[giornoNum],
                        style: TextStyle(
                          color: isChiuso ? Colors.white54 : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    SizedBox(width: 135, child: stato),
                    Expanded(child: orari),
                    SizedBox(width: 48, child: copia),
                  ],
                ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1118),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121B26),
        toolbarHeight: 76,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.neonOrange),
        title: const Text(
          'Orari del centro',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(
              right: MediaQuery.sizeOf(context).width < 600 ? 12 : 30,
            ),
            child: Center(
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _salvaTutto,
                icon: _isSaving
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(Icons.save_outlined, size: 19),
                label: Text(
                  _isSaving
                      ? 'Salvataggio...'
                      : MediaQuery.sizeOf(context).width < 600
                      ? 'Salva'
                      : 'Salva modifiche',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonOrange,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.sizeOf(context).width < 600
                        ? 12
                        : 22,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.neonOrange),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.all(constraints.maxWidth < 600 ? 12 : 30),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1250),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Orari di apertura',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 27,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Configura gli orari settimanali del tuo centro sportivo. '
                            'Puoi impostare un turno unico, aggiungere una pausa '
                            'oppure chiudere un giorno.',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 30),

                          if (constraints.maxWidth >= 780)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 17,
                              ),
                              decoration: const BoxDecoration(
                                color: Color(0xFF121B26),
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(14),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  SizedBox(width: 145, child: Text('GIORNO')),
                                  SizedBox(width: 135, child: Text('STATO')),
                                  Expanded(child: Text('ORARI DI APERTURA')),
                                  SizedBox(width: 48, child: Text('COPIA')),
                                ],
                              ),
                            ),

                          const SizedBox(height: 12),

                          for (int i = 0; i < _orari.length; i++)
                            _webRigaGiorno(i),

                          const SizedBox(height: 20),

                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppTheme.neonOrange.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.neonOrange.withOpacity(0.16),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: AppTheme.neonOrange,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Le modifiche saranno applicate solo dopo '
                                    'aver premuto "Salva modifiche". '
                                    'Le prenotazioni esistenti verranno '
                                    'verificate automaticamente.',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
