import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_campi/core/theme/app_theme.dart';
import 'package:app_campi/features/notifiche/application/notifiche_provider.dart';

class NotifichePage extends ConsumerStatefulWidget {
  const NotifichePage({super.key});

  @override
  ConsumerState<NotifichePage> createState() => _NotifichePageState();
}

class _NotifichePageState extends ConsumerState<NotifichePage> {
  final Set<String> _notificheAppenaLette = {};
  final Set<String> _notificheEliminate = {};
  final Set<String> _notificheEspande = {};

  String _formattaData(DateTime data) {
    final diff = DateTime.now().difference(data);
    if (diff.inMinutes < 60) return "${diff.inMinutes}m fa";
    if (diff.inHours < 24) return "${diff.inHours}h fa";
    return "${data.day}/${data.month}";
  }

  Future<void> _segnaComeLetta(String id) async {
    setState(() => _notificheAppenaLette.add(id));
    try {
      await Supabase.instance.client
          .from('notifiche')
          .update({'letto': true})
          .eq('id', id);

      ref.invalidate(notificheStreamProvider);
    } catch (e) {
      debugPrint("Errore segna come letta: $e");
    }
  }

  Future<void> _segnaTutteComeLette() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) return;

    try {
      await Supabase.instance.client
          .from('notifiche')
          .update({'letto': true})
          .eq('id_utente', userId)
          .eq('letto', false);

      if (!mounted) return;

      setState(() {
        _notificheAppenaLette.clear();
      });

      ref.invalidate(notificheStreamProvider);
    } catch (e) {
      debugPrint('Errore segna tutte come lette: $e');
    }
  }

  Future<void> _eliminaNotifica(String idNotifica) async {
    try {
      await Supabase.instance.client
          .from('notifiche')
          .delete()
          .eq('id', idNotifica);

      ref.invalidate(notificheStreamProvider);
    } catch (e) {
      debugPrint("Errore eliminazione notifica: $e");
    }
  }

  IconData _getIconaTipo(String? tipo) {
    switch (tipo) {
      case 'completa':
      case 'match_completo':
        return Icons.check_circle_rounded;
      case 'aperta_a_rischio':
      case 'match_a_rischio':
        return Icons.warning_rounded;
      case 'annullata':
      case 'match_annullato':
        return Icons.cancel_rounded;
      case 'giocatore_unito':
        return Icons.person_add_alt_1_rounded;
      case 'giocatore_abbandonato':
        return Icons.person_remove_alt_1_rounded;
      case 'prenotazione_gestore':
        return Icons.event_available_rounded;

      case 'prenotazione_annullata_gestore':
        return Icons.event_busy_rounded;
      case 'invito_torneo':
        return Icons.military_tech_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getColoreTipo(String? tipo) {
    switch (tipo) {
      case 'completa':
      case 'match_completo':
        return AppTheme.statoSuccesso;
      case 'aperta_a_rischio':
      case 'match_a_rischio':
      case 'annullata':
      case 'match_annullato':
        return AppTheme.statoErrore;
      case 'giocatore_unito':
        return AppTheme.accent;
      case 'giocatore_abbandonato':
        return AppTheme.statoAttenzione;
      case 'prenotazione_gestore':
        return AppTheme.statoSuccesso;

      case 'prenotazione_annullata_gestore':
        return AppTheme.statoErrore;
      case 'invito_torneo':
        return AppTheme.neonPurple;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificheAsync = ref.watch(notificheStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      extendBodyBehindAppBar: true,
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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: 8,
                    right: 20,
                    top: 12,
                    bottom: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppTheme.textPrimary,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 4),

                      Expanded(
                        child: Text(
                          "CENTRO NOTIFICHE",
                          style: TextStyle(
                            color: AppTheme.textSecondary.withOpacity(0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),

                      TextButton(
                        onPressed: _segnaTutteComeLette,
                        child: const Text(
                          "SEGNA TUTTE",
                          style: TextStyle(
                            color: AppTheme.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: notificheAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: AppTheme.accent),
                    ),
                    error: (err, stack) {
                      debugPrint('ERRORE NOTIFICHE STREAM: $err');
                      debugPrint('STACK NOTIFICHE: $stack');

                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.accent.withOpacity(0.10),
                                ),
                                child: const Icon(
                                  Icons.wifi_off_rounded,
                                  size: 52,
                                  color: AppTheme.accent,
                                ),
                              ),

                              const SizedBox(height: 28),

                              const Text(
                                'Non è stato possibile connettersi',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),

                              const SizedBox(height: 10),

                              const Text(
                                'Controlla la tua connessione internet e riprova.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),

                              const SizedBox(height: 28),

                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    ref.invalidate(notificheStreamProvider);
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
                      );
                    },
                    data: (notifiche) {
                      final notificheVisibili = notifiche
                          .where((n) => !_notificheEliminate.contains(n.id))
                          .toList();

                      if (notificheVisibili.isEmpty) {
                        return _buildEmptyState(context);
                      }

                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        itemCount: notificheVisibili.length,
                        itemBuilder: (context, index) {
                          final n = notificheVisibili[index];
                          final isLetta =
                              n.letto || _notificheAppenaLette.contains(n.id);

                          return _buildNotificaCard(n, isLetta);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.textPrimary.withOpacity(0.04),
              ),
              child: const Icon(
                Icons.notifications_off_rounded,
                size: 60,
                color: AppTheme.textDisabled,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Nessuna notifica",
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Tutto tranquillo! Quando ci saranno nuovi aggiornamenti, li troverai qui.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textPrimary,
                  side: const BorderSide(color: AppTheme.cardBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text(
                  "TORNA INDIETRO",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificaCard(var n, bool isLetta) {
    final color = _getColoreTipo(n.tipo);
    final bool isEspansa = _notificheEspande.contains(n.id);

    return Dismissible(
      key: Key(n.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        setState(() => _notificheEliminate.add(n.id));
        _eliminaNotifica(n.id);
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.statoErrore.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.statoErrore.withOpacity(0.3)),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete_sweep_rounded,
          color: AppTheme.statoErrore,
        ),
      ),
      child: GestureDetector(
        onTap: () {
          if (!isLetta) {
            _segnaComeLetta(n.id);
          }

          setState(() {
            if (isEspansa) {
              _notificheEspande.remove(n.id);
            } else {
              _notificheEspande.add(n.id);
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isLetta ? AppTheme.cardBg : color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLetta ? AppTheme.cardBorder : color.withOpacity(0.4),
              width: isLetta ? 1 : 1.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isLetta
                      ? AppTheme.textPrimary.withOpacity(0.05)
                      : color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIconaTipo(n.tipo),
                  color: isLetta ? AppTheme.textDisabled : color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            n.titolo,
                            style: TextStyle(
                              color: isLetta
                                  ? AppTheme.textPrimary
                                  : Colors.white,
                              fontWeight: isLetta
                                  ? FontWeight.w600
                                  : FontWeight.w900,
                              fontSize: 15,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formattaData(n.createdAt),
                          style: TextStyle(
                            color: isLetta
                                ? AppTheme.textDisabled
                                : AppTheme.textSecondary,
                            fontSize: 11,
                            fontWeight: isLetta
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      child: Text(
                        n.messaggio,
                        style: TextStyle(
                          color: isLetta
                              ? AppTheme.textDisabled
                              : AppTheme.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                        maxLines: isEspansa ? null : 3,
                        overflow: isEspansa
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 6),

                    Align(
                      alignment: Alignment.centerRight,
                      child: Icon(
                        isEspansa
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.textDisabled,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLetta)
                Container(
                  margin: const EdgeInsets.only(left: 12, top: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
