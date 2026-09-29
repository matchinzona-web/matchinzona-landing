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

        if (o['is_chiuso'] == false) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text('Modifica Orari'),
        backgroundColor: AppTheme.darkBg,
        iconTheme: const IconThemeData(color: AppTheme.neonOrange),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.neonOrange),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 650),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'Modifica gli orari standard del tuo centro. Puoi gestire turni unici o spezzati e copiare le impostazioni su tutti i giorni per velocizzare.',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 20),
                        itemCount: _orari.length,
                        itemBuilder: (context, index) {
                          final o = _orari[index];
                          final int giornoNum = o['giorno_settimana'] ?? 1;
                          final bool isChiuso = o['is_chiuso'] ?? false;
                          final bool hasSecondoTurno =
                              o['has_secondo_turno'] ?? false;
                          final tApertura1 = _convertiInTimeOfDay(
                            o['orario_apertura'],
                          );
                          final tChiusura1 = _convertiInTimeOfDay(
                            o['orario_chiusura'],
                          );
                          final tApertura2 = _convertiInTimeOfDay(
                            o['orario_apertura_2'],
                          );
                          final tChiusura2 = _convertiInTimeOfDay(
                            o['orario_chiusura_2'],
                          );

                          return Card(
                            color: AppTheme.cardBg,
                            margin: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                color: isChiuso
                                    ? Colors.redAccent.withValues(alpha: 0.5)
                                    : AppTheme.neonOrange.withValues(
                                        alpha: 0.4,
                                      ),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Switch(
                                            value: !isChiuso,
                                            activeThumbColor:
                                                AppTheme.neonOrange,
                                            inactiveThumbColor: Colors.grey,
                                            onChanged: (valore) => setState(
                                              () => _orari[index]['is_chiuso'] =
                                                  !valore,
                                            ),
                                          ),
                                          Text(
                                            _nomiGiorni[giornoNum],
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: isChiuso
                                                  ? Colors.grey
                                                  : Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (!isChiuso)
                                        TextButton.icon(
                                          onPressed: () =>
                                              _copiaOrarioATutti(index),
                                          icon: const Icon(
                                            Icons.copy_all,
                                            color: Colors.grey,
                                            size: 18,
                                          ),
                                          label: const Text(
                                            'Applica a tutti',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (!isChiuso) ...[
                                    const Divider(color: Colors.white10),
                                    const SizedBox(height: 5),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          hasSecondoTurno
                                              ? 'Turno 1:'
                                              : 'Orario Continuo:',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            TextButton(
                                              onPressed: () => _selezionaOra(
                                                index,
                                                true,
                                                false,
                                              ),
                                              child: Text(
                                                tApertura1.format(context),
                                                style: const TextStyle(
                                                  color: AppTheme.neonOrange,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const Text(
                                              '-',
                                              style: TextStyle(
                                                color: Colors.white30,
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () => _selezionaOra(
                                                index,
                                                false,
                                                false,
                                              ),
                                              child: Text(
                                                tChiusura1.format(context),
                                                style: const TextStyle(
                                                  color: AppTheme.neonOrange,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (hasSecondoTurno)
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Turno 2:',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              TextButton(
                                                onPressed: () => _selezionaOra(
                                                  index,
                                                  true,
                                                  true,
                                                ),
                                                child: Text(
                                                  tApertura2.format(context),
                                                  style: const TextStyle(
                                                    color: AppTheme.neonOrange,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const Text(
                                                '-',
                                                style: TextStyle(
                                                  color: Colors.white30,
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () => _selezionaOra(
                                                  index,
                                                  false,
                                                  true,
                                                ),
                                                child: Text(
                                                  tChiusura2.format(context),
                                                  style: const TextStyle(
                                                    color: AppTheme.neonOrange,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: const Size(50, 30),
                                        ),
                                        onPressed: () => setState(
                                          () =>
                                              _orari[index]['has_secondo_turno'] =
                                                  !hasSecondoTurno,
                                        ),
                                        icon: Icon(
                                          hasSecondoTurno
                                              ? Icons.remove_circle_outline
                                              : Icons.add_circle_outline,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                        label: Text(
                                          hasSecondoTurno
                                              ? 'Rimuovi pausa'
                                              : 'Aggiungi pausa (Spezzato)',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ] else ...[
                                    const SizedBox(height: 10),
                                    const Text(
                                      'CHIUSO TUTTO IL GIORNO',
                                      style: TextStyle(
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _salvaTutto,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.neonOrange,
                            foregroundColor: AppTheme.darkBg,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.black,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Salva Tutti gli Orari',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
