import 'package:flutter/material.dart';
import 'package:app_campi/core/theme/app_theme.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

class TelefonoFormWidget extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final bool mostraErrore;
  final String numeroIniziale;
  final ValueChanged<String> onNumeroCambiato;
  final ValueChanged<bool> onValiditaCambiata;

  const TelefonoFormWidget({
    super.key,
    required this.controller,
    this.focusNode,
    this.label = 'Cellulare *',
    this.mostraErrore = false,
    this.numeroIniziale = '',
    required this.onNumeroCambiato,
    required this.onValiditaCambiata,
  });

  @override
  Widget build(BuildContext context) {
    return InternationalPhoneNumberInput(
      onInputChanged: (PhoneNumber numero) {
        final completo = (numero.phoneNumber ?? '').replaceAll(
          RegExp(r'[^\d+]'),
          '',
        );

        onNumeroCambiato(completo);
      },
      onInputValidated: (bool valido) {
        onValiditaCambiata(valido);
      },
      selectorConfig: const SelectorConfig(
        selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
        showFlags: true,
        setSelectorButtonAsPrefixIcon: true,
      ),
      initialValue: PhoneNumber(
        isoCode: 'IT',
        phoneNumber: numeroIniziale.isEmpty ? null : numeroIniziale,
      ),
      textFieldController: controller,
      autoValidateMode: AutovalidateMode.onUserInteraction,
      ignoreBlank: false,
      formatInput: true,
      keyboardType: TextInputType.phone,
      selectorTextStyle: const TextStyle(color: Colors.white),
      textStyle: const TextStyle(color: Colors.white),
      inputDecoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade400),
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
    );
  }
}
