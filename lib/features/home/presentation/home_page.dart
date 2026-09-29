import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_campi/features/auth/application/auth_provider.dart';
import 'package:app_campi/features/miei_match/presentation/pages/miei_match.dart';
import 'package:app_campi/features/profilo/presentation/pages/profilo_utente.dart';
import 'package:app_campi/features/home/presentation/widgets/radar_map_screen.dart';
import 'package:app_campi/core/theme/app_theme.dart';
import 'package:geolocator/geolocator.dart';

import 'package:app_campi/features/home/presentation/views/home_tab.dart';
import 'package:app_campi/features/home/presentation/widgets/nav_item.dart';
import 'package:app_campi/core/models/utente.dart';
import 'package:app_campi/core/services/location_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  final int initialIndex;

  const HomePage({super.key, this.initialIndex = 0});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late int _indiceSelezionato;

  @override
  void initState() {
    super.initState();

    _indiceSelezionato = widget.initialIndex;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final permission = await richiediPermessoPosizionePrimaVolta();

      if (!mounted) return;

      ref.invalidate(permessoPosizioneProvider);
      ref.invalidate(posizioneAttualeProvider);

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        ref.invalidate(matchInZonaProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Utente?> utenteAsyncValue = ref.watch(
      utenteCorrenteProvider,
    );

    final utente = utenteAsyncValue.value;
    final bool isOspite = utente == null;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      extendBody: true,

      body: IndexedStack(
        index: _indiceSelezionato,
        children: [
          HomeTab(utenteAsyncValue: utenteAsyncValue),
          const RadarMapScreen(),

          MieiMatch(utenteLoggato: utente),
          const ProfiloUtente(),
        ],
      ),

      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.darkBg.withOpacity(0.85),
            border: const Border(top: BorderSide(color: AppTheme.cardBorder)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                NavItem(
                  icon: Icons.home_filled,
                  label: 'HOME',
                  selected: _indiceSelezionato == 0,
                  color: AppTheme.accent,
                  onTap: () => setState(() => _indiceSelezionato = 0),
                ),
                NavItem(
                  icon: Icons.radar,
                  label: 'RADAR',
                  selected: _indiceSelezionato == 1,
                  color: AppTheme.accent,
                  onTap: () => setState(() => _indiceSelezionato = 1),
                ),
                NavItem(
                  icon: Icons.event_note,
                  label: 'MATCH',
                  selected: _indiceSelezionato == 2,
                  color: AppTheme.accent,
                  onTap: () => setState(() => _indiceSelezionato = 2),
                ),
                NavItem(
                  icon: Icons.person,
                  label: 'PROFILO',
                  selected: _indiceSelezionato == 3,
                  color: AppTheme.accent,
                  onTap: () => setState(() => _indiceSelezionato = 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
