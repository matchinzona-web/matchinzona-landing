import 'package:flutter/material.dart';
import 'package:app_campi/core/theme/app_theme.dart';

class IndirizzoFormWidget extends StatefulWidget {
  final TextEditingController viaController;
  final TextEditingController civicoController;
  final TextEditingController capController;
  final TextEditingController cittaController;
  final TextEditingController provinciaController;

  final FocusNode viaFocus;
  final FocusNode civicoFocus;
  final FocusNode capFocus;
  final FocusNode cittaFocus;
  final FocusNode provinciaFocus;

  final Map<String, bool> campiAbbandonati;

  final Function(TextEditingController) onViaControllerReady;

  // Mantenuto per compatibilità.
  // Le coordinate vengono ottenute tramite Geoapify
  // al momento del salvataggio.
  final Function(Map<String, double>) onCoordinateSelezionate;

  final VoidCallback onIndirizzoModificato;

  const IndirizzoFormWidget({
    super.key,
    required this.viaController,
    required this.civicoController,
    required this.capController,
    required this.cittaController,
    required this.provinciaController,
    required this.viaFocus,
    required this.civicoFocus,
    required this.capFocus,
    required this.cittaFocus,
    required this.provinciaFocus,
    required this.campiAbbandonati,
    required this.onViaControllerReady,
    required this.onCoordinateSelezionate,
    required this.onIndirizzoModificato,
  });

  @override
  State<IndirizzoFormWidget> createState() => _IndirizzoFormWidgetState();
}

class _IndirizzoFormWidgetState extends State<IndirizzoFormWidget> {
  void _indirizzoModificato() {
    widget.onIndirizzoModificato();
  }

  @override
  void initState() {
    super.initState();

    widget.viaController.addListener(_indirizzoModificato);

    widget.civicoController.addListener(_indirizzoModificato);

    widget.capController.addListener(_indirizzoModificato);

    widget.cittaController.addListener(_indirizzoModificato);

    widget.provinciaController.addListener(_indirizzoModificato);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      widget.onViaControllerReady(widget.viaController);
    });
  }

  @override
  void dispose() {
    widget.viaController.removeListener(_indirizzoModificato);

    widget.civicoController.removeListener(_indirizzoModificato);

    widget.capController.removeListener(_indirizzoModificato);

    widget.cittaController.removeListener(_indirizzoModificato);

    widget.provinciaController.removeListener(_indirizzoModificato);

    super.dispose();
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String campoKey,
    FocusNode? focusNode,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction? textInputAction,
    int? maxLength,
    String? Function(String?)? validator,
    VoidCallback? onEditingComplete,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLength: maxLength,
      style: const TextStyle(color: Colors.white),
      textCapitalization: maxLength == 2
          ? TextCapitalization.characters
          : TextCapitalization.words,
      validator: (val) {
        if (widget.campiAbbandonati[campoKey] != true) {
          return null;
        }

        return validator?.call(val);
      },
      onEditingComplete: onEditingComplete,
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        labelStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: AppTheme.neonOrange),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Indirizzo Centro Sportivo *',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        // VIA
        _buildField(
          controller: widget.viaController,
          focusNode: widget.viaFocus,
          label: 'Via/Piazza *',
          icon: Icons.location_on,
          campoKey: 'via',
          keyboardType: TextInputType.streetAddress,
          textInputAction: TextInputAction.next,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Inserisci la via';
            }

            return null;
          },
          onEditingComplete: () {
            FocusScope.of(context).requestFocus(widget.civicoFocus);
          },
        ),

        const SizedBox(height: 15),

        // CIVICO
        _buildField(
          controller: widget.civicoController,
          focusNode: widget.civicoFocus,
          label: 'Numero Civico *',
          icon: Icons.tag,
          campoKey: 'civico',
          keyboardType: TextInputType.streetAddress,
          textInputAction: TextInputAction.next,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'N° obbligatorio';
            }

            return null;
          },
          onEditingComplete: () {
            FocusScope.of(context).requestFocus(widget.capFocus);
          },
        ),

        const SizedBox(height: 15),

        // CAP
        _buildField(
          controller: widget.capController,
          focusNode: widget.capFocus,
          label: 'CAP *',
          icon: Icons.markunread_mailbox_outlined,
          campoKey: 'cap',
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          maxLength: 5,
          validator: (val) {
            final valore = (val ?? '').trim();

            if (valore.isEmpty) {
              return 'Inserisci il CAP';
            }

            if (!RegExp(r'^\d{5}$').hasMatch(valore)) {
              return 'Il CAP deve avere 5 cifre';
            }

            return null;
          },
          onEditingComplete: () {
            FocusScope.of(context).requestFocus(widget.cittaFocus);
          },
        ),

        const SizedBox(height: 15),

        // COMUNE
        _buildField(
          controller: widget.cittaController,
          focusNode: widget.cittaFocus,
          label: 'Comune *',
          icon: Icons.location_city,
          campoKey: 'citta',
          textInputAction: TextInputAction.next,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Inserisci il comune';
            }

            return null;
          },
          onEditingComplete: () {
            FocusScope.of(context).requestFocus(widget.provinciaFocus);
          },
        ),

        const SizedBox(height: 15),

        // PROVINCIA
        _buildField(
          controller: widget.provinciaController,
          focusNode: widget.provinciaFocus,
          label: 'Provincia *',
          icon: Icons.map,
          campoKey: 'provincia',
          maxLength: 2,
          textInputAction: TextInputAction.done,
          validator: (val) {
            final valore = (val ?? '').trim().toUpperCase();

            if (valore.length != 2) {
              return 'Inserisci 2 lettere';
            }

            if (!RegExp(r'^[A-Z]{2}$').hasMatch(valore)) {
              return 'Provincia non valida';
            }

            return null;
          },
          onEditingComplete: () {
            FocusScope.of(context).unfocus();
          },
        ),
      ],
    );
  }
}
