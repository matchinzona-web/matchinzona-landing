import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_campi/core/theme/app_theme.dart';
import 'package:app_campi/features/notifiche/presentation/pages/notifiche_page.dart';
import 'package:app_campi/features/notifiche/application/notifiche_provider.dart';
import 'package:app_campi/core/services/push_notification_service.dart';
import 'package:app_campi/core/models/utente.dart';
import 'package:app_campi/core/services/campi_service.dart';
import 'package:app_campi/features/admin/application/dashboard_provider.dart';
import 'package:app_campi/features/admin/presentation/pages/aggiungi_campo_page.dart';
import 'package:app_campi/features/admin/presentation/widgets/dettagli_prenotazione_dialog.dart';
import 'package:app_campi/features/admin/presentation/widgets/widget_calendario_gestore.dart';
import 'package:app_campi/features/admin/presentation/pages/chiusure_straordinarie.dart';
import 'package:app_campi/features/profilo/presentation/pages/profilo_gestore.dart';
import 'package:app_campi/features/admin/presentation/pages/statistiche_guadagni.dart';
import 'package:app_campi/features/admin/presentation/pages/modifica_orari.dart';
import 'package:app_campi/features/admin/presentation/pages/schermata_abbonamento.dart';
import 'package:app_campi/features/admin/presentation/pages/attivazione_pagamenti_page.dart';
import 'package:app_campi/features/admin/presentation/pages/prenotazione_manuale_page.dart';
import 'package:app_campi/features/admin/presentation/pages/privacy_assistenza_gestore.dart';

class DashboardGestore extends ConsumerStatefulWidget {
  final Utente? utenteLoggato;
  final String? idSocieta;

  const DashboardGestore({
    super.key,
    this.utenteLoggato,
    required this.idSocieta,
  });

  const DashboardGestore.fromLogin({super.key, required this.utenteLoggato})
    : idSocieta = null;

  @override
  ConsumerState<DashboardGestore> createState() => _DashboardGestoreState();
}

class _DashboardGestoreState extends ConsumerState<DashboardGestore> {
  final CalendarController _calendarController = CalendarController();
  final ScrollController _scrollController = ScrollController();
  late final DashboardNotifier _dashboardNotifier;
  DateTime get _oggi {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime get _dataMassimaCalendario {
    return _oggi.add(const Duration(days: 13));
  }

  @override
  void initState() {
    super.initState();

    // Salviamo il notifier mentre il widget è sicuramente attivo.
    _dashboardNotifier = ref.read(dashboardProvider.notifier);

    Future.microtask(() async {
      if (!mounted) return;

      await _dashboardNotifier.inizializza(
        idSocieta: widget.idSocieta,
        utenteLoggato: widget.utenteLoggato,
      );

      if (!mounted) return;

      _dashboardNotifier.avviaRealtimePartite(
        idSocieta: widget.idSocieta,
        utenteLoggato: widget.utenteLoggato,
      );
    });
  }

  @override
  void dispose() {
    _dashboardNotifier.cancellaRealtime();
    _calendarController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _gestisciClickCalendario(CalendarTapDetails details) {
    final datiPartiteRaw = ref.read(dashboardProvider).datiPartiteRaw;
    if (details.targetElement == CalendarElement.appointment &&
        details.appointments != null &&
        details.appointments!.isNotEmpty) {
      final Appointment app = details.appointments!.first;

      if (app.subject == '⛔ CHIUSO' || app.subject == '⛔ GIORNO DI CHIUSURA') {
        return;
      }

      // 🟢 Cerca l'ID sia da app.id che da app.notes
      final String idCercato = (app.notes ?? app.id ?? '').toString();

      final partitaRaw = datiPartiteRaw.firstWhere(
        (p) => p['id'].toString() == idCercato,
        orElse: () => <String, dynamic>{},
      );

      if (partitaRaw.isNotEmpty) {
        showDialog(
          context: context,
          builder: (context) => DettagliPrenotazioneDialog(partita: partitaRaw),
        );
      }
    }
  }

  void _tentaAggiuntaCampo() {
    final state = ref.read(dashboardProvider);
    if (state.actualIdSocieta == null) return;
    if (state.campi.length >= state.limiteCampiConsentiti) {
      _mostraDialogUpsell();
    } else {
      _vaiAdAggiungiCampo();
    }
  }

  Future<void> _vaiAdAggiungiCampo() async {
    final actualIdSocieta = ref.read(dashboardProvider).actualIdSocieta;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AggiungiCampo(idSocieta: actualIdSocieta!),
      ),
    );

    if (!mounted) return;

    await _dashboardNotifier.inizializza(
      idSocieta: widget.idSocieta,
      utenteLoggato: widget.utenteLoggato,
    );
  }

  void _mostraDialogUpsell() {
    final state = ref.read(dashboardProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppTheme.neonOrange, width: 2),
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.rocket_launch, color: AppTheme.neonOrange),
            SizedBox(width: 10),
            Text(
              'Limite Raggiunto',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Hai raggiunto il limite massimo di campi previsti dal tuo piano attuale (${state.limiteCampiConsentiti} campi).\n\nVuoi espandere il tuo centro sportivo? Esegui l\'upgrade al piano superiore!',
          style: TextStyle(
            color: Colors.grey.shade300,
            fontSize: 15,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neonOrange,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              if (state.actualIdSocieta != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SchermataAbbonamento(idSocieta: state.actualIdSocieta!),
                  ),
                ).then((_) async {
                  if (!mounted) return;

                  await _dashboardNotifier.inizializza(
                    idSocieta: widget.idSocieta,
                    utenteLoggato: widget.utenteLoggato,
                  );
                });
              }
            },
            child: const Text(
              'Esegui Upgrade',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _mostraDialogCampoBloccato() {
    final state = ref.read(dashboardProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppTheme.neonOrange, width: 2),
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.lock_reset_rounded, color: AppTheme.neonOrange),
            SizedBox(width: 10),
            Text(
              'Campo Sospeso',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Questo campo è temporaneamente bloccato perché hai effettuato il downgrade del tuo abbonamento.\n\nSe vuoi riattivarlo e ricominciare a gestire le prenotazioni su questa struttura, effettua l\'upgrade del piano!',
          style: TextStyle(
            color: Colors.grey.shade300,
            fontSize: 15,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neonOrange,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              if (state.actualIdSocieta != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SchermataAbbonamento(idSocieta: state.actualIdSocieta!),
                  ),
                ).then((_) async {
                  if (!mounted) return;

                  await _dashboardNotifier.inizializza(
                    idSocieta: widget.idSocieta,
                    utenteLoggato: widget.utenteLoggato,
                  );
                });
              }
            },
            child: const Text(
              'Riattiva con Upgrade',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigaConAggiornamento(Widget pagina) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => pagina),
    );

    if (!mounted) return;

    await _dashboardNotifier.inizializza(
      idSocieta: widget.idSocieta,
      utenteLoggato: widget.utenteLoggato,
    );
  }

  Future<void> _apriPrenotazioneManuale() async {
    final state = ref.read(dashboardProvider);

    final idSocieta = state.actualIdSocieta;

    if (idSocieta == null) {
      return;
    }

    final creata = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PrenotazioneManualePage(
          idSocieta: idSocieta,
          idCampoIniziale: state.idCampoSelezionato,
        ),
      ),
    );

    if (creata == true && mounted) {
      await _dashboardNotifier.inizializza(
        idSocieta: widget.idSocieta,
        utenteLoggato: widget.utenteLoggato,
      );
    }
  }

  IconData _iconaCampo(Map<String, dynamic> campo) {
    final nome = (campo['nome_campo'] ?? '').toString().toLowerCase();

    final tariffe = campo['tariffe_sport'];

    String sport = '';

    if (tariffe is List && tariffe.isNotEmpty) {
      final primo = tariffe.first;

      if (primo is Map) {
        sport = (primo['sport'] ?? '').toString().toLowerCase();
      }
    }

    final testo = '$sport $nome';

    if (testo.contains('padel')) {
      return Icons.sports_tennis_rounded;
    }

    if (testo.contains('tennis')) {
      return Icons.sports_tennis_rounded;
    }

    if (testo.contains('basket') || testo.contains('pallacanestro')) {
      return Icons.sports_basketball_rounded;
    }

    if (testo.contains('volley') || testo.contains('pallavolo')) {
      return Icons.sports_volleyball_rounded;
    }

    if (testo.contains('calcio') || testo.contains('calcetto')) {
      return Icons.sports_soccer_rounded;
    }

    return Icons.stadium_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardProvider);

    final notificheAsync = ref.watch(notificheStreamProvider);

    final numeroNonLette = notificheAsync.maybeWhen(
      data: (notifiche) => notifiche.where((n) => !n.letto).length,
      orElse: () => 0,
    );

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFF6B00), AppTheme.neonOrange],
          ).createShader(bounds),
          child: const Text(
            'ARENA GESTORE',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              fontSize: 20,
              letterSpacing: 1.5,
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Notifiche',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotifichePage()),
              );
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  color: AppTheme.neonOrange,
                  size: 29,
                ),

                if (numeroNonLette > 0)
                  Positioned(
                    right: -5,
                    top: -6,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.statoErrore,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.darkBg, width: 2),
                      ),
                      child: Text(
                        numeroNonLette > 99 ? '99+' : numeroNonLette.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: PopupMenuButton<String>(
              icon: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.neonOrange.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.account_circle,
                  color: AppTheme.neonOrange,
                  size: 32,
                ),
              ),
              color: AppTheme.cardBg,
              position: PopupMenuPosition.under,
              onSelected: (value) async {
                if (value == 'modifica_profilo') {
                  if (widget.utenteLoggato != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfiloGestore(
                          utenteLoggato: widget.utenteLoggato!,
                        ),
                      ),
                    );
                  } else {
                    final userId =
                        Supabase.instance.client.auth.currentUser?.id;
                    if (userId != null) {
                      final userData = await Supabase.instance.client
                          .from('utenti')
                          .select()
                          .eq('id', userId)
                          .single();
                      final utenteRecuperato = Utente.fromJson(userData);
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProfiloGestore(utenteLoggato: utenteRecuperato),
                          ),
                        );
                      }
                    }
                  }
                } else if (value == 'modifica_orari') {
                  if (state.actualIdSocieta != null) {
                    _navigaConAggiornamento(
                      ModificaOrari(idSocieta: state.actualIdSocieta!),
                    );
                  }
                } else if (value == 'chiusure') {
                  if (state.actualIdSocieta != null) {
                    _navigaConAggiornamento(
                      ChiusureStraordinarie(idSocieta: state.actualIdSocieta!),
                    );
                  }
                } else if (value == 'guadagni') {
                  if (state.actualIdSocieta != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StatisticheGuadagni(
                          idSocieta: state.actualIdSocieta!,
                        ),
                      ),
                    );
                  }
                } else if (value == 'pagamenti') {
                  if (state.actualIdSocieta != null) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AttivazionePagamentiPage(
                          idSocieta: state.actualIdSocieta!,
                        ),
                      ),
                    );

                    if (context.mounted) {
                      ref
                          .read(dashboardProvider.notifier)
                          .inizializza(
                            idSocieta: widget.idSocieta,
                            utenteLoggato: widget.utenteLoggato,
                          );
                    }
                  }
                } else if (value == 'gestione_piano') {
                  if (state.actualIdSocieta != null) {
                    _navigaConAggiornamento(
                      SchermataAbbonamento(idSocieta: state.actualIdSocieta!),
                    );
                  }
                } else if (value == 'privacy_assistenza') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PrivacyAssistenzaGestore(),
                    ),
                  );
                } else if (value == 'logout') {
                  try {
                    await PushNotificationService.rimuoviTokenCorrente();

                    await Supabase.instance.client.auth.signOut(
                      scope: SignOutScope.local,
                    );
                  } catch (e) {
                    debugPrint("Errore o timeout durante il logout: $e");
                  }
                  if (context.mounted) {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/', (route) => false);
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'modifica_profilo',
                  child: ListTile(
                    leading: Icon(Icons.person, color: Colors.white),
                    title: Text(
                      'Modifica Profilo',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const PopupMenuItem(
                  value: 'modifica_orari',
                  child: ListTile(
                    leading: Icon(Icons.access_time, color: Colors.white),
                    title: Text(
                      'Modifica Orari Centro',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const PopupMenuItem(
                  value: 'chiusure',
                  child: ListTile(
                    leading: Icon(Icons.event_busy, color: Colors.white),
                    title: Text(
                      'Chiusure Straordinarie',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const PopupMenuItem(
                  value: 'guadagni',
                  child: ListTile(
                    leading: Icon(Icons.euro, color: Colors.white),
                    title: Text(
                      'Resoconto Guadagni',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const PopupMenuItem(
                  value: 'pagamenti',
                  child: ListTile(
                    leading: Icon(
                      Icons.account_balance_wallet_outlined,
                      color: AppTheme.neonOrange,
                    ),
                    title: Text(
                      'Pagamenti',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const PopupMenuDivider(color: Colors.grey),
                const PopupMenuItem(
                  value: 'gestione_piano',
                  child: ListTile(
                    leading: Icon(Icons.credit_card, color: Colors.white),
                    title: Text(
                      'Gestione Abbonamento',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const PopupMenuItem(
                  value: 'privacy_assistenza',
                  child: ListTile(
                    leading: Icon(
                      Icons.help_outline_rounded,
                      color: Colors.white,
                    ),
                    title: Text(
                      'Privacy e Assistenza',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),

                const PopupMenuDivider(color: Colors.grey),
                const PopupMenuDivider(color: Colors.grey),
                const PopupMenuItem(
                  value: 'logout',
                  child: ListTile(
                    leading: Icon(Icons.logout, color: AppTheme.neonOrange),
                    title: Text(
                      'Esci',
                      style: TextStyle(
                        color: AppTheme.neonOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.neonOrange,
        backgroundColor: AppTheme.cardBg,
        onRefresh: () => ref
            .read(dashboardProvider.notifier)
            .inizializza(
              idSocieta: widget.idSocieta,
              utenteLoggato: widget.utenteLoggato,
            ),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14.0,
                vertical: 10.0,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Ciao, ",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.utenteLoggato?.nome ?? 'Gestore',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: state.isCentroAttivo
                              ? Colors.green.withOpacity(0.1)
                              : Colors.redAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: state.isCentroAttivo
                                ? Colors.green.withOpacity(0.3)
                                : Colors.redAccent.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: state.isCentroAttivo
                                    ? Colors.green
                                    : Colors.redAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              state.isCentroAttivo
                                  ? "Centro Attivo"
                                  : "Centro Non Attivo",
                              style: TextStyle(
                                color: state.isCentroAttivo
                                    ? Colors.green
                                    : Colors.redAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    'I Tuoi Campi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.neonOrange,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 55,
                    child: state.isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.neonOrange,
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: state.campi.length,
                            itemBuilder: (context, index) {
                              final campo = state.campi[index];
                              final String idCampoString = campo['id']
                                  .toString();
                              final bool isSelezionato =
                                  state.idCampoSelezionato == idCampoString;

                              final bool isCampoBloccato =
                                  index >= state.limiteCampiConsentiti;

                              return Padding(
                                padding: const EdgeInsets.only(right: 10.0),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    color: isCampoBloccato
                                        ? Colors.black.withOpacity(0.5)
                                        : (isSelezionato
                                              ? AppTheme.neonOrange.withOpacity(
                                                  0.15,
                                                )
                                              : AppTheme.cardBg),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isCampoBloccato
                                          ? Colors.grey.shade900
                                          : (isSelezionato
                                                ? AppTheme.neonOrange
                                                : Colors.grey.shade800),
                                      width: isSelezionato && !isCampoBloccato
                                          ? 2.0
                                          : 1.0,
                                    ),
                                    boxShadow: isSelezionato && !isCampoBloccato
                                        ? [
                                            BoxShadow(
                                              color: AppTheme.neonOrange
                                                  .withOpacity(0.2),
                                              blurRadius: 8,
                                              spreadRadius: 1,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          if (isCampoBloccato) {
                                            _mostraDialogCampoBloccato();
                                          } else {
                                            ref
                                                .read(
                                                  dashboardProvider.notifier,
                                                )
                                                .filtraEConvertiDatiCalendario(
                                                  idCampo: idCampoString,
                                                );
                                          }
                                        },
                                        borderRadius:
                                            const BorderRadius.horizontal(
                                              left: Radius.circular(16),
                                            ),
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            left: 16.0,
                                            right: 8.0,
                                            top: 12.0,
                                            bottom: 12.0,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                isCampoBloccato
                                                    ? Icons.lock_outline_rounded
                                                    : _iconaCampo(campo),
                                                color: isCampoBloccato
                                                    ? Colors.grey.shade600
                                                    : (isSelezionato
                                                          ? AppTheme.neonOrange
                                                          : Colors.grey),
                                                size: 18,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                campo['nome_campo'] ??
                                                    'Senza nome',
                                                style: TextStyle(
                                                  color: isCampoBloccato
                                                      ? Colors.grey.shade600
                                                      : (isSelezionato
                                                            ? Colors.white
                                                            : Colors
                                                                  .grey
                                                                  .shade400),
                                                  fontWeight:
                                                      isSelezionato &&
                                                          !isCampoBloccato
                                                      ? FontWeight.w900
                                                      : FontWeight.normal,
                                                  fontSize: 14,
                                                  decoration: isCampoBloccato
                                                      ? TextDecoration
                                                            .lineThrough
                                                      : null,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      PopupMenuButton<String>(
                                        icon: Icon(
                                          Icons.more_vert_rounded,
                                          color:
                                              isSelezionato && !isCampoBloccato
                                              ? AppTheme.neonOrange
                                              : Colors.grey.shade600,
                                          size: 18,
                                        ),
                                        padding: EdgeInsets.zero,
                                        color: AppTheme.cardBg,
                                        onSelected: (value) async {
                                          if (value == 'modifica') {
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    AggiungiCampo(
                                                      idSocieta:
                                                          widget.idSocieta ??
                                                          state
                                                              .actualIdSocieta ??
                                                          '',
                                                      campoEsistente: campo,
                                                    ),
                                              ),
                                            );
                                            ref
                                                .read(
                                                  dashboardProvider.notifier,
                                                )
                                                .inizializza(
                                                  idSocieta: widget.idSocieta,
                                                  utenteLoggato:
                                                      widget.utenteLoggato,
                                                );
                                          } else if (value == 'elimina') {
                                            final conferma = await showDialog<bool>(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  backgroundColor:
                                                      AppTheme.cardBg,
                                                  title: const Text(
                                                    'Conferma eliminazione',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  content: const Text(
                                                    'Sei sicuro di voler eliminare questo campo?',
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(
                                                            context,
                                                          ).pop(false),
                                                      child: const Text(
                                                        'Annulla',
                                                        style: TextStyle(
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(
                                                            context,
                                                          ).pop(true),
                                                      child: const Text(
                                                        'Elimina',
                                                        style: TextStyle(
                                                          color:
                                                              Colors.redAccent,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );

                                            if (conferma == true) {
                                              try {
                                                await CampiService()
                                                    .eliminaCampo(campo['id']);
                                                ref
                                                    .read(
                                                      dashboardProvider
                                                          .notifier,
                                                    )
                                                    .inizializza(
                                                      idSocieta:
                                                          widget.idSocieta,
                                                      utenteLoggato:
                                                          widget.utenteLoggato,
                                                    );
                                              } catch (e) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        e.toString().replaceAll(
                                                          'Exception: ',
                                                          '',
                                                        ),
                                                      ),
                                                      backgroundColor:
                                                          Colors.redAccent,
                                                    ),
                                                  );
                                                }
                                              }
                                            }
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'modifica',
                                            child: ListTile(
                                              leading: Icon(
                                                Icons.edit,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                              title: Text(
                                                'Modifica',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              contentPadding: EdgeInsets.zero,
                                              dense: true,
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'elimina',
                                            child: ListTile(
                                              leading: Icon(
                                                Icons.delete_forever,
                                                color: Colors.redAccent,
                                                size: 18,
                                              ),
                                              title: Text(
                                                'Elimina',
                                                style: TextStyle(
                                                  color: Colors.redAccent,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              contentPadding: EdgeInsets.zero,
                                              dense: true,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Calendario',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.neonOrange,
                        ),
                      ),

                      LayoutBuilder(
                        builder: (context, constraints) {
                          final compatto =
                              MediaQuery.sizeOf(context).width < 430;

                          return ElevatedButton.icon(
                            onPressed:
                                state.actualIdSocieta == null ||
                                    state.campi.isEmpty
                                ? null
                                : () {
                                    if (!state.isCentroAttivo) {
                                      _mostraDialogCampoBloccato();
                                      return;
                                    }

                                    _apriPrenotazioneManuale();
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.neonOrange.withOpacity(
                                0.12,
                              ),
                              foregroundColor: AppTheme.neonOrange,
                              elevation: 0,
                              padding: EdgeInsets.symmetric(
                                horizontal: compatto ? 11 : 15,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                  color: AppTheme.neonOrange.withOpacity(0.45),
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 20),
                            label: Text(
                              compatto ? 'PRENOTA' : 'PRENOTAZIONE MANUALE',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade800),
                        left: BorderSide(color: Colors.grey.shade800),
                        right: BorderSide(color: Colors.grey.shade800),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.03),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(
                            Icons.chevron_left_rounded,
                            color: AppTheme.neonOrange,
                            size: 28,
                          ),
                          onPressed: () {
                            final dataAttuale =
                                _calendarController.displayDate ?? _oggi;

                            final giornoAttuale = DateTime(
                              dataAttuale.year,
                              dataAttuale.month,
                              dataAttuale.day,
                            );

                            if (!giornoAttuale.isAfter(_oggi)) {
                              return;
                            }

                            _calendarController.backward!();
                          },
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final DateTime? scelta = await showDatePicker(
                              context: context,
                              initialDate:
                                  _calendarController.displayDate ??
                                  DateTime.now(),
                              firstDate: _oggi,
                              lastDate: _dataMassimaCalendario,
                              builder: (context, child) {
                                return Theme(
                                  data: ThemeData.dark().copyWith(
                                    colorScheme: const ColorScheme.dark(
                                      primary: AppTheme.neonOrange,
                                      onPrimary: Colors.black,
                                      surface: AppTheme.cardBg,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (scelta != null) {
                              setState(() {
                                _calendarController.displayDate = scelta;
                              });
                            }
                          },
                          icon: const Icon(
                            Icons.calendar_month_rounded,
                            color: AppTheme.neonOrange,
                            size: 18,
                          ),
                          label: Text(
                            state.stringaDataCorrente.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.03),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(
                            Icons.chevron_right_rounded,
                            color: AppTheme.neonOrange,
                            size: 28,
                          ),
                          onPressed: () {
                            final dataAttuale =
                                _calendarController.displayDate ?? _oggi;

                            final giornoAttuale = DateTime(
                              dataAttuale.year,
                              dataAttuale.month,
                              dataAttuale.day,
                            );

                            if (!giornoAttuale.isBefore(
                              _dataMassimaCalendario,
                            )) {
                              return;
                            }

                            _calendarController.forward!();
                          },
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                    border: Border(
                      left: BorderSide(color: Colors.grey.shade800),
                      right: BorderSide(color: Colors.grey.shade800),
                      bottom: BorderSide(color: Colors.grey.shade800),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                    child: WidgetCalendarioGestore(
                      controller: _calendarController,
                      isLoading: state.isLoading,
                      prenotazioniVisibili: state.prenotazioniVisibili,
                      startHour: state.startHour,
                      endHour: state.endHour,
                      giornoChiuso: state.giornoChiuso,
                      onTap: _gestisciClickCalendario,
                      mainScrollController: _scrollController,
                      onViewChanged: (details) {
                        if (details.visibleDates.isNotEmpty) {
                          final dataCorrente = details.visibleDates.first;

                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              final notifier = ref.read(
                                dashboardProvider.notifier,
                              );

                              notifier.aggiornaGiornoCalendario(dataCorrente);

                              notifier.aggiornaDataCorrente(
                                "${dataCorrente.day}/${dataCorrente.month}/${dataCorrente.year}",
                              );
                            }
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Center(
                      child: Text(
                        '↑ Tira verso il basso per aggiornare il calendario',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: state.actualIdSocieta == null
              ? null
              : [
                  BoxShadow(
                    color: AppTheme.neonOrange.withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: FloatingActionButton.extended(
          onPressed: state.actualIdSocieta == null ? null : _tentaAggiuntaCampo,
          backgroundColor: state.actualIdSocieta == null
              ? Colors.grey
              : AppTheme.neonOrange,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          icon: const Icon(
            Icons.add_circle_outline_rounded,
            size: 22,
            color: Colors.black,
          ),
          label: const Text(
            'NUOVO CAMPO',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
