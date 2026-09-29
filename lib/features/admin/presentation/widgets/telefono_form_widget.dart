import 'package:flutter/material.dart';
import 'package:app_campi/core/theme/app_theme.dart';

class TelefonoFormWidget extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final bool mostraErrore;

  const TelefonoFormWidget({
    super.key,
    required this.controller,
    this.focusNode,
    this.label = 'Cellulare *',
    this.mostraErrore = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.phone,
      maxLength: 10,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        labelStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: const Icon(Icons.phone_android, color: AppTheme.neonOrange),
        filled: true,
        fillColor: AppTheme.cardBg,
        errorStyle: const TextStyle(
          color: Colors.redAccent,
          fontWeight: FontWeight.bold,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade700, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppTheme.neonOrange, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2.5),
        ),
      ),
      validator: (val) {
        if (!mostraErrore) {
          return null;
        }

        if (val == null || val.trim().isEmpty) {
          return 'Inserisci il numero';
        }

        if (!RegExp(r'^\d{10}$').hasMatch(val.trim())) {
          return 'Inserisci esattamente 10 cifre';
        }

        return null;
      },
    );
  }
}
