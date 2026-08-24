import 'package:flutter/material.dart';
import 'package:app_campi/core/theme/app_theme.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class IndirizzoFormWidget extends StatefulWidget {
  final TextEditingController viaController;
  final TextEditingController civicoController;
  final TextEditingController cittaController;
  final TextEditingController provinciaController;
  final FocusNode viaFocus;
  final FocusNode civicoFocus;
  final FocusNode cittaFocus;
  final FocusNode provinciaFocus;
  final Map<String, bool> campiAbbandonati;
  final Function(TextEditingController) onViaControllerReady;
  final Function(Map<String, double>) onCoordinateSelezionate;
  final VoidCallback onIndirizzoModificato;

  const IndirizzoFormWidget({
    super.key,
    required this.viaController,
    required this.civicoController,
    required this.cittaController,
    required this.provinciaController,
    required this.viaFocus,
    required this.civicoFocus,
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
  TextEditingController? _viaInternalController;
  bool _selezionandoSuggerimento = false;

  Future<List<Map<String, String>>> _cercaIndirizzi(String query) async {
    if (query.length < 3) return [];
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&countrycodes=it&limit=5',
    );
    try {
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'AppCampi/1.0 (info@appcampi.it)',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        return data.map<Map<String, String>>((item) {
          final address = item['address'] ?? {};
          final via =
              address['road'] ??
              address['pedestrian'] ??
              address['square'] ??
              item['name'] ??
              '';
          final citta =
              address['city'] ?? address['town'] ?? address['village'] ?? '';
          String provincia = '';
          final iso = address['ISO3166-2-lvl6'] as String?;
          if (iso != null && iso.contains('-')) {
            provincia = iso.split('-')[1];
          } else {
            provincia = address['county'] ?? '';
          }
          return <String, String>{
            'display': '$via, $citta ($provincia)',
            'via': via,
            'citta': citta,
            'provincia': provincia.length > 2
                ? provincia.substring(0, 2).toUpperCase()
                : provincia.toUpperCase(),
            'latitudine': item['lat']?.toString() ?? '',
            'longitudine': item['lon']?.toString() ?? '',
          };
        }).toList();
      }
    } catch (e) {
      debugPrint("Errore ricerca indirizzo: $e");
    }
    return [];
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String campoKey,
    FocusNode? focusNode,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      maxLength: maxLength,
      style: const TextStyle(color: Colors.white),
      textCapitalization: maxLength == 2
          ? TextCapitalization.characters
          : TextCapitalization.none,
      validator: (val) {
        if (widget.campiAbbandonati[campoKey] != true) return null;
        return validator?.call(val);
      },
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
        Autocomplete<Map<String, String>>(
          optionsBuilder: (TextEditingValue val) async {
            if (val.text.length < 3) return const Iterable.empty();
            return await _cercaIndirizzi(val.text);
          },
          displayStringForOption: (opt) => opt['via'] ?? '',
          onSelected: (opt) {
            _selezionandoSuggerimento = true;

            widget.viaController.text = opt['via'] ?? '';
            widget.cittaController.text = opt['citta'] ?? '';
            widget.provinciaController.text = opt['provincia'] ?? '';

            final double? latitudine = double.tryParse(opt['latitudine'] ?? '');

            final double? longitudine = double.tryParse(
              opt['longitudine'] ?? '',
            );

            if (latitudine != null && longitudine != null) {
              widget.onCoordinateSelezionate({
                'latitudine': latitudine,
                'longitudine': longitudine,
              });
            }

            _selezionandoSuggerimento = false;

            FocusScope.of(context).requestFocus(widget.civicoFocus);
          },
          fieldViewBuilder: (ctx, controller, focusNode, onComplete) {
            if (_viaInternalController == null) {
              _viaInternalController = controller;
              controller.text = widget.viaController.text;
              controller.addListener(() {
                widget.viaController.text = controller.text;

                if (!_selezionandoSuggerimento) {
                  widget.onIndirizzoModificato();
                }
              });
              widget.onViaControllerReady(controller);
            }
            return _buildField(
              controller: controller,
              focusNode: focusNode,
              label: 'Via/Piazza (Inizia a scrivere...) *',
              icon: Icons.location_on,
              campoKey: 'via',
              validator: (val) =>
                  val == null || val.trim().isEmpty ? 'Inserisci la via' : null,
            );
          },
          optionsViewBuilder: (ctx, onSelected, options) => Align(
            alignment: Alignment.topLeft,
            child: Material(
              color: AppTheme.cardBg,
              elevation: 4.0,
              borderRadius: BorderRadius.circular(15),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 200,
                  maxWidth: 300,
                ),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (c, i) {
                    final opt = options.elementAt(i);
                    return ListTile(
                      leading: const Icon(
                        Icons.location_on,
                        color: AppTheme.neonOrange,
                        size: 20,
                      ),
                      title: Text(
                        opt['display'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                      onTap: () => onSelected(opt),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),
        _buildField(
          controller: widget.civicoController,
          focusNode: widget.civicoFocus,
          label: 'Numero Civico *',
          icon: Icons.tag,
          campoKey: 'civico',
          keyboardType: TextInputType.streetAddress,
          validator: (val) =>
              val == null || val.trim().isEmpty ? 'N° obbligatorio' : null,
        ),
        const SizedBox(height: 15),
        _buildField(
          controller: widget.cittaController,
          focusNode: widget.cittaFocus,
          label: 'Città *',
          icon: Icons.location_city,
          campoKey: 'citta',
          validator: (val) =>
              val == null || val.trim().isEmpty ? 'Inserisci la città' : null,
        ),
        const SizedBox(height: 15),
        _buildField(
          controller: widget.provinciaController,
          focusNode: widget.provinciaFocus,
          label: 'Provincia *',
          icon: Icons.map,
          campoKey: 'provincia',
          maxLength: 2,
          validator: (val) =>
              val == null || val.trim().length != 2 ? '2 lettere' : null,
        ),
      ],
    );
  }
}
