import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_campi/core/theme/app_theme.dart';
import 'package:app_campi/features/admin/application/statistiche_provider.dart';

class StatisticheGuadagni extends ConsumerStatefulWidget {
  final String idSocieta;

  const StatisticheGuadagni({super.key, required this.idSocieta});

  @override
  ConsumerState<StatisticheGuadagni> createState() =>
      _StatisticheGuadagniState();
}

class _StatisticheGuadagniState extends ConsumerState<StatisticheGuadagni> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(statisticheProvider.notifier).caricaDati(widget.idSocieta),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(statisticheProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        title: const Text('Resoconto Guadagni'),
        iconTheme: const IconThemeData(color: AppTheme.neonOrange),
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.neonOrange),
            )
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SELETTORE PERIODO
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ['Oggi', 'Settimana', 'Mese', 'Anno'].map((
                      periodo,
                    ) {
                      final bool isSelected =
                          state.periodoSelezionato == periodo;
                      return ChoiceChip(
                        label: Text(periodo),
                        selected: isSelected,
                        selectedColor: AppTheme.neonOrange,
                        backgroundColor: AppTheme.cardBg,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            ref
                                .read(statisticheProvider.notifier)
                                .impostaPeriodo(periodo);
                          }
                        },
                      );
                    }).toList(),
                  ),

                  if (state.periodoSelezionato == 'Anno' &&
                      state.anniDisponibili.isNotEmpty) ...[
                    const SizedBox(height: 16),

                    SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: state.anniDisponibili.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final anno = state.anniDisponibili[index];
                          final selezionato = state.annoAttivo == anno;

                          return ChoiceChip(
                            label: Text(anno.toString()),
                            selected: selezionato,
                            selectedColor: AppTheme.neonOrange,
                            backgroundColor: AppTheme.cardBg,
                            labelStyle: TextStyle(
                              color: selezionato ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (_) {
                              ref
                                  .read(statisticheProvider.notifier)
                                  .impostaAnno(anno);
                            },
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 25),

                  Card(
                    color: AppTheme.cardBg,
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(
                        color: AppTheme.neonOrange,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Text(
                            'Guadagno Totale (${state.periodoSelezionato})',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '€ ${state.guadagnoTotale.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: AppTheme.neonOrange,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${state.numeroPartiteVisualizzate} partite giocate',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  const Text(
                    'Dettaglio per Campo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 15),

                  // LISTA PER CAMPO
                  Expanded(
                    child: state.guadagniPerCampo.isEmpty
                        ? const Center(
                            child: Text(
                              'Nessun incasso in questo periodo.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: state.guadagniPerCampo.keys.length,
                            itemBuilder: (context, index) {
                              final campoNome = state.guadagniPerCampo.keys
                                  .elementAt(index);
                              final campoIncasso =
                                  state.guadagniPerCampo[campoNome]!;
                              return Card(
                                color: AppTheme.cardBg,
                                margin: const EdgeInsets.only(bottom: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.monetization_on,
                                    color: AppTheme.neonOrange,
                                  ),
                                  title: Text(
                                    campoNome,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  trailing: Text(
                                    '€ ${campoIncasso.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
