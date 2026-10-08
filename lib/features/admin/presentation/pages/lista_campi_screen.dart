import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_campi/core/theme/app_theme.dart';
import 'package:app_campi/core/models/campo.dart';
import 'package:app_campi/core/repositories/campi_repository.dart';
import 'package:app_campi/features/prenotazione/application/creazione_partita_controller.dart';
import 'package:app_campi/features/prenotazione/presentation/pages/creazione_partita_page.dart';
import 'package:app_campi/features/auth/application/auth_provider.dart';
import 'package:app_campi/core/shared_widget/selezione_livello_dialog.dart';

class ListaCampiScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> societa;

  const ListaCampiScreen({super.key, required this.societa});

  @override
  ConsumerState<ListaCampiScreen> createState() => _ListaCampiScreenState();
}

class _ListaCampiScreenState extends ConsumerState<ListaCampiScreen> {
  final CampiRepository _campiRepository = CampiRepository();
  late Future<List<Campo>> _futureCampi;

  @override
  void initState() {
    super.initState();
    final String idSocieta = widget.societa['id'].toString();

    _futureCampi = _campiRepository.getCampiSocietaVisibili(idSocieta);
  }

  int _giocatoriPerSport(String sport, int defaultCampo) {
    final value = sport.trim().toLowerCase();

    if (value == 'tennis_singolo') return 2;
    if (value == 'tennis_doppio' || value == 'padel') return 4;
    if (value == 'calcio_5') return 10;
    if (value == 'calcio_6') return 12;
    if (value == 'calcio_7') return 14;
    if (value == 'calcio_8') return 16;
    if (value == 'calcio_11') return 22;
    if (value == 'basket') return 10;
    if (value == 'pallavolo') return 12;

    return defaultCampo;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.societa['nome_societa'] ?? 'Dettaglio Centro',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
            ),
            Text(
              widget.societa['indirizzo'] ?? '',
              style: const TextStyle(fontSize: 12, color: AppTheme.neonCyan),
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<Campo>>(
        future: _futureCampi,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.neonOrange),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Errore durante il caricamento:\n${snapshot.error}",
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final campi = snapshot.data ?? [];

          if (campi.isEmpty) {
            return const Center(
              child: Text(
                "Nessun campo disponibile al momento.",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: campi.length,
            itemBuilder: (context, index) {
              final Campo campo = campi[index];

              final List<String> sportLivelliCampo = [];

              for (final tariffa in campo.tariffeSport) {
                final String sport = tariffa.sport
                    .toString()
                    .trim()
                    .toLowerCase();

                if (sport.isNotEmpty) {
                  sportLivelliCampo.add(sport);
                }
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: AppTheme.neonCyan.withValues(alpha: 0.3),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    campo.nomeCampo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              campo.coperto ? Icons.roofing : Icons.wb_sunny,
                              size: 16,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              campo.coperto ? "Coperto" : "All'aperto",
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(width: 16),
                            const Icon(
                              Icons.groups,
                              size: 16,
                              color: AppTheme.neonOrange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              campo.tariffeSport.length > 1
                                  ? "da ${campo.tariffeSport.map((t) => _giocatoriPerSport(t.sport, campo.numeroDiGiocatori)).reduce((a, b) => a < b ? a : b)} Giocatori"
                                  : "${_giocatoriPerSport(campo.tariffeSport.isNotEmpty ? campo.tariffeSport.first.sport : '', campo.numeroDiGiocatori)} Giocatori",
                              style: const TextStyle(
                                color: AppTheme.neonOrange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        if (campo.tariffeSport.isNotEmpty) ...[
                          const SizedBox(height: 10),

                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: campo.tariffeSport.map((tariffa) {
                              final sport = tariffa.sport.trim().toLowerCase();

                              String nomeSport;

                              switch (sport) {
                                case 'tennis_singolo':
                                  nomeSport = 'Tennis singolo';
                                  break;
                                case 'tennis_doppio':
                                  nomeSport = 'Tennis doppio';
                                  break;
                                case 'padel':
                                  nomeSport = 'Padel';
                                  break;
                                case 'calcio_5':
                                  nomeSport = 'Calcio a 5';
                                  break;
                                case 'calcio_6':
                                  nomeSport = 'Calcio a 6';
                                  break;
                                case 'calcio_7':
                                  nomeSport = 'Calcio a 7';
                                  break;
                                case 'calcio_8':
                                  nomeSport = 'Calcio a 8';
                                  break;
                                case 'calcio_11':
                                  nomeSport = 'Calcio a 11';
                                  break;
                                case 'basket':
                                  nomeSport = 'Basket';
                                  break;
                                case 'pallavolo':
                                  nomeSport = 'Pallavolo';
                                  break;
                                default:
                                  nomeSport = sport;
                              }

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.neonCyan.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppTheme.neonCyan.withOpacity(0.25),
                                  ),
                                ),
                                child: Text(
                                  nomeSport,
                                  style: const TextStyle(
                                    color: AppTheme.neonCyan,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Prezzo",
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      Text(
                        campo.tariffeSport.isNotEmpty
                            ? campo.tariffeSport.length > 1
                                  ? "da €${campo.tariffeSport.map((t) => t.prezzo).reduce((a, b) => a < b ? a : b).toStringAsFixed(2)}"
                                  : "€${campo.tariffeSport.first.prezzo.toStringAsFixed(2)}"
                            : "€${campo.prezzo.toStringAsFixed(2)}",
                        style: const TextStyle(
                          color: AppTheme.neonCyan,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    final utente = ref.read(utenteCorrenteProvider).value;
                    final controller = ref.read(
                      creazionePartitaProvider.notifier,
                    );

                    String sportCampo = '';

                    if (campo.tariffeSport.isNotEmpty) {
                      sportCampo = campo.tariffeSport.first.sport
                          .trim()
                          .toLowerCase();
                    }

                    if (utente == null) {
                      controller.impostaSport(sportCampo);
                      controller.selezionaCampo(campo);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreazionePartitaPage(),
                        ),
                      );

                      return;
                    }

                    verificaESelezionaLivello(
                      context: context,
                      userId: utente.id,
                      livelliSportAttuali: utente.livelliSport,
                      sports: sportLivelliCampo,
                      onCompletato: () {
                        ref.invalidate(utenteCorrenteProvider);

                        controller.impostaSport(sportCampo);
                        controller.selezionaCampo(campo);

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreazionePartitaPage(),
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
