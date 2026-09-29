import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_campi/features/auth/presentation/pages/login_utente.dart';
import 'package:app_campi/features/auth/presentation/pages/registrazione_utente.dart';
import 'package:app_campi/features/profilo/presentation/pages/modifica_profilo.dart';
import 'package:app_campi/features/admin/presentation/pages/piani_abbonamento.dart';
import 'package:app_campi/core/theme/app_theme.dart';

import 'package:app_campi/features/auth/application/auth_provider.dart';
import 'package:app_campi/features/profilo/application/auth_controller.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfiloUtente extends ConsumerWidget {
  const ProfiloUtente({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supabase = Supabase.instance.client;
    final utenteLoggato = ref.watch(utenteCorrenteProvider).value;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,

      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accent.withOpacity(0.05),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          SafeArea(
            child: StreamBuilder<AuthState>(
              stream: supabase.auth.onAuthStateChange,
              builder: (context, snapshot) {
                final session =
                    snapshot.data?.session ?? supabase.auth.currentSession;
                final isLogged = session != null;

                if (isLogged) {
                  return _buildProfiloLoggato(
                    context,
                    ref,
                    session.user,
                    utenteLoggato,
                  );
                } else {
                  return _buildProfiloOspite(context);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _apriUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);

    try {
      final aperto = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!aperto && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossibile aprire il collegamento.'),
            backgroundColor: AppTheme.statoErrore,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossibile aprire il collegamento.'),
          backgroundColor: AppTheme.statoErrore,
        ),
      );
    }
  }

  Future<void> _contattaAssistenza(
    BuildContext context, {
    bool segnalaProblema = false,
  }) async {
    final subject = segnalaProblema
        ? 'Segnalazione problema Matchly'
        : 'Assistenza Matchly';

    final uri = Uri(
      scheme: 'mailto',
      path: 'matchly.assistenza@gmail.com',
      queryParameters: {'subject': subject},
    );

    try {
      final aperto = await launchUrl(uri);

      if (!aperto && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Non è stato possibile aprire l’app email.'),
            backgroundColor: AppTheme.statoErrore,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Non è stato possibile aprire l’app email.'),
          backgroundColor: AppTheme.statoErrore,
        ),
      );
    }
  }

  Widget _buildProfiloOspite(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.fingerprint_rounded,
              size: 50,
              color: Colors.white24,
            ),
            const SizedBox(height: 24),
            const Text(
              'Benvenuto in Matchly',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Seleziona il tuo profilo per continuare.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 40),

            AnimatedRuoloCard(
              titolo: 'Sono un Giocatore',
              descrizione: 'Prenota campi, trova compagni e gioca.',
              icona: Icons.sports_soccer_rounded,
              coloreAccento: AppTheme.neonGreen,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const RegistrazioneUtente(),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            AnimatedRuoloCard(
              titolo: 'Gestisco un Centro',
              descrizione: 'Digitalizza il tuo impianto e ricevi prenotazioni.',
              icona: Icons.stadium_rounded,
              coloreAccento: AppTheme.neonPurple,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PianiAbbonamentoScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Hai già un account?',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const LoginUtente(),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    splashFactory: NoSplash.splashFactory,
                  ),
                  child: const Text(
                    'Accedi ora',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            Wrap(
              alignment: WrapAlignment.center,
              spacing: 4,
              runSpacing: 0,
              children: [
                TextButton(
                  onPressed: () => _apriUrl(
                    context,
                    'https://matchlyassistenza-web.github.io/matchly-privacy/',
                  ),
                  child: const Text(
                    'Privacy Policy',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
                TextButton(
                  onPressed: () => _apriUrl(
                    context,
                    'https://matchlyassistenza-web.github.io/matchly-privacy/termini.html',
                  ),
                  child: const Text(
                    'Termini e Condizioni',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
                TextButton(
                  onPressed: () => _contattaAssistenza(context),
                  child: const Text(
                    'Assistenza',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
                TextButton(
                  onPressed: () => _apriUrl(
                    context,
                    'https://matchlyassistenza-web.github.io/matchly-privacy/elimina-account.html',
                  ),
                  child: const Text(
                    'Eliminazione account',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildProfiloLoggato(
    BuildContext context,
    WidgetRef ref,
    User user,
    var utenteLoggato,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 20.0,
        right: 20.0,
        top: 32.0,
        bottom: 24.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              "IL TUO PROFILO",
              style: TextStyle(
                color: AppTheme.textSecondary.withOpacity(0.8),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.accent.withOpacity(0.2),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accent.withOpacity(0.15),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 34,
                    backgroundColor: AppTheme.darkBg,
                    child: Text(
                      user.email != null && user.email!.isNotEmpty
                          ? user.email![0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bentornato!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        utenteLoggato?.nome ?? 'Caricamento...',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email ?? 'Email non disponibile',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          const Padding(
            padding: EdgeInsets.only(left: 8.0, bottom: 16),
            child: Text(
              "IMPOSTAZIONI",
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),

          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                _buildMenuTile(
                  icon: Icons.manage_accounts_outlined,
                  iconColor: AppTheme.accent,
                  title: 'Dati Profilo',
                  subtitle: 'Modifica informazioni e password',
                  onTap: () {
                    if (utenteLoggato != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              ModificaProfiloScreen(utente: utenteLoggato),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Caricamento dati in corso... riprova.',
                          ),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 20),

                const Padding(
                  padding: EdgeInsets.only(left: 8, bottom: 12),
                  child: Text(
                    'PRIVACY E LEGALE',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),

                _buildMenuTile(
                  icon: Icons.privacy_tip_outlined,
                  iconColor: AppTheme.neonGreen,
                  title: 'Privacy Policy',
                  subtitle: 'Come vengono trattati i tuoi dati',
                  onTap: () => _apriUrl(
                    context,
                    'https://matchlyassistenza-web.github.io/matchly-privacy/',
                  ),
                ),

                _buildMenuTile(
                  icon: Icons.description_outlined,
                  iconColor: AppTheme.neonPurple,
                  title: 'Termini e Condizioni',
                  subtitle: 'Consulta le condizioni di utilizzo',
                  onTap: () => _apriUrl(
                    context,
                    'https://matchlyassistenza-web.github.io/matchly-privacy/termini.html',
                  ),
                ),

                _buildMenuTile(
                  icon: Icons.delete_outline_rounded,
                  iconColor: AppTheme.statoErrore,
                  title: 'Eliminazione account e dati',
                  subtitle: 'Informazioni sulla cancellazione dei dati',
                  onTap: () => _apriUrl(
                    context,
                    'https://matchlyassistenza-web.github.io/matchly-privacy/elimina-account.html',
                  ),
                ),

                const SizedBox(height: 20),

                const Padding(
                  padding: EdgeInsets.only(left: 8, bottom: 12),
                  child: Text(
                    'ASSISTENZA',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),

                _buildMenuTile(
                  icon: Icons.support_agent_rounded,
                  iconColor: AppTheme.accent,
                  title: 'Contatta assistenza',
                  subtitle: 'Scrivici per domande o richieste',
                  onTap: () => _contattaAssistenza(context),
                ),

                _buildMenuTile(
                  icon: Icons.bug_report_outlined,
                  iconColor: Colors.amber,
                  title: 'Segnala un problema',
                  subtitle: 'Aiutaci a migliorare Matchly',
                  onTap: () =>
                      _contattaAssistenza(context, segnalaProblema: true),
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(18),
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
                          color: AppTheme.accent,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Trova. Prenota. Gioca.',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Assistenza: matchly.assistenza@gmail.com',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confermaLogout(context, ref),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.statoErrore,
                side: BorderSide(
                  color: AppTheme.statoErrore.withOpacity(0.3),
                  width: 1.5,
                ),
                backgroundColor: AppTheme.statoErrore.withOpacity(0.05),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.logout, size: 22),
              label: const Text(
                'DISCONNETTI',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required Color iconColor,
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
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
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
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
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
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.white24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confermaLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.cardBorder),
        ),
        title: const Text(
          "Esci dall'account",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Sei sicuro di voler uscire? Dovrai effettuare nuovamente l'accesso.",
          style: TextStyle(color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              "Annulla",
              style: TextStyle(
                color: Colors.white54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.statoErrore,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text(
              "Esci",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref.read(authControllerProvider).logout();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.statoSuccesso,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: const Text(
            'Disconnessione effettuata con successo.',
            style: TextStyle(
              color: AppTheme.darkBg,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.statoErrore,
          content: Text(
            'Errore durante la disconnessione',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
  }
}

class AnimatedRuoloCard extends StatefulWidget {
  final String titolo;
  final String descrizione;
  final IconData icona;
  final Color coloreAccento;
  final VoidCallback onTap;

  const AnimatedRuoloCard({
    super.key,
    required this.titolo,
    required this.descrizione,
    required this.icona,
    required this.coloreAccento,
    required this.onTap,
  });

  @override
  State<AnimatedRuoloCard> createState() => _AnimatedRuoloCardState();
}

class _AnimatedRuoloCardState extends State<AnimatedRuoloCard>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        Future.delayed(const Duration(milliseconds: 150), widget.onTap);
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF16161E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isPressed
                  ? widget.coloreAccento.withOpacity(0.5)
                  : Colors.white.withOpacity(0.05),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: _isPressed ? 10 : 25,
                offset: Offset(0, _isPressed ? 5 : 12),
              ),
              if (_isPressed)
                BoxShadow(
                  color: widget.coloreAccento.withOpacity(0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.coloreAccento.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icona,
                  color: widget.coloreAccento,
                  size: 28,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.titolo,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.descrizione,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withOpacity(0.2),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
