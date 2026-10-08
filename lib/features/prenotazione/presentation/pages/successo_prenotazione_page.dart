import 'package:flutter/material.dart';
import 'package:app_campi/core/theme/app_theme.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_campi/features/chat/match_chat_page.dart';

class SuccessoPrenotazionePage extends StatelessWidget {
  final String idPartita;
  final String nomeCampo;
  final String nomeSocieta;
  final String sport;
  final DateTime data;
  final String ora;
  final bool isPrivata;

  const SuccessoPrenotazionePage({
    super.key,
    required this.idPartita,
    required this.nomeCampo,
    required this.nomeSocieta,
    required this.sport,
    required this.data,
    required this.ora,
    required this.isPrivata,
  });

  String _emojiSport(String sport) {
    final valore = sport.trim().toLowerCase();

    if (valore.startsWith('calcio_')) return '⚽';
    if (valore == 'basket') return '🏀';
    if (valore == 'pallavolo' || valore == 'volley') return '🏐';
    if (valore == 'tennis_singolo' || valore == 'tennis_doppio') return '🎾';
    if (valore == 'padel') return '🎾';

    return '🏟️';
  }

  @override
  Widget build(BuildContext context) {
    final dataFormattata = "${data.day}/${data.month}/${data.year}";

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.neonGreen.withOpacity(0.1),
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: AppTheme.neonGreen,
                  size: 72,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "MATCH CONFERMATO!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isPrivata
                    ? "Hai prenotato $nomeCampo\npresso $nomeSocieta\nil $dataFormattata alle $ora."
                    : "Hai aperto un match presso\n$nomeSocieta\nil $dataFormattata alle $ora.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.testoSecondario,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              Container(
                padding: const EdgeInsets.all(24),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isPrivata
                        ? AppTheme.neonOrange.withOpacity(0.15)
                        : AppTheme.neonCyan.withOpacity(0.15),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isPrivata ? AppTheme.neonOrange : AppTheme.neonCyan)
                              .withOpacity(0.05),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            (isPrivata
                                    ? AppTheme.neonOrange
                                    : AppTheme.neonCyan)
                                .withOpacity(0.1),
                      ),
                      child: Icon(
                        isPrivata
                            ? Icons.lock_person_rounded
                            : Icons.hub_rounded,
                        color: isPrivata
                            ? AppTheme.neonOrange
                            : AppTheme.neonCyan,
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isPrivata ? "PRENOTAZIONE PRIVATA" : "MATCHMAKING ATTIVO",
                      style: TextStyle(
                        color: isPrivata
                            ? AppTheme.neonOrange
                            : AppTheme.neonCyan,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    isPrivata
                        ? Text.rich(
                            const TextSpan(
                              text:
                                  "Il campo è riservato esclusivamente a te e ai tuoi amici. Potrai disdire la prenotazione fino a 30 minuti prima dell'inizio della partita. Buona partita bomber ",
                              children: [
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: Icon(
                                    Icons.local_fire_department_rounded,
                                    color: AppTheme.neonOrange,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          )
                        : Text(
                            "Altri giocatori potranno iscriversi al match. Se il match non raggiunge il numero necessario entro 2 ore dall'inizio, verrà annullato. Se il campo viene prenotato per intero, il match verrà annullato.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // BOTTONE CHAT

              // BOTTONE CHAT (Visibile solo se NON è privata)
              if (!isPrivata) ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonCyan,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text(
                    "APRI CHAT DI GRUPPO",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MatchChatPage(
                          matchId: idPartita,
                          nomeSocieta: nomeSocieta,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],

              // BOTTONE CONDIVIDI WHATSAPP
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  side: const BorderSide(color: AppTheme.neonGreen, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  foregroundColor: AppTheme.neonGreen,
                ),
                icon: const Icon(Icons.share),
                label: const Text(
                  "INVITA AMICI SU WHATSAPP",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                onPressed: () async {
                  final emoji = _emojiSport(sport);
                  final String testoMessaggio = isPrivata
                      ? "$emoji Ho prenotato *$nomeCampo* presso *$nomeSocieta*\n"
                            "📅 $dataFormattata alle $ora\n\n"
                            "Ci vediamo in campo!"
                      : "$emoji *CERCHIAMO GIOCATORI!*\n\n"
                            "Ho aperto un match su MatchInZona presso:\n"
                            "🏟️ *$nomeSocieta*\n"
                            "📅 $dataFormattata alle $ora\n\n"
                            "Unisciti alla partita su MatchInZona!";

                  final urlAndroid =
                      "whatsapp://send?text=${Uri.encodeComponent(testoMessaggio)}";
                  final urlIos =
                      "https://wa.me/?text=${Uri.encodeComponent(testoMessaggio)}";

                  final String urlFinale = Platform.isAndroid
                      ? urlAndroid
                      : urlIos;
                  final Uri uri = Uri.parse(urlFinale);

                  try {
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    } else {
                      final webUri = Uri.parse(
                        "https://wa.me/?text=${Uri.encodeComponent(testoMessaggio)}",
                      );
                      await launchUrl(
                        webUri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Impossibile aprire WhatsApp automaticamente.",
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 12),

              TextButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text(
                  "Torna alla Home",
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
