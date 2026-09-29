import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:app_campi/core/theme/app_theme.dart';

class PrivacyAssistenzaGestore extends StatelessWidget {
  const PrivacyAssistenzaGestore({super.key});

  Future<void> _apriUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);

    try {
      final aperto = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!aperto && context.mounted) {
        _mostraErrore(context);
      }
    } catch (_) {
      if (context.mounted) {
        _mostraErrore(context);
      }
    }
  }

  Future<void> _inviaEmail(
    BuildContext context, {
    required String oggetto,
  }) async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'matchly.assistenza@gmail.com',
      queryParameters: {'subject': oggetto},
    );

    try {
      final aperto = await launchUrl(uri);

      if (!aperto && context.mounted) {
        _mostraErroreEmail(context);
      }
    } catch (_) {
      if (context.mounted) {
        _mostraErroreEmail(context);
      }
    }
  }

  void _mostraErrore(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Impossibile aprire il collegamento.'),
        backgroundColor: AppTheme.statoErrore,
      ),
    );
  }

  void _mostraErroreEmail(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Non è stato possibile aprire l’app email.'),
        backgroundColor: AppTheme.statoErrore,
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 15,
                  color: Colors.white24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        foregroundColor: AppTheme.neonOrange,
        title: const Text(
          'Privacy e Assistenza',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'PRIVACY E LEGALE',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),

          const SizedBox(height: 14),

          _buildTile(
            icon: Icons.privacy_tip_outlined,
            color: AppTheme.neonGreen,
            title: 'Privacy Policy',
            subtitle: 'Scopri come vengono trattati i tuoi dati',
            onTap: () => _apriUrl(
              context,
              'https://matchlyassistenza-web.github.io/matchly-privacy/',
            ),
          ),

          _buildTile(
            icon: Icons.description_outlined,
            color: AppTheme.neonPurple,
            title: 'Termini e Condizioni',
            subtitle: 'Consulta le condizioni di utilizzo di Matchly',
            onTap: () => _apriUrl(
              context,
              'https://matchlyassistenza-web.github.io/matchly-privacy/termini.html',
            ),
          ),

          _buildTile(
            icon: Icons.delete_outline_rounded,
            color: Colors.redAccent,
            title: 'Eliminazione account e dati',
            subtitle: 'Informazioni sulla cancellazione del tuo account',
            onTap: () => _apriUrl(
              context,
              'https://matchlyassistenza-web.github.io/matchly-privacy/elimina-account.html',
            ),
          ),

          const SizedBox(height: 22),

          const Text(
            'ASSISTENZA',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),

          const SizedBox(height: 14),

          _buildTile(
            icon: Icons.support_agent_rounded,
            color: AppTheme.neonOrange,
            title: 'Contatta assistenza',
            subtitle: 'Scrivici per domande o richieste',
            onTap: () =>
                _inviaEmail(context, oggetto: 'Assistenza Gestore Matchly'),
          ),

          _buildTile(
            icon: Icons.bug_report_outlined,
            color: Colors.amber,
            title: 'Segnala un problema',
            subtitle: 'Segnalaci malfunzionamenti o difficoltà',
            onTap: () => _inviaEmail(
              context,
              oggetto: 'Segnalazione problema Gestore Matchly',
            ),
          ),

          const SizedBox(height: 22),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: const Column(
              children: [
                Text(
                  'MATCHLY',
                  style: TextStyle(
                    color: AppTheme.neonOrange,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Trova. Prenota. Gioca.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                SizedBox(height: 12),
                Text(
                  'matchly.assistenza@gmail.com',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
