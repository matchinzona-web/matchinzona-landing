import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_campi/features/prenotazione/application/creazione_partita_controller.dart';
import 'package:app_campi/core/theme/app_theme.dart';
import 'package:app_campi/features/prenotazione/presentation/widget/societa_card_pro.dart';
import 'lista_campi_centro_page.dart';

class RicercaCentriPage extends ConsumerStatefulWidget {
  const RicercaCentriPage({super.key});

  @override
  ConsumerState<RicercaCentriPage> createState() => _RicercaCentriPageState();
}

class _RicercaCentriPageState extends ConsumerState<RicercaCentriPage> {
  @override
  void initState() {
    super.initState();

    final controller = ref.read(creazionePartitaProvider.notifier);

    // Sincronizza il valore visualizzato con quello già usato dal filtro.
    _provinciaSelezionata =
        controller.provinciaSelezionata ?? 'Tutte le province';

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      controller.applicaFiltri();

      final province = await controller.caricaProvinceDisponibili();

      if (!mounted) return;

      setState(() {
        _provinceDisponibili = province;
      });
    });
  }

  final TextEditingController searchCtrl = TextEditingController();
  TipoRicerca filtroSelezionato = TipoRicerca.tutti;
  String _provinciaSelezionata = 'Tutte le province';
  List<String> _provinceDisponibili = [];

  Timer? _debounceTimer;
  bool _ricercaAttiva = false;

  final List<Map<String, dynamic>> _sports = [
    {'id': 'calcio_5', 'label': 'Calcio 5', 'icon': Icons.sports_soccer},
    {'id': 'calcio_6', 'label': 'Calcio 6', 'icon': Icons.sports_soccer},
    {'id': 'calcio_7', 'label': 'Calcio 7', 'icon': Icons.sports_soccer},
    {'id': 'calcio_8', 'label': 'Calcio 8', 'icon': Icons.sports_soccer},
    {'id': 'calcio_11', 'label': 'Calcio 11', 'icon': Icons.sports_soccer},
    {'id': 'padel', 'label': 'Padel', 'icon': Icons.sports_tennis},
    {'id': 'tennis', 'label': 'Tennis', 'icon': Icons.sports_tennis},
    {'id': 'basket', 'label': 'Basket', 'icon': Icons.sports_basketball},
    {'id': 'pallavolo', 'label': 'Pallavolo', 'icon': Icons.sports_volleyball},
  ];

  @override
  void dispose() {
    _debounceTimer?.cancel();
    searchCtrl.dispose();
    super.dispose();
  }

  // POPUP SELEZIONE OPZIONE B: TENNIS SINGOLO O DOPPIO
  void _mostraModalitaTennis(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E2026),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Che tipo di Tennis vuoi giocare?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.person, color: AppTheme.neonOrange),
                title: const Text(
                  'Singolo (1 vs 1)',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  '2 Giocatori in campo',
                  style: TextStyle(color: Colors.grey),
                ),
                onTap: () {
                  ref
                      .read(creazionePartitaProvider.notifier)
                      .impostaSport('tennis_singolo');
                  ref.read(creazionePartitaProvider.notifier).applicaFiltri();
                  Navigator.pop(context);
                },
              ),
              const Divider(color: Colors.white12),
              ListTile(
                leading: const Icon(Icons.group, color: AppTheme.neonOrange),
                title: const Text(
                  'Doppio (2 vs 2)',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  '4 Giocatori in campo',
                  style: TextStyle(color: Colors.grey),
                ),
                onTap: () {
                  ref
                      .read(creazionePartitaProvider.notifier)
                      .impostaSport('tennis_doppio');
                  ref.read(creazionePartitaProvider.notifier).applicaFiltri();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // BOTTOM SHEET PER LA SCELTA DI TUTTI GLI SPORT
  void _mostraSelezionaSport(BuildContext context) {
    final state = ref.read(creazionePartitaProvider);

    // Mappa di visualizzazione con le etichette per l'interfaccia
    final List<Map<String, dynamic>> tuttiGliSport = [
      {'id': 'calcio_5', 'label': 'Calcio a 5', 'icon': Icons.sports_soccer},
      {'id': 'calcio_6', 'label': 'Calcio 6', 'icon': Icons.sports_soccer},
      {'id': 'calcio_7', 'label': 'Calcio a 7', 'icon': Icons.sports_soccer},
      {'id': 'calcio_8', 'label': 'Calcio a 8', 'icon': Icons.sports_soccer},
      {'id': 'calcio_11', 'label': 'Calcio a 11', 'icon': Icons.sports_soccer},
      {'id': 'padel', 'label': 'Padel', 'icon': Icons.sports_tennis},
      {
        'id': 'tennis',
        'label': 'Tennis',
        'icon': Icons.sports_tennis,
      }, // Apre sotto-scelta Singolo/Doppio
      {'id': 'basket', 'label': 'Basket', 'icon': Icons.sports_basketball},
      {
        'id': 'pallavolo',
        'label': 'Pallavolo',
        'icon': Icons.sports_volleyball,
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E2026),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    'Seleziona Sport',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: tuttiGliSport.length,
                    separatorBuilder: (context, index) =>
                        const Divider(color: Colors.white12, height: 1),
                    itemBuilder: (context, index) {
                      final item = tuttiGliSport[index];
                      final String sportId = item['id'];
                      final String label = item['label'];
                      final IconData icon = item['icon'];

                      // Controlla se è lo sport attualmente selezionato
                      final bool isSelected =
                          state.sportSelezionato == sportId ||
                          (sportId == 'tennis' &&
                              state.sportSelezionato.contains('tennis'));

                      return ListTile(
                        leading: Icon(
                          icon,
                          color: isSelected
                              ? AppTheme.neonOrange
                              : Colors.grey.shade400,
                        ),
                        title: Text(
                          label,
                          style: TextStyle(
                            color: isSelected
                                ? AppTheme.neonOrange
                                : Colors.white,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: AppTheme.neonOrange,
                                size: 20,
                              )
                            : null,
                        onTap: () {
                          Navigator.pop(context); // Chiude il menu
                          if (sportId == 'tennis') {
                            _mostraModalitaTennis(context);
                          } else {
                            ref
                                .read(creazionePartitaProvider.notifier)
                                .impostaSport(sportId);
                            ref
                                .read(creazionePartitaProvider.notifier)
                                .applicaFiltri();
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Funzione di utilità per formattare l'etichetta dello sport selezionato sul pulsante
  String _getEtichettaSport(String sportId) {
    switch (sportId) {
      case 'calcio_5':
        return 'Calcio 5';
      case 'calcio_6':
        return 'Calcio 6';
      case 'calcio_7':
        return 'Calcio 7';
      case 'calcio_8':
        return 'Calcio 8';
      case 'calcio_11':
        return 'Calcio 11';
      case 'padel':
        return 'Padel';
      case 'tennis_singolo':
        return 'Tennis (Singolo)';
      case 'tennis_doppio':
        return 'Tennis (Doppio)';
      case 'basket':
        return 'Basket';
      case 'pallavolo':
        return 'Pallavolo';
      default:
        return 'Calcio 5';
    }
  }

  // BOTTOM SHEET PER LA SCELTA FASCIA ORARIA
  void _mostraSelezionaOrario(BuildContext context) {
    final state = ref.read(creazionePartitaProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E2026),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'A che ora vuoi giocare?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildOpzioneOrario(
                'Tutto il giorno',
                '00:00 - 23:59',
                'tutto',
                state.fasciaOraria,
              ),
              _buildOpzioneOrario(
                'Mattino',
                '06:00 - 12:00',
                'mattina',
                state.fasciaOraria,
              ),
              _buildOpzioneOrario(
                'Pomeriggio',
                '12:00 - 18:00',
                'pomeriggio',
                state.fasciaOraria,
              ),
              _buildOpzioneOrario(
                'Sera',
                '18:00 - 24:00',
                'sera',
                state.fasciaOraria,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOpzioneOrario(
    String titolo,
    String orario,
    String chiave,
    String corrente,
  ) {
    final isSelected = chiave == corrente;
    return RadioListTile<String>(
      title: Text(titolo, style: const TextStyle(color: Colors.white)),
      subtitle: Text(orario, style: const TextStyle(color: Colors.grey)),
      value: chiave,
      groupValue: corrente,
      activeColor: AppTheme.neonOrange,
      onChanged: (val) {
        if (val != null) {
          ref.read(creazionePartitaProvider.notifier).impostaFasciaOraria(val);
          ref.read(creazionePartitaProvider.notifier).applicaFiltri();
          Navigator.pop(context);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(creazionePartitaProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121318),
      body: SafeArea(
        child: Column(
          children: [
            // BARRA DI RICERCA + TITOLO
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'PRENOTA CAMPO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // INPUT RICERCA
                  TextField(
                    controller: searchCtrl,
                    style: const TextStyle(color: Colors.white),
                    onChanged: (val) {
                      final testo = val.trim();

                      setState(() => _ricercaAttiva = testo.length >= 3);

                      if (testo.length >= 3) {
                        ref
                            .read(creazionePartitaProvider.notifier)
                            .cercaSocieta(testo);
                      } else {
                        ref
                            .read(creazionePartitaProvider.notifier)
                            .applicaFiltri();
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Cerca per centro o città...',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppTheme.neonOrange,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1E2026),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // BARRA FILTRI POPUP (SOLO SPORT E GIORNO)
            if (!_ricercaAttiva)
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // 1. TENDINA SPORT
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        avatar: const Icon(
                          Icons.sports_soccer_rounded,
                          size: 16,
                          color: AppTheme.neonOrange,
                        ),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _getEtichettaSport(state.sportSelezionato),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.white54,
                              size: 18,
                            ),
                          ],
                        ),
                        selected: false,
                        backgroundColor: const Color(0xFF1E2026),
                        onSelected: (_) => _mostraSelezionaSport(context),
                      ),
                    ),

                    // 2. TENDINA GIORNO
                    FilterChip(
                      avatar: const Icon(
                        Icons.calendar_today_rounded,
                        size: 15,
                        color: AppTheme.neonOrange,
                      ),
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formattaDataFiltro(state.dataSelezionata),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.white54,
                            size: 18,
                          ),
                        ],
                      ),
                      selected: false,
                      backgroundColor: const Color(0xFF1E2026),
                      onSelected: (_) => _selezionaGiorno(context),
                    ),
                    const SizedBox(width: 8),

                    FilterChip(
                      avatar: const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: AppTheme.neonOrange,
                      ),
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _provinciaSelezionata,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.white54,
                            size: 18,
                          ),
                        ],
                      ),
                      selected: false,
                      backgroundColor: const Color(0xFF1E2026),
                      onSelected: (_) => _mostraSelezionaProvincia(context),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // LISTA REALE SOCIETA / CAMPI (Stile Playtomic)
            Expanded(
              child: state.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.neonOrange,
                      ),
                    )
                  : state.societaTrovate.isEmpty
                  ? Center(
                      child: Text(
                        'Nessun centro trovato.',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.societaTrovate.length,
                      itemBuilder: (context, index) {
                        final societa = state.societaTrovate[index];
                        // Recupera il prezzo dinamico estratto dal JSONB per questo sport
                        final double prezzoReale =
                            state.prezziPerSocieta[societa.id] ?? 0.0;

                        return SocietaCardPro(
                          societa: societa,
                          sport: state.sportSelezionato,
                          prezzoPartenza:
                              prezzoReale, // <-- PREZZO REALE DAL DATABASE!
                          distanzaKm:
                              null, // Metti null se non vuoi mostrare i km inventati, oppure la tua variabile se hai la geolocalizzazione attiva
                          onTap: () {
                            ref
                                .read(creazionePartitaProvider.notifier)
                                .caricaCampiSocieta(societa.id);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ListaCampiCentroPage(societa: societa),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // POPUP CALENDARIO GIORNO
  Future<void> _selezionaGiorno(BuildContext context) async {
    final state = ref.read(creazionePartitaProvider);

    final DateTime? nuovaData = await showDatePicker(
      context: context,
      initialDate: state.dataSelezionata,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.neonOrange,
              onPrimary: Colors.black,
              surface: Color(0xFF1E2026),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (nuovaData != null) {
      ref.read(creazionePartitaProvider.notifier).impostaData(nuovaData);
      ref.read(creazionePartitaProvider.notifier).applicaFiltri();
    }
  }

  // Funzione di utilità per formattare la data sul pulsante (es. "Oggi", "Domani", "14 Ago")
  String _formattaDataFiltro(DateTime data) {
    final ora = DateTime.now();
    final oggi = DateTime(ora.year, ora.month, ora.day);
    final dataConfronto = DateTime(data.year, data.month, data.day);

    if (dataConfronto == oggi) return 'Oggi';
    if (dataConfronto == oggi.add(const Duration(days: 1))) return 'Domani';

    return '${data.day}/${data.month}';
  }

  void _mostraSelezionaProvincia(BuildContext context) {
    final province = ['Tutte le province', ..._provinceDisponibili];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E2026),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: province.length,
            separatorBuilder: (_, _) =>
                const Divider(color: Colors.white12, height: 1),
            itemBuilder: (context, index) {
              final provincia = province[index];
              final selezionata = provincia == _provinciaSelezionata;

              return ListTile(
                title: Text(
                  provincia,
                  style: TextStyle(
                    color: selezionata ? AppTheme.neonOrange : Colors.white,
                    fontWeight: selezionata
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                trailing: selezionata
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: AppTheme.neonOrange,
                      )
                    : null,
                onTap: () async {
                  Navigator.pop(context);

                  setState(() {
                    _provinciaSelezionata = provincia;
                  });

                  await ref
                      .read(creazionePartitaProvider.notifier)
                      .impostaProvincia(provincia);
                },
              );
            },
          ),
        );
      },
    );
  }
}
