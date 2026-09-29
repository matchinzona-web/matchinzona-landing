import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_campi/features/notifiche/application/notifiche_provider.dart';
import 'package:app_campi/core/theme/app_theme.dart';
import 'package:app_campi/features/notifiche/presentation/pages/notifiche_page.dart';
import 'package:app_campi/features/home/presentation/widgets/glow_pill_button.dart';
import 'package:app_campi/features/notifiche/presentation/widget/notifiche_bell.dart';
import 'package:app_campi/features/home/presentation/widgets/auth_bottom_sheet.dart';
import 'package:app_campi/core/models/utente.dart';

class HomeAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final Utente? utenteLoggato;

  const HomeAppBar({super.key, required this.utenteLoggato});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificheAsync = ref.watch(notificheStreamProvider);

    return AppBar(
      backgroundColor: AppTheme.darkBg,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.accent,
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Text(
              "AC",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 11,
                color: AppTheme.darkBg,
              ),
            ),
          ),
          const SizedBox(width: 9),
          const Text(
            'AppCampi',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
      centerTitle: false,
      actions: [
        if (utenteLoggato == null)
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GlowPillButton(
              label: "Accedi",
              icon: Icons.person_outline,
              color: AppTheme.accent,
              onTap: () => showAuthBottomSheet(context),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: notificheAsync.when(
              data: (notifiche) {
                final nonLette = notifiche.where((n) => !n.letto).length;
                return NotificheBell(
                  count: nonLette,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotifichePage()),
                  ),
                );
              },
              loading: () => const IconButton(
                icon: Icon(
                  Icons.notifications_none,
                  color: AppTheme.textSecondary,
                  size: 28,
                ),
                onPressed: null,
              ),
              error: (_, _) => const IconButton(
                icon: Icon(
                  Icons.error_outline,
                  color: AppTheme.statoErrore,
                  size: 28,
                ),
                onPressed: null,
              ),
            ),
          ),
      ],
    );
  }
}
