import 'package:flutter/material.dart';
import 'package:app_campi/core/theme/app_theme.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_campi/features/chat/match_chat_page.dart';

class SuccessoPrenotazionePage extends StatelessWidget {
  final String idPartita;
  final String nomeCampo;
  final DateTime data;
  final String ora;
  final bool isPrivata;

  const SuccessoPrenotazionePage({
    super.key,
    required this.idPartita,
    required this.nomeCampo,
    required this.data,
    required this.ora,
    required this.isPrivata,
  });

  @override
  Widget build(BuildContext context) {
    final dataFormattata = "${data.day}/${data.month}/${data.year}";

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.neonGreen.withOpacity(0.1),
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: AppTheme.neonGreen,
                  size: 100,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                "MATCH CONFERMATO!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Hai prenotato $nomeCampo\nil $dataFormattata alle $ora.",
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
                                  "Il campo è riservato esclusivamente a te e ai tuoi amici. Buona partita bomber ",
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
                            "La partita è visibile nella bacheca pubblica! Chiunque potrà iscriversi per aiutarti a raggiungere il numero minimo.",
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
              const Spacer(),

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
                          nomeCampo: nomeCampo,
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
                  final String testoMessaggio = isPrivata
                      ? "Grande! Ho prenotato il campo *$nomeCampo* per il giorno *$dataFormattata* alle ore *$ora*. Ci vediamo in campo! ⚽"
                      : "Chi scende in campo? ⚽ Ho aperto un match su *$nomeCampo* il *$dataFormattata* alle *$ora*. Unisciti alla partita dall'app per bloccare lo slot!";

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
