import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_campi/core/theme/app_theme.dart';
import 'package:app_campi/core/utils/connessione_provider.dart';

class ConnessioneAssenteOverlay extends ConsumerWidget {
  const ConnessioneAssenteOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connessione = ref.watch(connessioneProvider);

    return connessione.when(
      data: (connesso) {
        if (connesso) {
          return const SizedBox.shrink();
        }

        return Material(
          color: AppTheme.darkBg,
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.accent.withOpacity(0.10),
                      ),
                      child: const Icon(
                        Icons.wifi_off_rounded,
                        size: 58,
                        color: AppTheme.accent,
                      ),
                    ),

                    const SizedBox(height: 32),

                    const Text(
                      'Non è stato possibile connettersi',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Controlla la tua connessione internet e riprova.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ref.invalidate(connessioneProvider);
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text(
                          'RIPROVA',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },

      loading: () => const SizedBox.shrink(),

      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
