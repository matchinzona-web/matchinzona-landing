import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:app_campi/core/theme/app_theme.dart';

void mostraLeggendaDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.6),
    builder: (ctx) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.cardBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 30,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.textPrimary.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      color: AppTheme.textPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    "Stati del Match",
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const _LeggendaItem(
                titolo: "COMPLETA",
                descrizione:
                    "La partita ha raggiunto il numero massimo di giocatori. "
                    "Il campo è occupato e lo slot è bloccato.",
                colore: AppTheme.statoSuccesso,
                icona: Icons.check_circle_rounded,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: AppTheme.cardBorder, height: 1),
              ),
              const _LeggendaItem(
                titolo: "APERTA",
                descrizione:
                    "La partita è ancora incompleta e altri giocatori possono unirsi. "
                    "Finché non è completa, lo slot può essere assegnato a una prenotazione "
                    "completa del campo.",
                colore: AppTheme.accent,
                icona: Icons.groups_rounded,
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.textPrimary.withOpacity(0.1),
                    foregroundColor: AppTheme.textPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text("HO CAPITO"),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _LeggendaItem extends StatelessWidget {
  final String titolo;
  final String descrizione;
  final Color colore;
  final IconData icona;

  const _LeggendaItem({
    required this.titolo,
    required this.descrizione,
    required this.colore,
    required this.icona,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icona, color: colore, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titolo,
                style: TextStyle(
                  color: colore,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                descrizione,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
