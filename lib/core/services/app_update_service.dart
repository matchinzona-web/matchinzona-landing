import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> checkForAppUpdate(BuildContext context) async {
  // Identifica la piattaforma.
  final String? platform;

  if (defaultTargetPlatform == TargetPlatform.android) {
    platform = 'android';
  } else if (defaultTargetPlatform == TargetPlatform.iOS) {
    platform = 'ios';
  } else {
    return;
  }

  try {
    // Legge la configurazione pubblicata su Supabase.
    final config = await Supabase.instance.client
        .from('app_update_config')
        .select('latest_version, min_supported_version, update_url, message')
        .eq('platform', platform)
        .maybeSingle();

    if (config == null || !context.mounted) return;

    final info = await PackageInfo.fromPlatform();

    if (!context.mounted) return;

    final versioneInstallata = info.version;
    final ultimaVersione = config['latest_version'] as String;
    final versioneMinima = config['min_supported_version'] as String;
    final linkAggiornamento = (config['update_url'] as String? ?? '').trim();
    final messaggio =
        config['message'] as String? ??
        'È disponibile una nuova versione di MatchInZona.';

    // Non mostra avvisi se manca il link per aggiornare.
    // Inserire il link corretto su Supabase prima di attivare
    // gli aggiornamenti obbligatori.
    final uriAggiornamento = Uri.tryParse(linkAggiornamento);

    if (uriAggiornamento == null ||
        !uriAggiornamento.hasScheme ||
        !['https', 'http'].contains(uriAggiornamento.scheme)) {
      return;
    }

    final aggiornamentoObbligatorio =
        _compareVersions(versioneInstallata, versioneMinima) < 0;

    final aggiornamentoDisponibile =
        _compareVersions(versioneInstallata, ultimaVersione) < 0;

    if (!aggiornamentoObbligatorio && !aggiornamentoDisponibile) {
      return;
    }

    // Per gli aggiornamenti facoltativi, controlla se l'utente
    // ha già scelto "Più tardi" per questa versione.
    if (!aggiornamentoObbligatorio) {
      final prefs = await SharedPreferences.getInstance();

      final chiaveVersioneRimandata = 'dismissed_optional_update_$platform';

      final versioneRimandata = prefs.getString(chiaveVersioneRimandata);

      if (versioneRimandata == ultimaVersione) {
        return;
      }
    }

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: !aggiornamentoObbligatorio,
      builder: (dialogContext) {
        return PopScope(
          canPop: !aggiornamentoObbligatorio,
          child: AlertDialog(
            title: Text(
              aggiornamentoObbligatorio
                  ? 'Aggiornamento necessario'
                  : 'Nuova versione disponibile',
            ),
            content: Text(
              aggiornamentoObbligatorio
                  ? 'Per continuare a utilizzare MatchInZona, '
                        'devi aggiornare l’app alla versione più recente.'
                  : messaggio,
            ),
            actions: [
              if (!aggiornamentoObbligatorio)
                TextButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();

                    await prefs.setString(
                      'dismissed_optional_update_$platform',
                      ultimaVersione,
                    );

                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: const Text('Più tardi'),
                ),

              FilledButton.icon(
                onPressed: () async {
                  try {
                    await launchUrl(
                      uriAggiornamento,
                      mode: LaunchMode.externalApplication,
                    );
                  } catch (_) {
                    // L'utente può riprovare il pulsante.
                  }
                },
                icon: const Icon(Icons.system_update_alt),
                label: const Text('Aggiorna ora'),
              ),
            ],
          ),
        );
      },
    );
  } catch (e, stackTrace) {
    // Un errore di rete non deve impedire l'apertura dell'app.
    debugPrint('Controllo aggiornamenti non riuscito: $e');
    debugPrintStack(stackTrace: stackTrace);
  }
}

int _compareVersions(String first, String second) {
  final a = RegExp(
    r'\d+',
  ).allMatches(first).map((match) => int.parse(match.group(0)!)).toList();

  final b = RegExp(
    r'\d+',
  ).allMatches(second).map((match) => int.parse(match.group(0)!)).toList();

  final length = a.length > b.length ? a.length : b.length;

  for (var i = 0; i < length; i++) {
    final partA = i < a.length ? a[i] : 0;
    final partB = i < b.length ? b[i] : 0;

    if (partA < partB) return -1;
    if (partA > partB) return 1;
  }

  return 0;
}
