import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_campi/core/theme/app_theme.dart';

class ChiusureStraordinarie extends StatefulWidget {
  final String idSocieta;

  const ChiusureStraordinarie({super.key, required this.idSocieta});

  @override
  State<ChiusureStraordinarie> createState() => _ChiusureStraordinarieState();
}

class _ChiusureStraordinarieState extends State<ChiusureStraordinarie> {
  List<Map<String, dynamic>> _chiusure = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _eliminaChiusureVecchie().then((_) => _scaricaChiusure());
  }

  Future<void> _scaricaChiusure() async {
    setState(() => _isLoading = true);
    try {
      final String oggiStr = _formattaDataDb(DateTime.now());

      final data = await Supabase.instance.client
          .from('chiusure_straordinarie')
          .select()
          .eq('id_societa', widget.idSocieta)
          .gte('data_fine', oggiStr)
          .order('data_inizio', ascending: true);

      if (mounted) {
        setState(() {
          _chiusure = data;
        });
      }
    } catch (e) {
      debugPrint("Errore: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _eliminaChiusura(String idChiusura) async {
    try {
      await Supabase.instance.client
          .from('chiusure_straordinarie')
          .delete()
          .eq('id', idChiusura);
      _scaricaChiusure();
    } catch (e) {
      debugPrint("Errore eliminazione: $e");
    }
  }

  String _formattaDataDisplay(DateTime d) {
    return "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";
  }

  String _formattaDataDb(DateTime d) {
    return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
  }

  void _mostraDialogAggiunta() {
    DateTime dataInizio = DateTime.now();
    DateTime dataFine = DateTime.now();
    bool interoGiorno = true;
    TimeOfDay oraInizio = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay oraFine = const TimeOfDay(hour: 20, minute: 0);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppTheme.cardBg,
              contentPadding: const EdgeInsets.all(20),
              title: const Text(
                'Nuova Chiusura',
                style: TextStyle(
                  color: AppTheme.neonOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: dataInizio,
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setStateDialog(() {
                                  dataInizio = picked;
                                  if (dataFine.isBefore(dataInizio)) {
                                    dataFine = dataInizio;
                                  }
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Dal giorno',
                                labelStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                _formattaDataDisplay(dataInizio),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: dataFine,
                                firstDate: dataInizio,
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setStateDialog(() => dataFine = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Al giorno',
                                labelStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                _formattaDataDisplay(dataFine),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade800),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: SwitchListTile(
                        title: const Text(
                          'Tutto il giorno',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        activeThumbColor: AppTheme.neonOrange,
                        value: interoGiorno,
                        onChanged: (val) =>
                            setStateDialog(() => interoGiorno = val),
                      ),
                    ),
                    if (!interoGiorno) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: oraInizio,
                                );
                                if (picked != null) {
                                  setStateDialog(() => oraInizio = picked);
                                }
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Dalle ore',
                                  labelStyle: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  oraInizio.format(context),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: oraFine,
                                );
                                if (picked != null) {
                                  setStateDialog(() => oraFine = picked);
                                }
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Alle ore',
                                  labelStyle: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  oraFine.format(context),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Annulla',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonOrange,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () async {
                    final String dataInizioStr = _formattaDataDb(dataInizio);
                    final String dataFineStr = _formattaDataDb(dataFine);

                    final String inizioStrCheck = interoGiorno
                        ? "00:00"
                        : "${oraInizio.hour.toString().padLeft(2, '0')}:${oraInizio.minute.toString().padLeft(2, '0')}";

                    final String fineStrCheck = interoGiorno
                        ? "23:59"
                        : "${oraFine.hour.toString().padLeft(2, '0')}:${oraFine.minute.toString().padLeft(2, '0')}";

                    int toMinuti(String valore) {
                      final parti = valore.split(':');
                      return int.parse(parti[0]) * 60 + int.parse(parti[1]);
                    }

                    if (!interoGiorno &&
                        toMinuti(fineStrCheck) <= toMinuti(inizioStrCheck)) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'L’orario di fine deve essere successivo all’orario di inizio.',
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }

                      return;
                    }

                    final sovrapposta = await _esisteSovrapposizione(
                      dataInizioStr,
                      dataFineStr,
                      inizioStrCheck,
                      fineStrCheck,
                    );

                    if (sovrapposta) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Esiste già una chiusura che si sovrappone a questo periodo.',
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                      return;
                    }

                    final valido = await _orarioValido(
                      dataInizio,
                      dataFine,
                      inizioStrCheck,
                      fineStrCheck,
                    );

                    if (!valido) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'La società è già chiusa in questo orario.',
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                      return;
                    }

                    try {
                      final String inizioStr = interoGiorno
                          ? "00:00:00"
                          : "${oraInizio.hour.toString().padLeft(2, '0')}:${oraInizio.minute.toString().padLeft(2, '0')}:00";
                      final String fineStr = interoGiorno
                          ? "23:59:59"
                          : "${oraFine.hour.toString().padLeft(2, '0')}:${oraFine.minute.toString().padLeft(2, '0')}:00";

                      // 1. Inserimento chiusura
                      try {
                        final String inizioStr = interoGiorno
                            ? "00:00:00"
                            : "${oraInizio.hour.toString().padLeft(2, '0')}:${oraInizio.minute.toString().padLeft(2, '0')}:00";

                        final String fineStr = interoGiorno
                            ? "23:59:59"
                            : "${oraFine.hour.toString().padLeft(2, '0')}:${oraFine.minute.toString().padLeft(2, '0')}:00";

                        // 1. Salva la chiusura e recupera l'id
                        final chiusuraCreata = await Supabase.instance.client
                            .from('chiusure_straordinarie')
                            .insert({
                              'id_societa': widget.idSocieta,
                              'data_inizio': dataInizioStr,
                              'data_fine': dataFineStr,
                              'orario_inizio': inizioStr,
                              'orario_fine': fineStr,
                            })
                            .select('id')
                            .single();

                        try {
                          // 2. Annulla le partite coinvolte
                          await Supabase.instance.client.rpc(
                            'annulla_partite_chiusura',
                            params: {
                              'p_id_societa': widget.idSocieta,
                              'p_data_inizio': dataInizioStr,
                              'p_data_fine': dataFineStr,
                              'p_ora_inizio': inizioStr,
                              'p_ora_fine': fineStr,
                            },
                          );
                        } catch (e) {
                          // Se l'annullamento fallisce, togli anche la chiusura appena creata
                          await Supabase.instance.client
                              .from('chiusure_straordinarie')
                              .delete()
                              .eq('id', chiusuraCreata['id']);

                          rethrow;
                        }

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Chiusura salvata con successo!'),
                              backgroundColor: Colors.green,
                            ),
                          );

                          _scaricaChiusure();
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        debugPrint(
                          "Errore salvataggio chiusura straordinaria: $e",
                        );

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Impossibile salvare la chiusura straordinaria. Riprova tra poco.',
                              ),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      }

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Chiusura salvata con successo!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        _scaricaChiusure();
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      debugPrint("Errore salvataggio chiusura straordinaria");

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Impossibile salvare la chiusura straordinaria. Riprova tra poco.',
                            ),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text(
                    'Salva',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formattaDallaStringaDb(String dataDb) {
    try {
      final parti = dataDb.split('-');
      return "${parti[2]}/${parti[1]}/${parti[0]}";
    } catch (e) {
      return dataDb;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chiusure Straordinarie'),
        iconTheme: const IconThemeData(color: AppTheme.neonOrange),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.neonOrange),
            )
          : _chiusure.isEmpty
          ? const Center(
              child: Text(
                'Nessuna chiusura impostata.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _chiusure.length,
              itemBuilder: (context, index) {
                final c = _chiusure[index];
                final dataInizio = _formattaDallaStringaDb(
                  c['data_inizio'].toString(),
                );
                final dataFine = _formattaDallaStringaDb(
                  c['data_fine'].toString(),
                );
                final orarioInizio = c['orario_inizio'].toString().substring(
                  0,
                  5,
                );
                final orarioFine = c['orario_fine'].toString().substring(0, 5);
                final bool isSingoloGiorno = dataInizio == dataFine;
                final bool isInteroGiorno =
                    orarioInizio == '00:00' &&
                    (orarioFine == '23:59' || orarioFine == '24:00');
                final titolo = isSingoloGiorno
                    ? 'Chiuso il $dataInizio'
                    : 'Chiuso dal $dataInizio al $dataFine';
                final sottotitolo = isInteroGiorno
                    ? 'Tutto il giorno'
                    : 'Dalle $orarioInizio alle $orarioFine';

                return Card(
                  color: AppTheme.cardBg,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Colors.redAccent, width: 1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.block, color: Colors.redAccent),
                    title: Text(
                      titolo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      sottotitolo,
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.grey),
                      onPressed: () => _eliminaChiusura(c['id']),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostraDialogAggiunta,
        backgroundColor: AppTheme.neonOrange,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text(
          'Aggiungi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _eliminaChiusureVecchie() async {
    try {
      final String limiteStr = _formattaDataDb(
        DateTime.now().subtract(const Duration(days: 30)),
      );
      await Supabase.instance.client
          .from('chiusure_straordinarie')
          .delete()
          .eq('id_societa', widget.idSocieta)
          .lt('data_fine', limiteStr);
    } catch (e) {
      debugPrint("Errore pulizia chiusure vecchie: $e");
    }
  }

  Future<bool> _esisteSovrapposizione(
    String dataInizioStr,
    String dataFineStr,
    String oraInizioStr,
    String oraFineStr,
  ) async {
    try {
      final result = await Supabase.instance.client
          .from('chiusure_straordinarie')
          .select('id, data_inizio, data_fine, orario_inizio, orario_fine')
          .eq('id_societa', widget.idSocieta)
          // Prima filtriamo le chiusure che si sovrappongono come date
          .lte('data_inizio', dataFineStr)
          .gte('data_fine', dataInizioStr);

      int strToMinuti(String valore) {
        final parti = valore.substring(0, 5).split(':');

        return int.parse(parti[0]) * 60 + int.parse(parti[1]);
      }

      final nuovoInizio = strToMinuti(oraInizioStr);
      final nuovaFine = strToMinuti(oraFineStr);

      for (final chiusura in result) {
        final vecchioInizio = chiusura['orario_inizio']?.toString() ?? '00:00';

        final vecchiaFine = chiusura['orario_fine']?.toString() ?? '23:59';

        final vecchioInizioMin = strToMinuti(vecchioInizio);
        final vecchiaFineMin = strToMinuti(vecchiaFine);

        // Sovrapposizione reale degli orari
        if (nuovoInizio < vecchiaFineMin && nuovaFine > vecchioInizioMin) {
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint("Errore controllo sovrapposizione: $e");

      // In caso di errore meglio impedire il salvataggio,
      // invece di rischiare doppie chiusure.
      return true;
    }
  }

  Future<bool> _orarioValido(
    DateTime dataInizio,
    DateTime dataFine,
    String inizioStr,
    String fineStr,
  ) async {
    try {
      final orari = await Supabase.instance.client
          .from('orari_societa')
          .select()
          .eq('id_societa', widget.idSocieta);

      int strToMinuti(String s) {
        final p = s.split(':');
        return int.parse(p[0]) * 60 + int.parse(p[1]);
      }

      final int minInizio = strToMinuti(inizioStr);
      final int minFine = strToMinuti(fineStr);

      DateTime giorno = dataInizio;
      while (!giorno.isAfter(dataFine)) {
        final int giornoSettimana = giorno.weekday;

        final orarioGiorno = (orari as List).firstWhere(
          (o) => o['giorno_settimana'] == giornoSettimana,
          orElse: () => <String, dynamic>{},
        );

        if (orarioGiorno.isNotEmpty && orarioGiorno['is_chiuso'] != true) {
          final int apMin = strToMinuti(
            orarioGiorno['orario_apertura'].toString().substring(0, 5),
          );
          final int chMin = strToMinuti(
            orarioGiorno['orario_chiusura'].toString().substring(0, 5),
          );

          if (minInizio < chMin && minFine > apMin) return true;

          final ap2 = orarioGiorno['orario_apertura_2']?.toString();
          final ch2 = orarioGiorno['orario_chiusura_2']?.toString();
          if (ap2 != null && ch2 != null) {
            final int ap2Min = strToMinuti(ap2.substring(0, 5));
            final int ch2Min = strToMinuti(ch2.substring(0, 5));
            if (minInizio < ch2Min && minFine > ap2Min) return true;
          }
        }

        giorno = giorno.add(const Duration(days: 1));
      }

      return false;
    } catch (e) {
      debugPrint("Errore controllo orario valido: $e");
      return true;
    }
  }
}
