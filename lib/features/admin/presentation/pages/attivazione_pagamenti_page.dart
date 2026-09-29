import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:app_campi/core/theme/app_theme.dart';

class AttivazionePagamentiPage extends StatefulWidget {
  final String idSocieta;

  const AttivazionePagamentiPage({super.key, required this.idSocieta});

  @override
  State<AttivazionePagamentiPage> createState() =>
      _AttivazionePagamentiPageState();
}

class _AttivazionePagamentiPageState extends State<AttivazionePagamentiPage> {
  bool _isChecking = true;
  bool _isOpeningStripe = false;

  bool _hasStripeAccount = false;
  bool _chargesEnabled = false;
  bool _payoutsEnabled = false;
  bool _detailsSubmitted = false;

  List<dynamic> _currentlyDue = [];
  List<dynamic> _pastDue = [];

  @override
  void initState() {
    super.initState();
    _verificaStatoConto();
  }

  // ============================================================
  // VERIFICA STATO STRIPE
  // ============================================================

  Future<void> _verificaStatoConto({bool mostraErrore = true}) async {
    if (mounted) {
      setState(() => _isChecking = true);
    }

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'verifica-account-connect',
      );

      if (response.status != 200 || response.data == null) {
        throw Exception(
          response.data?['error'] ??
              'Impossibile verificare lo stato dei pagamenti.',
        );
      }

      final data = Map<String, dynamic>.from(response.data);

      final bool chargesEnabled = data['charges_enabled'] == true;
      final bool payoutsEnabled = data['payouts_enabled'] == true;
      final bool hasStripeAccount = data['has_stripe_account'] == true;
      final bool detailsSubmitted = data['details_submitted'] == true;

      if (!mounted) return;

      setState(() {
        _hasStripeAccount = hasStripeAccount;
        _chargesEnabled = chargesEnabled;
        _payoutsEnabled = payoutsEnabled;
        _detailsSubmitted = detailsSubmitted;

        _currentlyDue = data['currently_due'] is List
            ? List<dynamic>.from(data['currently_due'])
            : [];

        _pastDue = data['past_due'] is List
            ? List<dynamic>.from(data['past_due'])
            : [];

        _isChecking = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isChecking = false);

      if (mostraErrore) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Non è stato possibile verificare lo stato dei pagamenti.',
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ============================================================
  // APERTURA STRIPE CONNECT
  // ============================================================

  Future<void> _apriConfigurazioneStripe() async {
    if (_isOpeningStripe) return;

    setState(() => _isOpeningStripe = true);

    try {
      debugPrint(
        'Avvio configurazione pagamenti per società: ${widget.idSocieta}',
      );

      final response = await Supabase.instance.client.functions.invoke(
        'crea-account-connect',
        body: {'id_societa': widget.idSocieta},
      );

      if (response.status != 200 || response.data == null) {
        throw Exception(
          response.data?['error'] ??
              'Impossibile aprire la configurazione dei pagamenti.',
        );
      }

      final String? url = response.data['url'];

      if (url == null || url.isEmpty) {
        throw Exception('Link di configurazione non valido.');
      }

      final uri = Uri.tryParse(url);

      if (uri == null) {
        throw Exception('Link di configurazione non valido.');
      }

      final canOpen = await canLaunchUrl(uri);

      if (!canOpen) {
        throw Exception('Impossibile aprire il portale di configurazione.');
      }

      await launchUrl(uri, mode: LaunchMode.externalApplication);

      // Quando l'utente torna nell'app, ricontrolliamo lo stato.
      if (mounted) {
        await _verificaStatoConto(mostraErrore: false);
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Non è stato possibile aprire la configurazione.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isOpeningStripe = false);
      }
    }
  }

  // ============================================================
  // NAVIGAZIONE
  // ============================================================

  // ============================================================
  // STATO PAGAMENTI
  // ============================================================

  bool get _pagamentiAttivi => _chargesEnabled && _payoutsEnabled;

  bool get _configurazioneIncompleta => _hasStripeAccount && !_pagamentiAttivi;

  String get _titolo {
    if (_pagamentiAttivi) {
      return 'Pagamenti attivi';
    }

    if (_configurazioneIncompleta) {
      return 'Completa la configurazione';
    }

    return 'Ricevi i pagamenti delle prenotazioni';
  }

  String get _descrizione {
    if (_pagamentiAttivi) {
      return 'Il tuo conto è pronto per ricevere i pagamenti delle prenotazioni su Matchly.';
    }

    if (_configurazioneIncompleta) {
      return 'La configurazione è stata iniziata, ma servono ancora alcuni passaggi per attivare completamente i pagamenti.';
    }

    return 'Configura il tuo conto per permettere ai clienti di pagare le prenotazioni direttamente su Matchly.';
  }

  String get _testoPulsante {
    if (_configurazioneIncompleta) {
      return 'Continua configurazione';
    }

    return 'Configura i pagamenti';
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Pagamenti',
          style: TextStyle(
            color: AppTheme.neonOrange,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 28),
                  _buildStatusCard(),
                  const SizedBox(height: 20),
                  _buildInfoCard(),
                  const SizedBox(height: 28),
                  _buildMainButton(),
                  const SizedBox(height: 20),
                  _buildSecurityText(),
                  const SizedBox(height: 24),
                  _buildHomeButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.cardBg,
            border: Border.all(
              color: _pagamentiAttivi
                  ? Colors.greenAccent
                  : AppTheme.neonOrange,
              width: 2,
            ),
          ),
          child: Icon(
            _pagamentiAttivi
                ? Icons.check_circle_outline
                : Icons.account_balance_wallet_outlined,
            size: 42,
            color: _pagamentiAttivi ? Colors.greenAccent : AppTheme.neonOrange,
          ),
        ),
        const SizedBox(height: 22),
        Text(
          _titolo,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _descrizione,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade400,
            height: 1.55,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STATUS CARD
  // ============================================================

  Widget _buildStatusCard() {
    if (_isChecking) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppTheme.neonOrange,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              'Verifica dello stato in corso...',
              style: TextStyle(color: Colors.grey.shade300, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_pagamentiAttivi) {
      return _buildStatusContainer(
        icon: Icons.check_circle,
        iconColor: Colors.greenAccent,
        title: 'Pagamenti attivi',
        subtitle: 'Il conto è pronto per ricevere gli accrediti.',
      );
    }

    if (_configurazioneIncompleta) {
      return _buildStatusContainer(
        icon: Icons.info_outline,
        iconColor: AppTheme.neonOrange,
        title: 'Configurazione da completare',
        subtitle: _pastDue.isNotEmpty
            ? 'È necessario completare alcune informazioni.'
            : 'Continua la configurazione per attivare i pagamenti.',
      );
    }

    return _buildStatusContainer(
      icon: Icons.arrow_forward_rounded,
      iconColor: AppTheme.neonOrange,
      title: 'Configurazione necessaria',
      subtitle: 'Bastano pochi passaggi per iniziare.',
    );
  }

  Widget _buildStatusContainer({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: iconColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFO
  // ============================================================

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            Icons.credit_card_outlined,
            'Pagamenti online',
            'I clienti potranno pagare le prenotazioni.',
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.account_balance_outlined,
            'Accrediti',
            'Gli incassi vengono trasferiti sul conto configurato.',
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.verified_user_outlined,
            'Sicurezza',
            'La verifica dei dati viene gestita da Stripe.',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.neonOrange, size: 22),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MAIN BUTTON
  // ============================================================

  Widget _buildMainButton() {
    if (_pagamentiAttivi) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isOpeningStripe ? null : _apriConfigurazioneStripe,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.neonOrange,
          foregroundColor: AppTheme.darkBg,
          disabledBackgroundColor: AppTheme.neonOrange.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        icon: _isOpeningStripe
            ? const SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(
                  strokeWidth: 2.3,
                  color: AppTheme.darkBg,
                ),
              )
            : const Icon(Icons.arrow_forward_rounded),
        label: Text(
          _isOpeningStripe ? 'Apertura in corso...' : _testoPulsante,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ============================================================
  // CONTINUA
  // ============================================================

  // ============================================================
  // SICUREZZA
  // ============================================================

  Widget _buildSecurityText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline, size: 15, color: Colors.grey.shade600),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            'Configurazione e verifica gestite in sicurezza da Stripe',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5),
          ),
        ),
      ],
    );
  }

  Widget _buildHomeButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.of(context).pop();
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.grey.shade700),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        icon: const Icon(Icons.home_outlined),
        label: const Text(
          'Torna alla Home',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
