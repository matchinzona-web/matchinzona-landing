import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_campi/core/theme/app_theme.dart';
import 'package:app_campi/features/auth/application/auth_provider.dart';
import 'package:app_campi/features/admin/presentation/pages/dashboard_gestore_page.dart';
import 'package:app_campi/features/admin/presentation/pages/attivazione_pagamenti_page.dart';
import 'package:app_campi/features/admin/presentation/pages/configurazione_orari.dart';
import 'package:app_campi/features/home/presentation/home_page.dart';
import 'package:app_campi/features/home/presentation/views/onboarding_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final utenteAsync = ref.watch(utenteCorrenteProvider);

    return utenteAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppTheme.darkBg,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.neonOrange),
        ),
      ),
      error: (err, stack) => const OnboardingScreen(),
      data: (utente) {
        if (utente == null) {
          return const OnboardingScreen();
        }

        // Se è un utente normale va alla Home
        if (!utente.isGestore) {
          return const HomePage();
        }

        // Se è un gestore, verifichiamo lo stato del suo account su Supabase
        return FutureBuilder<Map<String, dynamic>?>(
          future: Supabase.instance.client
              .from('societa')
              .select('id, piano_attuale, stripe_charges_enabled')
              .eq('id_utente', utente.id)
              .maybeSingle(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: AppTheme.darkBg,
                body: Center(
                  child: CircularProgressIndicator(color: AppTheme.neonOrange),
                ),
              );
            }

            final datiSocieta = snapshot.data;

            // 1. Se non ha una società o non ha un piano attivo
            if (datiSocieta == null ||
                datiSocieta['piano_attuale'] == null ||
                datiSocieta['piano_attuale'] == 'NESSUNO') {
              return const OnboardingScreen();
            }

            final String idSocieta = datiSocieta['id'];
            final bool chargesEnabled =
                datiSocieta['stripe_charges_enabled'] == true;

            // 2. GATE 1: Se non ha completato Stripe Connect, resta bloccato qui!
            if (!chargesEnabled) {
              return AttivazionePagamentiPage(idSocieta: idSocieta);
            }

            // 3. GATE 2: Accesso alla Dashboard solo se abilitato
            return DashboardGestore.fromLogin(utenteLoggato: utente);
          },
        );
      },
    );
  }
}
