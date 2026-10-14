import 'package:flutter/material.dart';
import 'package:app_campi/core/theme/app_theme.dart';
import 'package:app_campi/features/admin/config/piani_config.dart';
import 'package:app_campi/features/auth/presentation/pages/registrazione_proprietario_page.dart';
import 'package:app_campi/features/admin/presentation/pages/richiedi_accesso_gestore_page.dart';

class PianiAbbonamentoScreen extends StatefulWidget {
  const PianiAbbonamentoScreen({super.key});

  @override
  State<PianiAbbonamentoScreen> createState() => _PianiAbbonamentoScreenState();
}

class _PianiAbbonamentoScreenState extends State<PianiAbbonamentoScreen> {
  int _indiceSelezionato = 1; // PRO preselezionato

  void _continuaConPiano(String nomePiano) {
    // ============================================================
    // FLUSSO ABBONAMENTI A PAGAMENTO - DA RIATTIVARE IN FUTURO
    // ============================================================
    /*
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) =>
          RegistrazioneProprietario(pianoScelto: nomePiano),
    ),
  );
  */

    // ============================================================
    // FASE LANCIO - ACCESSO GRATUITO PER I CENTRI SPORTIVI
    // ============================================================
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            RichiediAccessoGestorePage(pianoScelto: nomePiano),
      ),
    );
  }

  Widget _buildHero() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.neonOrange.withOpacity(0.12),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppTheme.neonOrange.withOpacity(0.5)),
          ),
          child: const Text(
            'Abbonamenti MatchInZona',
            style: TextStyle(
              color: AppTheme.neonOrange,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Approfitta del PERIODO GRATUITO.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Gestisci prenotazioni, partite e clienti in modo semplice. Trova il piano giusto per il tuo centro sportivo e porta subito la tua struttura su MatchInZona.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 15,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPianoCard({
    required int index,
    required Map<String, dynamic> piano,
  }) {
    final bool isSelezionato = _indiceSelezionato == index;

    return GestureDetector(
      onTap: () => setState(() => _indiceSelezionato = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 310,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelezionato
                ? AppTheme.neonOrange
                : Colors.white.withOpacity(0.08),
            width: isSelezionato ? 2.2 : 1.2,
          ),
          boxShadow: [
            if (isSelezionato)
              BoxShadow(
                color: AppTheme.neonOrange.withOpacity(0.12),
                blurRadius: 22,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              piano['titolo'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              piano['sottotitolo'],
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            ),
            const SizedBox(height: 18),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    '€',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  piano['prezzo'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            Text(
              'al mese',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
            const SizedBox(height: 22),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.sports_soccer_rounded,
                    color: AppTheme.neonOrange,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      piano['limiti'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Text(
              piano['descrizione'],
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),

            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 18),

            _buildMiniFeature(
              Icons.calendar_month_rounded,
              'Calendario e prenotazioni',
            ),
            _buildMiniFeature(
              Icons.groups_rounded,
              'Partite aperte e gestione giocatori',
            ),
            _buildMiniFeature(
              Icons.payments_rounded,
              'Pagamenti e gestione incassi',
            ),
            _buildMiniFeature(
              Icons.insights_rounded,
              'Statistiche e controllo attività',
            ),

            const SizedBox(height: 26),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _continuaConPiano(piano['nome'].toString()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelezionato
                      ? AppTheme.neonOrange
                      : Colors.white.withOpacity(0.06),
                  foregroundColor: isSelezionato ? Colors.black : Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: isSelezionato
                          ? AppTheme.neonOrange
                          : Colors.white24,
                    ),
                  ),
                ),
                child: Text(
                  // 'Scegli ${piano['titolo']}',
                  'Prova gratis',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniFeature(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.neonOrange, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.neonOrange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppTheme.neonOrange, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 900),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Perché scegliere MatchInZona?',
            style: TextStyle(
              color: AppTheme.neonOrange,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 22),

          _buildFeatureRow(
            Icons.calendar_today_rounded,
            'Prenotazioni sempre sotto controllo',
            'Gestisci disponibilità, campi, orari e prenotazioni da un unico pannello semplice e veloce.',
          ),

          _buildFeatureRow(
            Icons.schedule_rounded,
            'Meno chiamate, più tempo per il tuo centro',
            'I clienti vedono le disponibilità aggiornate e possono prenotare direttamente, riducendo chiamate e messaggi.',
          ),

          _buildFeatureRow(
            Icons.groups_rounded,
            'Più opportunità per riempire i campi',
            'Con le Partite Aperte, i giocatori possono trovare nuovi compagni e completare le partite direttamente su MatchInZona.',
          ),

          _buildFeatureRow(
            Icons.payments_rounded,
            'Incassi come preferisci',
            'Puoi accettare pagamenti online, in sede oppure offrire entrambe le modalità in base alle esigenze del centro.',
          ),

          _buildFeatureRow(
            Icons.location_on_rounded,
            'Fatti trovare dai giocatori vicini',
            'Il tuo centro può comparire nella ricerca e nel radar di MatchInZona, aiutando i giocatori della zona a scoprirlo.',
          ),

          _buildFeatureRow(
            Icons.query_stats_rounded,
            'Statistiche chiare sul tuo centro',
            'Monitora prenotazioni, incassi e andamento dell’attività direttamente dall’app.',
          ),
        ],
      ),
    );
  }

  Widget _buildPolicySection() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 900),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informazioni utili',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          _policyItem('Nessun costo di attivazione.'),
          _policyItem('Abbonamento mensile rinnovabile.'),
          _policyItem(
            'Puoi scegliere il piano più adatto in base al numero di campi gestiti.',
          ),
          _policyItem(
            'Se in futuro aumentano i tuoi campi, potrai passare al piano superiore.',
          ),
        ],
      ),
    );
  }

  Widget _policyItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 3),
            child: Icon(
              Icons.check_circle_rounded,
              color: AppTheme.neonOrange,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ),
        ],
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
        iconTheme: const IconThemeData(color: AppTheme.neonOrange),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              children: [
                _buildHero(),
                const SizedBox(height: 40),

                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  alignment: WrapAlignment.center,
                  children: PianiConfig.piani.asMap().entries.map((entry) {
                    return _buildPianoCard(
                      index: entry.key,
                      piano: entry.value,
                    );
                  }).toList(),
                ),

                const SizedBox(height: 40),
                _buildInfoBox(),
                const SizedBox(height: 24),
                _buildPolicySection(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
