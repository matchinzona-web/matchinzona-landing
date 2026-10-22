import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app_campi/core/models/campo.dart';
import 'package:app_campi/core/models/orario_societa.dart';
import 'package:app_campi/core/repositories/campi_repository.dart';
import 'package:app_campi/core/repositories/orario_societa_repository.dart';
import 'package:app_campi/core/repositories/partita_repository.dart';
import 'package:app_campi/core/repositories/chiusura_straordinaria_repository.dart';
import 'package:app_campi/core/services/partita_service.dart';
import 'package:app_campi/core/theme/app_theme.dart';
import 'package:app_campi/core/utils/slot_utils.dart';

class PrenotazioneManualePage extends StatefulWidget {
  final String idSocieta;
  final String? idCampoIniziale;

  const PrenotazioneManualePage({
    super.key,
    required this.idSocieta,
    this.idCampoIniziale,
  });

  @override
  State<PrenotazioneManualePage> createState() =>
      _PrenotazioneManualePageState();
}

class _PrenotazioneManualePageState extends State<PrenotazioneManualePage> {
  final CampiRepository _campiRepository = CampiRepository();

  final OrarioSocietaRepository _orarioRepository = OrarioSocietaRepository();

  final PartitaRepository _partitaRepository = PartitaRepository();

  final ChiusuraStraordinariaRepository _chiusuraRepository =
      ChiusuraStraordinariaRepository();

  final PartitaService _partitaService = PartitaService();

  final TextEditingController _nomeController = TextEditingController();

  final TextEditingController _telefonoController = TextEditingController();

  final TextEditingController _notaController = TextEditingController();

  List<Campo> _campi = [];
  List<String> _slotDisponibili = [];

  Campo? _campoSelezionato;
  String? _orarioSelezionato;
  String? _sportSelezionato;
  int _durataSelezionata = 60;

  DateTime _dataSelezionata = DateTime.now();

  bool _isLoading = true;
  bool _isLoadingOrari = false;
  bool _isSaving = false;

  List<int> _durateDisponibili() {
    final campo = _campoSelezionato;
    final sport = _sportSelezionato;

    if (campo == null || sport == null) return [];

    for (final tariffa in campo.tariffeSport) {
      if (tariffa.sport.trim().toLowerCase() == sport.trim().toLowerCase()) {
        return tariffa.durateDisponibili;
      }
    }

    return [];
  }

  void _impostaCampoESport(Campo? campo) {
    _campoSelezionato = campo;
    _sportSelezionato = null;
    _durataSelezionata = 60;
    _orarioSelezionato = null;
    _slotDisponibili = [];

    if (campo == null || campo.tariffeSport.isEmpty) {
      return;
    }

    final tariffa = campo.tariffeSport.first;
    _sportSelezionato = tariffa.sport;

    final durate = tariffa.durateDisponibili;

    if (durate.isNotEmpty) {
      _durataSelezionata = durate.contains(60) ? 60 : durate.first;
    }
  }

  String _orarioFine(String inizio, int durata) {
    final minuti = SlotUtils.orarioInMinuti(inizio) + durata;

    return '${((minuti ~/ 60) % 24).toString().padLeft(2, '0')}:'
        '${(minuti % 60).toString().padLeft(2, '0')}';
  }

  double? _prezzoSelezionato() {
    final campo = _campoSelezionato;
    final sport = _sportSelezionato;

    if (campo == null || sport == null) return null;

    for (final tariffa in campo.tariffeSport) {
      if (tariffa.sport.trim().toLowerCase() == sport.trim().toLowerCase()) {
        return tariffa.prezzoPerDurata(_durataSelezionata);
      }
    }

    return null;
  }

  @override
  void initState() {
    super.initState();
    _inizializza();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefonoController.dispose();
    _notaController.dispose();
    super.dispose();
  }

  Future<void> _inizializza() async {
    setState(() => _isLoading = true);

    try {
      final campi = await _campiRepository.getCampiSocietaConDettagli(
        widget.idSocieta,
      );

      final societa = await Supabase.instance.client
          .from('societa')
          .select('limite_campi')
          .eq('id', widget.idSocieta)
          .single();

      final limite = societa['limite_campi'] as int? ?? campi.length;

      final campiAttivi = campi.take(limite).toList();

      Campo? iniziale;

      if (widget.idCampoIniziale != null) {
        for (final campo in campiAttivi) {
          if (campo.id == widget.idCampoIniziale) {
            iniziale = campo;
            break;
          }
        }
      }

      iniziale ??= campiAttivi.isNotEmpty ? campiAttivi.first : null;

      if (!mounted) return;

      setState(() {
        _campi = campiAttivi;
        _impostaCampoESport(iniziale);
        _isLoading = false;
      });

      if (iniziale != null) {
        await _caricaSlot();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      _mostraErrore('Impossibile caricare i campi');
    }
  }

  List<String> _generaSlotPerDurata(OrarioSocieta orario) {
    final slot = <String>[];
    final durata = _durataSelezionata;
    // Una durata disponibile: partenze ogni 60 o 90 minuti.
    // Entrambe disponibili: partenze ogni 30 minuti.
    final durate = _durateDisponibili();
    final passoMinuti = durate.length == 1 ? durate.first : 30;

    void aggiungiTurno(String? apertura, String? chiusura) {
      if (apertura == null || chiusura == null) return;

      var inizio = SlotUtils.orarioInMinuti(apertura);
      var fine = SlotUtils.orarioInMinuti(chiusura);

      if (fine == 0 && inizio > 0) {
        fine = 24 * 60;
      }

      // Non gestiamo ancora turni che attraversano la
      // mezzanotte e terminano dopo le 00:00.
      if (fine <= inizio) return;

      while (inizio + durata <= fine) {
        final ora = (inizio ~/ 60).toString().padLeft(2, '0');
        final minuti = (inizio % 60).toString().padLeft(2, '0');

        slot.add('$ora:$minuti');
        inizio += passoMinuti;
      }
    }

    aggiungiTurno(orario.orarioApertura, orario.orarioChiusura);
    aggiungiTurno(orario.orarioApertura2, orario.orarioChiusura2);

    return slot.toSet().toList()..sort(
      (a, b) =>
          SlotUtils.orarioInMinuti(a).compareTo(SlotUtils.orarioInMinuti(b)),
    );
  }

  Future<void> _caricaSlot() async {
    final campo = _campoSelezionato;
    if (campo == null) return;

    final data = _dataSelezionata;
    final durata = _durataSelezionata;
    final sport = _sportSelezionato;

    setState(() {
      _isLoadingOrari = true;
      _slotDisponibili = [];
      _orarioSelezionato = null;
    });

    try {
      final orario = await _orarioRepository.getOrarioGiorno(
        widget.idSocieta,
        data.weekday,
      );

      if (orario == null || orario.isChiuso) {
        if (!mounted) return;

        setState(() {
          _slotDisponibili = [];
          _isLoadingOrari = false;
        });
        return;
      }

      final tuttiGliSlot = _generaSlotPerDurata(orario);

      final intervalliOccupati = await _partitaRepository
          .getIntervalliOccupatiGiorno(idCampo: campo.id, data: data);

      final chiusure = await _chiusuraRepository.getChiusurePerData(
        widget.idSocieta,
        data,
      );

      final disponibili = <String>[];

      for (final slot in tuttiGliSlot) {
        final inizioSlot = SlotUtils.orarioInMinuti(slot);
        final fineSlot = inizioSlot + durata;

        bool chiuso = false;

        for (final chiusura in chiusure) {
          if (chiusura.orarioInizio == null || chiusura.orarioFine == null) {
            chiuso = true;
            break;
          }

          final inizioChiusura = SlotUtils.orarioInMinuti(
            chiusura.orarioInizio!,
          );

          var fineChiusura = SlotUtils.orarioInMinuti(chiusura.orarioFine!);

          if (fineChiusura == 0 && inizioChiusura > 0) {
            fineChiusura = 24 * 60;
          }

          if (inizioSlot < fineChiusura && fineSlot > inizioChiusura) {
            chiuso = true;
            break;
          }
        }

        if (chiuso) continue;

        final occupato = intervalliOccupati.any((partita) {
          final inizio = SlotUtils.orarioInMinuti(
            partita['orario_inizio'].toString(),
          );

          var fine = SlotUtils.orarioInMinuti(
            partita['orario_fine'].toString(),
          );

          if (fine == 0 && inizio > 0) {
            fine = 24 * 60;
          }

          return inizioSlot < fine && fineSlot > inizio;
        });

        if (occupato) continue;

        final parti = slot.split(':');

        final dataOraSlot = DateTime(
          data.year,
          data.month,
          data.day,
          int.parse(parti[0]),
          int.parse(parti[1]),
        );

        if (!dataOraSlot.isAfter(DateTime.now())) {
          continue;
        }

        disponibili.add(slot);
      }

      if (!mounted ||
          _campoSelezionato?.id != campo.id ||
          _dataSelezionata != data ||
          _durataSelezionata != durata ||
          _sportSelezionato != sport) {
        return;
      }

      setState(() {
        _slotDisponibili = disponibili;
        _orarioSelezionato = disponibili.isNotEmpty ? disponibili.first : null;
        _isLoadingOrari = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _slotDisponibili = [];
        _orarioSelezionato = null;
        _isLoadingOrari = false;
      });

      _mostraErrore('Errore caricamento disponibilità: $e');
    }
  }

  Future<void> _scegliData() async {
    final oggi = DateTime.now();

    final nuovaData = await showDatePicker(
      context: context,
      initialDate: _dataSelezionata,
      firstDate: DateTime(oggi.year, oggi.month, oggi.day),
      lastDate: oggi.add(const Duration(days: 365)),
      locale: const Locale('it', 'IT'),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.neonOrange,
              onPrimary: Colors.black,
              surface: AppTheme.cardBg,
            ),
          ),
          child: child!,
        );
      },
    );

    if (nuovaData == null) {
      return;
    }

    setState(() {
      _dataSelezionata = nuovaData;
    });

    await _caricaSlot();
  }

  String _formattaData(DateTime data) {
    const mesi = [
      'gennaio',
      'febbraio',
      'marzo',
      'aprile',
      'maggio',
      'giugno',
      'luglio',
      'agosto',
      'settembre',
      'ottobre',
      'novembre',
      'dicembre',
    ];

    return '${data.day} '
        '${mesi[data.month - 1]} '
        '${data.year}';
  }

  Future<void> _conferma() async {
    final campo = _campoSelezionato;
    final orario = _orarioSelezionato;
    final sport = _sportSelezionato;
    final durata = _durataSelezionata;

    if (campo == null || orario == null) {
      _mostraErrore('Seleziona campo e orario.');
      return;
    }

    final idGestore = Supabase.instance.client.auth.currentUser?.id;

    if (idGestore == null) {
      _mostraErrore('Sessione gestore non trovata.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Ricontrolliamo la disponibilità
      // immediatamente prima del salvataggio.
      if (sport == null ||
          !_durateDisponibili().contains(durata) ||
          _prezzoSelezionato() == null) {
        throw Exception('Sport, durata o prezzo non validi.');
      }

      if (!_slotDisponibili.contains(orario)) {
        throw Exception('L’orario selezionato non è disponibile.');
      }

      final occupato = await _partitaRepository.isIntervalloOccupato(
        idCampo: campo.id,
        data: _dataSelezionata,
        orarioInizio: '$orario:00',
        orarioFine: '${_orarioFine(orario, durata)}:00',
      );

      final libero = !occupato;

      if (!libero) {
        throw Exception(
          'Nel frattempo questo orario è stato occupato. '
          'Scegline un altro.',
        );
      }

      final risultato = await _partitaService.creaPrenotazioneManuale(
        campo: campo,
        idGestore: idGestore,
        dataPartita: _dataSelezionata,
        orarioInizio: orario,
        durataMinuti: durata,
        sport: sport,
        nomeCliente: _nomeController.text,
        telefonoCliente: _telefonoController.text,
        notaGestore: _notaController.text,
      );

      if (!risultato.isSuccesso) {
        throw Exception(
          risultato.errore ?? 'Impossibile creare la prenotazione.',
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prenotazione manuale inserita.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      _mostraErrore(e.toString().replaceFirst('Exception: ', ''));

      await _caricaSlot();
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _mostraErrore(String messaggio) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(messaggio), backgroundColor: Colors.redAccent),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: AppTheme.neonOrange),
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: TextStyle(color: Colors.grey.shade600),
      filled: true,
      fillColor: Colors.white.withOpacity(0.03),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade800),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.neonOrange, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Prenotazione manuale',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        iconTheme: const IconThemeData(color: AppTheme.neonOrange),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.neonOrange),
            )
          : SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: AppTheme.neonOrange.withOpacity(0.22),
                          ),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.add_task_rounded,
                              color: AppTheme.neonOrange,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Blocca rapidamente un campo '
                                'per una prenotazione ricevuta '
                                'al telefono o direttamente al centro. '
                                'La durata e il prezzo dipendono dallo sport e dal campo scelti.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        'CAMPO',
                        style: TextStyle(
                          color: AppTheme.neonOrange,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),

                      DropdownButtonFormField<Campo>(
                        initialValue: _campoSelezionato,
                        dropdownColor: AppTheme.cardBg,
                        decoration: _inputDecoration(
                          label: 'Campo da prenotare',
                          icon: Icons.sports_soccer_rounded,
                        ),
                        items: _campi
                            .map(
                              (campo) => DropdownMenuItem(
                                value: campo,
                                child: Text(
                                  campo.nomeCampo,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (campo) async {
                          if (campo == null) {
                            return;
                          }

                          setState(() {
                            _impostaCampoESport(campo);
                          });

                          await _caricaSlot();
                        },
                      ),

                      const SizedBox(height: 22),

                      if (_campoSelezionato != null &&
                          _campoSelezionato!.tariffeSport.length > 1) ...[
                        const Text(
                          'SPORT',
                          style: TextStyle(
                            color: AppTheme.neonOrange,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),

                        DropdownButtonFormField<String>(
                          key: ValueKey(
                            'sport_${_campoSelezionato!.id}_$_sportSelezionato',
                          ),
                          initialValue: _sportSelezionato,
                          dropdownColor: AppTheme.cardBg,
                          decoration: _inputDecoration(
                            label: 'Sport da prenotare',
                            icon: Icons.sports_rounded,
                          ),
                          items: _campoSelezionato!.tariffeSport.map((tariffa) {
                            return DropdownMenuItem<String>(
                              value: tariffa.sport,
                              child: Text(
                                tariffa.sport
                                    .replaceAll('_', ' ')
                                    .toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          }).toList(),
                          onChanged: (sport) async {
                            if (sport == null) return;

                            setState(() {
                              _sportSelezionato = sport;
                              final durate = _durateDisponibili();
                              _durataSelezionata = durate.contains(60)
                                  ? 60
                                  : (durate.isNotEmpty ? durate.first : 60);
                              _orarioSelezionato = null;
                            });

                            await _caricaSlot();
                          },
                        ),

                        const SizedBox(height: 22),
                      ],

                      const Text(
                        'DATA',
                        style: TextStyle(
                          color: AppTheme.neonOrange,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),

                      InkWell(
                        onTap: _scegliData,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 17,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade800),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_month_rounded,
                                color: AppTheme.neonOrange,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _formattaData(_dataSelezionata),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.white38,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'DURATA',
                        style: TextStyle(
                          color: AppTheme.neonOrange,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _durateDisponibili().map((durata) {
                          final selezionata = _durataSelezionata == durata;

                          return ChoiceChip(
                            label: Text('$durata minuti'),
                            selected: selezionata,
                            selectedColor: AppTheme.neonOrange,
                            backgroundColor: AppTheme.cardBg,
                            labelStyle: TextStyle(
                              color: selezionata
                                  ? Colors.black
                                  : Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (_) async {
                              if (_isLoadingOrari || _isSaving) return;

                              setState(() {
                                _durataSelezionata = durata;
                                _orarioSelezionato = null;
                              });

                              await _caricaSlot();
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 12),

                      Builder(
                        builder: (context) {
                          final prezzo = _prezzoSelezionato();

                          return Text(
                            prezzo == null
                                ? 'Prezzo non disponibile'
                                : 'Prezzo campo: ${prezzo.toStringAsFixed(2)} €',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'ORARIO DISPONIBILE',
                              style: TextStyle(
                                color: AppTheme.neonOrange,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          Text(
                            '$_durataSelezionata min',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (_isLoadingOrari)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.neonOrange,
                            ),
                          ),
                        )
                      else if (_slotDisponibili.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.025),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade800),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.event_busy_rounded,
                                color: Colors.white38,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Nessun orario libero '
                                  'per questa data.',
                                  style: TextStyle(color: Colors.white54),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _slotDisponibili.map((slot) {
                            final selezionato = _orarioSelezionato == slot;

                            return ChoiceChip(
                              selected: selezionato,
                              onSelected: (_) {
                                setState(() {
                                  _orarioSelezionato = slot;
                                });
                              },
                              label: Text(
                                '$slot → '
                                '${_orarioFine(slot, _durataSelezionata)}',
                              ),
                              selectedColor: AppTheme.neonOrange,
                              backgroundColor: AppTheme.cardBg,
                              side: BorderSide(
                                color: selezionato
                                    ? AppTheme.neonOrange
                                    : Colors.grey.shade800,
                              ),
                              labelStyle: TextStyle(
                                color: selezionato
                                    ? Colors.black
                                    : Colors.white70,
                                fontWeight: FontWeight.w800,
                              ),
                            );
                          }).toList(),
                        ),

                      const SizedBox(height: 30),

                      Row(
                        children: [
                          const Expanded(child: Divider(color: Colors.white10)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'DATI CLIENTE',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider(color: Colors.white10)),
                        ],
                      ),

                      const SizedBox(height: 22),

                      TextField(
                        controller: _nomeController,
                        textCapitalization: TextCapitalization.words,
                        decoration: _inputDecoration(
                          label: 'Nome cliente',
                          hint: 'Facoltativo',
                          icon: Icons.person_outline_rounded,
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller: _telefonoController,
                        keyboardType: TextInputType.phone,
                        decoration: _inputDecoration(
                          label: 'Telefono',
                          hint: 'Facoltativo',
                          icon: Icons.phone_outlined,
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller: _notaController,
                        minLines: 3,
                        maxLines: 5,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: _inputDecoration(
                          label: 'Nota interna',
                          hint: 'Es. paga al campo, cliente abituale...',
                          icon: Icons.sticky_note_2_outlined,
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),

                      const SizedBox(height: 30),

                      SizedBox(
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving || _orarioSelezionato == null
                              ? null
                              : _conferma,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.neonOrange,
                            foregroundColor: Colors.black,
                            disabledBackgroundColor: Colors.grey.shade800,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : const Icon(Icons.check_circle_outline_rounded),
                          label: Text(
                            _isSaving
                                ? 'SALVATAGGIO...'
                                : 'CONFERMA PRENOTAZIONE',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
