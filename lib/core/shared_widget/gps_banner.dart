import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:app_campi/core/theme/app_theme.dart';
import 'package:app_campi/core/theme/app_constants.dart';
import 'package:app_campi/core/services/location_provider.dart';

class GpsBanner extends ConsumerStatefulWidget {
  const GpsBanner({super.key});

  @override
  ConsumerState<GpsBanner> createState() => _GpsBannerState();
}

class _GpsBannerState extends ConsumerState<GpsBanner>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(gpsAttivoProvider);
      ref.invalidate(permessoPosizioneProvider);
      ref.invalidate(posizioneAttualeProvider);
      ref.invalidate(matchInZonaProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gpsState = ref.watch(gpsAttivoProvider);
    final permessoState = ref.watch(permessoPosizioneProvider);

    return gpsState.when(
      data: (isGpsAttivo) {
        final permission = permessoState.value ?? LocationPermission.denied;

        final bool permessoConcesso =
            permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always;

        final bool negatoPerSempre =
            permission == LocationPermission.deniedForever;

        if (isGpsAttivo && permessoConcesso) {
          return const SizedBox.shrink();
        }

        final String titolo;
        final String sottotitolo;
        final IconData icona;
        final String etichettaBottone;
        final VoidCallback azione;

        if (!isGpsAttivo) {
          titolo = "GPS DISATTIVATO";
          sottotitolo =
              "Attiva la posizione per vedere centri, distanze e match vicino a te.";
          icona = Icons.location_off;
          etichettaBottone = "ATTIVA";

          azione = () {
            Geolocator.openLocationSettings();
          };
        } else if (negatoPerSempre) {
          titolo = "POSIZIONE NON CONSENTITA";
          sottotitolo =
              "La posizione è facoltativa. Puoi abilitarla dalle impostazioni per usare le funzioni vicino a te.";
          icona = Icons.gps_off_rounded;
          etichettaBottone = "IMPOSTAZIONI";

          azione = () {
            Geolocator.openAppSettings();
          };
        } else {
          titolo = "ATTIVA LE FUNZIONI VICINO A TE";
          sottotitolo =
              "La posizione è facoltativa. Consentila per vedere distanze, centri e match nella tua zona.";
          icona = Icons.location_on_outlined;
          etichettaBottone = "CONSENTI";

          azione = () async {
            final nuovoPermesso = await richiediPermessoPosizione();

            ref.invalidate(permessoPosizioneProvider);
            ref.invalidate(posizioneAttualeProvider);

            if (nuovoPermesso == LocationPermission.whileInUse ||
                nuovoPermesso == LocationPermission.always) {
              ref.invalidate(matchInZonaProvider);
              return;
            }

            if (nuovoPermesso == LocationPermission.deniedForever) {
              await Geolocator.openAppSettings();
            }
          };
        }

        return Container(
          margin: const EdgeInsets.only(
            left: AppSpacing.screenPadding,
            right: AppSpacing.screenPadding,
            bottom: 16,
          ),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.statoErrore.withOpacity(0.10),
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: AppTheme.statoErrore.withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.statoErrore.withOpacity(0.16),
                ),
                child: Icon(icona, color: AppTheme.statoErrore, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titolo,
                      style: const TextStyle(
                        color: AppTheme.statoErrore,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sottotitolo,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: azione,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.statoErrore,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.chip ?? 10),
                  ),
                ),
                child: Text(
                  etichettaBottone,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
