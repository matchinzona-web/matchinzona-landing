import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app_campi/core/theme/app_theme.dart';

class FotoSocietaWidget extends StatefulWidget {
  final Function(Uint8List bytes, String estensione) onFotoSelezionata;
  final VoidCallback onFotoRimossa;
  final Uint8List? fotoBytes;

  const FotoSocietaWidget({
    super.key,
    required this.onFotoSelezionata,
    required this.onFotoRimossa,
    this.fotoBytes,
  });

  @override
  State<FotoSocietaWidget> createState() => _FotoSocietaWidgetState();
}

class _FotoSocietaWidgetState extends State<FotoSocietaWidget> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _selezionaFoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      String estensione = 'jpg';
      if (image.name.contains('.')) {
        estensione = image.name.split('.').last;
      }
      widget.onFotoSelezionata(bytes, estensione);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossibile selezionare la foto. Riprova.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto Società (Facoltativa)',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          height: 140,
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: widget.fotoBytes != null
                  ? AppTheme.neonOrange
                  : Colors.grey.shade700,
              width: 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (widget.fotoBytes != null)
                  Image.memory(widget.fotoBytes!, fit: BoxFit.cover)
                else
                  GestureDetector(
                    onTap: _selezionaFoto,
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_a_photo,
                          color: AppTheme.neonOrange,
                          size: 36,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Clicca per selezionare il logo del centro',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (widget.fotoBytes != null)
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _selezionaFoto,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppTheme.neonOrange,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.black,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: widget.onFotoRimossa,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
