import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_campi/core/models/partita.dart';
import 'package:app_campi/core/models/utente.dart';
import 'package:app_campi/core/theme/app_theme.dart';
import 'package:app_campi/features/auth/application/auth_provider.dart';
import '../../application/esplora_match_filter.dart';
import '../../application/join_match_controller.dart';
import 'package:app_campi/core/services/location_provider.dart';
import 'auth_bottom_sheet.dart';
import 'package:app_campi/features/miei_match/application/partite_utente_provider.dart';
import 'package:app_campi/features/home/presentation/home_page.dart';

void mostraDettagliEUnisciti(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> rawPartita,
) {
  final jsonNorm = Map<String, dynamic>.from(rawPartita);
  jsonNorm['campo'] = jsonNorm['campo'] ?? jsonNorm['campi'];

  Partita partita;
  try {
    partita = Partita.fromJson(jsonNorm);
  } catch (_) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Dati partita non disponibili.")),
    );
    return;
  }

  final utenteLoggato = ref.read(utenteCorrenteProvider).value;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _JoinMatchSheetContent(
      partita: partita,
      isOspite: utenteLoggato == null,
      giaIscritto: isGiaIscritto(partita, utenteLoggato),
      utenteLoggato: utenteLoggato,
    ),
  );
}

class _JoinMatchSheetContent extends StatelessWidget {
  final Partita partita;
  final bool isOspite;
  final bool giaIscritto;
  final Utente? utenteLoggato;

  const _JoinMatchSheetContent({
    required this.partita,
    required this.isOspite,
    required this.giaIscritto,
    required this.utenteLoggato,
  });

  int get _postiDisponibili =>
      partita.maxGiocatoriReali - partita.numeroGiocatoriPrenotati;

  @override
  Widget build(BuildContext context) {
    final postiDisponibili = _postiDisponibili;
    final maxOspitiAggiungibili = postiDisponibili > 0
        ? postiDisponibili - 1
        : 0;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.darkBg.withOpacity(0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: const Border(top: BorderSide(color: Colors.white10)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 30,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SheetHandle(),
              const SizedBox(height: 24),
              Text(
                partita.campo.nomeCampo,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              _DataOraChip(partita: partita),
              const SizedBox(height: 20),
              _PostiDisponibiliTile(posti: postiDisponibili),
              const SizedBox(height: 24),
              _buildCtaSection(postiDisponibili, maxOspitiAggiungibili),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCtaSection(int postiDisponibili, int maxOspitiAggiungibili) {
    if (isOspite) return const _OspiteSection();
    if (giaIscritto) return const _GiaIscrittoSection();
    if (postiDisponibili <= 0) return const _PartitaAlCompletoSection();
    return _IscrizioneConOspitiSection(
      partita: partita,
      utenteLoggato: utenteLoggato!,
      maxOspitiAggiungibili: maxOspitiAggiungibili,
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 5,
        decoration: BoxDecoration(
          color: Colors.grey.shade700,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

class _DataOraChip extends StatelessWidget {
  final Partita partita;
  const _DataOraChip({required this.partita});

  @override
  Widget build(BuildContext context) {
    final orario = partita.orarioInizio.length >= 5
        ? partita.orarioInizio.substring(0, 5)
        : partita.orarioInizio;
    final d = partita.dataPartita;
    final dataStr =
        "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.textPrimary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.calendar_month_rounded,
            color: AppTheme.textSecondary,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            dataStr,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.schedule, color: AppTheme.textSecondary, size: 16),
          const SizedBox(width: 6),
          Text(
            orario,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _PostiDisponibiliTile extends StatelessWidget {
  final int posti;
  const _PostiDisponibiliTile({required this.posti});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Posti disponibili",
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "$posti",
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _OspiteSection extends StatelessWidget {
  const _OspiteSection();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Devi accedere per poterti unire al match.",
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 15),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              mostraBottomSheetAutenticazione(context);
            },
            child: const Text(
              "ACCEDI",
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }
}

class _GiaIscrittoSection extends StatelessWidget {
  const _GiaIscrittoSection();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accent.withOpacity(0.5)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded, color: AppTheme.accent, size: 18),
          SizedBox(width: 8),
          Text(
            "Sei già iscritto a questa partita",
            style: TextStyle(
              color: AppTheme.accent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _PartitaAlCompletoSection extends StatelessWidget {
  const _PartitaAlCompletoSection();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.statoErrore.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.statoErrore.withOpacity(0.5)),
      ),
      child: const Center(
        child: Text(
          "La partita è al completo",
          style: TextStyle(
            color: AppTheme.statoErrore,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _IscrizioneConOspitiSection extends ConsumerStatefulWidget {
  final Partita partita;
  final Utente utenteLoggato;
  final int maxOspitiAggiungibili;

  const _IscrizioneConOspitiSection({
    required this.partita,
    required this.utenteLoggato,
    required this.maxOspitiAggiungibili,
  });

  @override
  ConsumerState<_IscrizioneConOspitiSection> createState() =>
      _IscrizioneConOspitiSectionState();
}

class _IscrizioneConOspitiSectionState
    extends ConsumerState<_IscrizioneConOspitiSection> {
  int _numeroPersone = 1;

  @override
  Widget build(BuildContext context) {
    final joinState = ref.watch(joinMatchControllerProvider);
    final isLoading = joinState.isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "In quanti siete?",
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        _OspitiCounter(
          valore: _numeroPersone,
          max: widget.maxOspitiAggiungibili + 1,
          onDecrementa: _numeroPersone > 1 && !isLoading
              ? () => setState(() => _numeroPersone--)
              : null,
          onIncrementa:
              _numeroPersone < widget.maxOspitiAggiungibili + 1 && !isLoading
              ? () => setState(() => _numeroPersone++)
              : null,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isLoading ? null : () => _confermaIscrizione(context),
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: AppTheme.darkBg,
                      strokeWidth: 3,
                    ),
                  )
                : const Text(
                    "CONFERMA ISCRIZIONE",
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _confermaIscrizione(BuildContext context) async {
    final int nuovoTotale =
        widget.partita.numeroGiocatoriPrenotati + _numeroPersone;

    final bool diventaCompleta =
        nuovoTotale >= widget.partita.maxGiocatoriReali;
    final errore = await ref
        .read(joinMatchControllerProvider.notifier)
        .unisciti(widget.partita, widget.utenteLoggato, _numeroPersone - 1);

    if (!context.mounted) return;

    if (errore == null) {
      Navigator.pop(context);

      ref
          .read(filtroPartitaProvider.notifier)
          .impostaFiltro(
            diventaCompleta ? FiltroPartita.complete : FiltroPartita.aperte,
          );

      ref.invalidate(matchInZonaProvider);
      ref.invalidate(partiteUtenteProvider(widget.utenteLoggato.id));

      if (!context.mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage(initialIndex: 2)),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errore), backgroundColor: AppTheme.statoErrore),
      );
    }
  }
}

class _OspitiCounter extends StatelessWidget {
  final int valore;
  final int max;
  final VoidCallback? onDecrementa;
  final VoidCallback? onIncrementa;

  const _OspitiCounter({
    required this.valore,
    required this.max,
    required this.onDecrementa,
    required this.onIncrementa,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onDecrementa,
            icon: Icon(
              Icons.remove_circle_outline_rounded,
              color: onDecrementa != null
                  ? AppTheme.textPrimary
                  : AppTheme.textDisabled,
              size: 30,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "$valore",
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onIncrementa,
            icon: Icon(
              Icons.add_circle_outline_rounded,
              color: onIncrementa != null
                  ? AppTheme.textPrimary
                  : AppTheme.textDisabled,
              size: 30,
            ),
          ),
          const Spacer(),
          Text(
            "$valore ${valore == 1 ? 'persona' : 'persone'}",
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
