import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_campi/core/theme/app_theme.dart';
import 'package:app_campi/core/services/campi_service.dart';
import 'package:app_campi/features/admin/presentation/pages/dashboard_gestore_page.dart';

class ConfigurazioneOrari extends StatefulWidget {
  final String? idSocieta;

  const ConfigurazioneOrari({super.key, this.idSocieta});

  @override
  State<ConfigurazioneOrari> createState() => _ConfigurazioneOrariState();
}

class _ConfigurazioneOrariState extends State<ConfigurazioneOrari> {
  late final CampiService _campiService;
  bool _isLoading = false;

  final List<String> _nomiGiorni = [
    'Lunedì',
    'Martedì',
    'Mercoledì',
    'Giovedì',
    'Venerdì',
    'Sabato',
    'Domenica',
  ];

  late List<Map<String, dynamic>> _orari;

  @override
  void initState() {
    super.initState();
    _campiService = CampiService();
    _orari = List.generate(
      7,
      (index) => {
        'giorno_settimana': index + 1,
        'is_chiuso': false,
        'orario_apertura': const TimeOfDay(hour: 8, minute: 0),
        'orario_chiusura': const TimeOfDay(hour: 13, minute: 0),
        'has_secondo_turno': false,
        'orario_apertura_2': const TimeOfDay(hour: 16, minute: 0),
        'orario_chiusura_2': const TimeOfDay(hour: 21, minute: 0),
      },
    );
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
          'Orari di ${_nomiGiorni[sorgenteIndex]} copiati su tutta la settimana! 📋',
        ),
        backgroundColor: AppTheme.neonOrange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _selezionaOrario(
    int index,
    bool isApertura,
    bool isSecondoTurno,
  ) async {
    final chiave = isSecondoTurno
        ? (isApertura ? 'orario_apertura_2' : 'orario_chiusura_2')
        : (isApertura ? 'orario_apertura' : 'orario_chiusura');

    final TimeOfDay orarioAttuale = _convertiInTimeOfDay(_orari[index][chiave]);

    final TimeOfDay? nuovoOrario = await showTimePicker(
      context: context,
      initialTime: orarioAttuale,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.neonOrange,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );

    if (nuovoOrario != null) {
      setState(() => _orari[index][chiave] = nuovoOrario);
    }
  }

  bool _orarioValido(int index) {
    final o = _orari[index];
    if (o['is_chiuso'] == true) return true;

    final ap1 = _convertiInTimeOfDay(o['orario_apertura']);
    final ch1 = _convertiInTimeOfDay(o['orario_chiusura']);

    final int minAp1 = ap1.hour * 60 + ap1.minute;

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

      if (minAp2 != 0 && minAp2 <= minCh1) return false;

      if (minAp2 == 0 && minCh1 < 1440) {}

      if (minCh2 <= minAp2) return false;
    }

    return true;
  }

  Future<void> _salvaOrari() async {
    setState(() => _isLoading = true);
    // Controllo validità orari
    for (int i = 0; i < _orari.length; i++) {
      if (!_orarioValido(i)) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Orari non validi per ${_nomiGiorni[i]}: verifica che l\'apertura sia prima della chiusura.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }

    try {
      String? idSocieta = widget.idSocieta;
      final supabase = Supabase.instance.client;

      if (idSocieta == null) {
        final utenteAttuale = supabase.auth.currentUser;
        if (utenteAttuale == null) {
          throw Exception("Sessione utente non trovata.");
        }
        final societaData = await supabase
            .from('societa')
            .select('id')
            .eq('id_utente', utenteAttuale.id)
            .single();
        idSocieta = societaData['id'] as String;
      }

      final List<Map<String, dynamic>> orariProntiPerDb = _orari
          .map(
            (o) => {
              'id_societa': idSocieta,
              'giorno_settimana': o['giorno_settimana'],
              'is_chiuso': o['is_chiuso'],
              'orario_apertura': _convertiInTimeOfDay(o['orario_apertura']),
              'orario_chiusura': _convertiInTimeOfDay(o['orario_chiusura']),
              'orario_apertura_2': o['has_secondo_turno'] == true
                  ? _convertiInTimeOfDay(o['orario_apertura_2'])
                  : null,
              'orario_chiusura_2': o['has_secondo_turno'] == true
                  ? _convertiInTimeOfDay(o['orario_chiusura_2'])
                  : null,
            },
          )
          .toList();

      await _campiService.salvaOrariSocieta(
        idSocieta: idSocieta,
        listaOrari: orariProntiPerDb,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configurazione completata! Benvenuto. 🎉'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardGestore(idSocieta: idSocieta!),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        title: const Text('Orari di Apertura'),
        iconTheme: const IconThemeData(color: AppTheme.neonOrange),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Configura gli orari standard del tuo centro. Puoi gestire turni unici o spezzati (es. mattina e pomeriggio) e copiare le impostazioni su tutti i giorni per velocizzare.',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: 7,
                  padding: const EdgeInsets.only(bottom: 20),
                  itemBuilder: (context, index) {
                    final giorno = _orari[index];
                    final isChiuso = giorno['is_chiuso'];
                    final hasSecondoTurno = giorno['has_secondo_turno'];
                    final tApertura1 = _convertiInTimeOfDay(
                      giorno['orario_apertura'],
                    );
                    final tChiusura1 = _convertiInTimeOfDay(
                      giorno['orario_chiusura'],
                    );
                    final tApertura2 = _convertiInTimeOfDay(
                      giorno['orario_apertura_2'],
                    );
                    final tChiusura2 = _convertiInTimeOfDay(
                      giorno['orario_chiusura_2'],
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
                              : AppTheme.neonOrange.withValues(alpha: 0.4),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Switch(
                                      value: !isChiuso,
                                      activeThumbColor: AppTheme.neonOrange,
                                      inactiveThumbColor: Colors.grey,
                                      onChanged: (valore) => setState(
                                        () => _orari[index]['is_chiuso'] =
                                            !valore,
                                      ),
                                    ),
                                    Text(
                                      _nomiGiorni[index],
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
                                    onPressed: () => _copiaOrarioATutti(index),
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
                                        onPressed: () => _selezionaOrario(
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
                                        style: TextStyle(color: Colors.white30),
                                      ),
                                      TextButton(
                                        onPressed: () => _selezionaOrario(
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
                                          onPressed: () => _selezionaOrario(
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
                                          onPressed: () => _selezionaOrario(
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
                                    () => _orari[index]['has_secondo_turno'] =
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
                    onPressed: _isLoading ? null : _salvaOrari,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.neonOrange,
                      foregroundColor: AppTheme.darkBg,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Salva Orari e Entra nella Dashboard',
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
