import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_campi/core/services/campi_service.dart';
import 'package:app_campi/core/theme/app_theme.dart';

class AggiungiCampo extends StatefulWidget {
  final String idSocieta;
  final Map<String, dynamic>? campoEsistente;

  const AggiungiCampo({
    super.key,
    required this.idSocieta,
    this.campoEsistente,
  });

  @override
  State<AggiungiCampo> createState() => _AggiungiCampoState();
}

class _AggiungiCampoState extends State<AggiungiCampo> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  late final CampiService _campiService;

  final _nomeController = TextEditingController();

  // Lista sport supportati con icone ed etichette
  final List<Map<String, dynamic>> _sportDisponibili = [
    {'id': 'calcio_5', 'label': 'Calcio a 5', 'icon': Icons.sports_soccer},
    {'id': 'calcio_6', 'label': 'Calcio a 6', 'icon': Icons.sports_soccer},
    {'id': 'calcio_7', 'label': 'Calcio a 7', 'icon': Icons.sports_soccer},
    {'id': 'calcio_8', 'label': 'Calcio a 8', 'icon': Icons.sports_soccer},
    {'id': 'calcio_11', 'label': 'Calcio a 11', 'icon': Icons.sports_soccer},
    {
      'id': 'tennis_singolo',
      'label': 'Tennis Singolo (1 vs 1)',
      'icon': Icons.sports_tennis,
    },
    {
      'id': 'tennis_doppio',
      'label': 'Tennis Doppio (2 vs 2)',
      'icon': Icons.sports_tennis,
    },
    {'id': 'padel', 'label': 'Padel (2 vs 2)', 'icon': Icons.sports_tennis},
    {'id': 'basket', 'label': 'Basket', 'icon': Icons.sports_basketball},
    {'id': 'pallavolo', 'label': 'Pallavolo', 'icon': Icons.sports_volleyball},
  ];

  final Map<String, bool> _sportSelezionati = {};
  final Map<String, Map<int, TextEditingController>> _prezziDurataControllers =
      {};

  final Map<String, Set<int>> _durateAbilitate = {};

  bool _isCoperto = false;
  bool _isCaricamento = false;

  String? _fotoUrl;
  Uint8List? _fotoBytesLocali;
  String? _estensioneFotoLocale;

  @override
  void initState() {
    super.initState();
    _campiService = CampiService();

    for (var sport in _sportDisponibili) {
      final sportId = sport['id'] as String;

      _sportSelezionati[sportId] = false;

      _prezziDurataControllers[sportId] = {
        60: TextEditingController(),
        90: TextEditingController(),
      };

      _durateAbilitate[sportId] = {60};
    }

    if (widget.campoEsistente != null) {
      final c = widget.campoEsistente!;
      _nomeController.text = c['nome_campo'] ?? '';
      _isCoperto = c['coperto'] ?? false;
      _fotoUrl = c['foto_url'];

      if (c['tariffe_sport'] != null &&
          (c['tariffe_sport'] as List).isNotEmpty) {
        final List tariffe = c['tariffe_sport'];
        for (var t in tariffe) {
          final String sportId = t['sport'] ?? '';
          final double prezzo = (t['prezzo'] ?? 0).toDouble();

          if (_sportSelezionati.containsKey(sportId)) {
            _sportSelezionati[sportId] = true;

            final raw = t['prezzi_durata'];

            if (raw is Map) {
              _durateAbilitate[sportId] = {};

              for (final durata in [60, 90]) {
                final valore = raw[durata.toString()];

                if (valore is num && valore > 0) {
                  _durateAbilitate[sportId]!.add(durata);
                  _prezziDurataControllers[sportId]![durata]!.text = valore
                      .toStringAsFixed(2);
                }
              }
            } else {
              // Tariffa precedente: soltanto 60 minuti.
              _durateAbilitate[sportId] = {60};

              _prezziDurataControllers[sportId]![60]!.text = prezzo > 0
                  ? prezzo.toStringAsFixed(2)
                  : '';
            }
          }
        }
      } else {
        final double prezzoVecchio = (c['prezzo'] ?? 0).toDouble();
        _sportSelezionati['calcio_5'] = true;
        _durateAbilitate['calcio_5'] = {60};

        _prezziDurataControllers['calcio_5']![60]!.text = prezzoVecchio > 0
            ? prezzoVecchio.toStringAsFixed(2)
            : '';
      }
    } else {
      for (var key in _sportSelezionati.keys) {
        _sportSelezionati[key] = false;
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    for (final controllers in _prezziDurataControllers.values) {
      for (final controller in controllers.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _selezionaFotoCampo() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      String estensione = 'jpg';
      if (image.name.contains('.')) {
        estensione = image.name.split('.').last;
      }
      setState(() {
        _fotoBytesLocali = bytes;
        _estensioneFotoLocale = estensione;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossibile selezionare la foto. Riprova.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _rimuoviFotoCampo() {
    setState(() {
      _fotoBytesLocali = null;
      _estensioneFotoLocale = null;
      _fotoUrl = null;
    });
  }

  void _salvaCampo() async {
    final haSportSelezionato = _sportSelezionati.values.contains(true);
    if (!haSportSelezionato) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text('Seleziona almeno uno sport per questo campo!'),
              ),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _isCaricamento = true);

      try {
        final List<Map<String, dynamic>> tariffeSport = [];
        double? prezzoPrincipale;

        for (var sport in _sportDisponibili) {
          final sportId = sport['id'] as String;

          if (_sportSelezionati[sportId] == true) {
            final Map<String, double> prezziDurata = {};
            final durateAttive = _durateAbilitate[sportId] ?? <int>{};

            if (durateAttive.isEmpty) {
              throw Exception(
                'Seleziona almeno una durata per ${sport['label']}.',
              );
            }

            for (final durata in [60, 90]) {
              if (!durateAttive.contains(durata)) continue;

              final testo = _prezziDurataControllers[sportId]![durata]!.text
                  .trim()
                  .replaceAll(',', '.');

              final prezzo = double.tryParse(testo);

              if (prezzo == null || !prezzo.isFinite || prezzo <= 0) {
                throw Exception(
                  'Inserisci un prezzo valido per ${sport['label']} '
                  '($durata minuti).',
                );
              }

              prezziDurata[durata.toString()] = prezzo;
            }

            // Mantiene il vecchio campo "prezzo" per compatibilità.
            final prezzoRiferimento =
                prezziDurata['60'] ?? prezziDurata['90'] ?? 0.0;

            tariffeSport.add({
              'sport': sportId,
              'prezzo': prezzoRiferimento,
              'prezzi_durata': prezziDurata,
            });

            prezzoPrincipale ??= prezzoRiferimento;
          }
        }

        String? idCampoAttuale;
        final int numGiocatori = _calcolaNumeroGiocatori(tariffeSport);

        if (widget.campoEsistente == null) {
          final res = await Supabase.instance.client
              .from('campi')
              .insert({
                'id_societa': widget.idSocieta,
                'nome_campo': _nomeController.text.trim(),
                'numero_di_giocatori': numGiocatori,
                'prezzo': prezzoPrincipale ?? 0,
                'coperto': _isCoperto,
                'tariffe_sport': tariffeSport,
              })
              .select('id')
              .single();

          idCampoAttuale = res['id']?.toString();
        } else {
          idCampoAttuale = widget.campoEsistente!['id'].toString();
          await Supabase.instance.client
              .from('campi')
              .update({
                'nome_campo': _nomeController.text.trim(),
                'numero_di_giocatori': numGiocatori,
                'prezzo': prezzoPrincipale ?? 0,
                'coperto': _isCoperto,
                'tariffe_sport': tariffeSport,
              })
              .eq('id', idCampoAttuale);
        }

        if (idCampoAttuale != null) {
          if (_fotoBytesLocali != null && _estensioneFotoLocale != null) {
            final fileName =
                'campo_${idCampoAttuale}_${DateTime.now().millisecondsSinceEpoch}.$_estensioneFotoLocale';
            await Supabase.instance.client.storage
                .from('avatar_societa')
                .uploadBinary(
                  fileName,
                  _fotoBytesLocali!,
                  fileOptions: const FileOptions(upsert: true),
                );
            final String publicUrl = Supabase.instance.client.storage
                .from('avatar_societa')
                .getPublicUrl(fileName);
            await Supabase.instance.client
                .from('campi')
                .update({'foto_url': publicUrl})
                .eq('id', idCampoAttuale);
          } else if (_fotoUrl == null &&
              widget.campoEsistente != null &&
              widget.campoEsistente!['foto_url'] != null) {
            await Supabase.instance.client
                .from('campi')
                .update({'foto_url': null})
                .eq('id', idCampoAttuale);
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.campoEsistente == null
                    ? 'Campo creato con successo! 🎉'
                    : 'Campo aggiornato! ✏️',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isCaricamento = false);
      }
    }
  }

  InputDecoration _stileInput(
    String label,
    IconData icon, {
    String? prefixText,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      prefixIcon: Icon(icon, color: AppTheme.neonOrange, size: 22),
      prefixText: prefixText,
      prefixStyle: const TextStyle(
        color: AppTheme.neonOrange,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
      filled: true,
      fillColor: const Color(0xFF1E2026),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.neonOrange, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
      errorStyle: const TextStyle(
        color: Colors.redAccent,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isModifica = widget.campoEsistente != null;
    final bool urlValido =
        _fotoUrl != null && _fotoUrl!.trim().isNotEmpty && _fotoUrl != 'null';
    final bool haImmagine = _fotoBytesLocali != null || urlValido;

    return Scaffold(
      backgroundColor: const Color(0xFF121318),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121318),
        elevation: 0,
        centerTitle: true,
        title: Text(
          isModifica ? 'Modifica Campo' : 'Nuovo Campo',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CARD FOTO CAMPO
                  const Text(
                    'FOTO COPERTINA',
                    style: TextStyle(
                      color: AppTheme.neonOrange,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _selezionaFotoCampo,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      height: 170,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2026),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: haImmagine
                              ? AppTheme.neonOrange
                              : Colors.white.withOpacity(0.1),
                          width: haImmagine ? 2 : 1,
                        ),
                        boxShadow: haImmagine
                            ? [
                                BoxShadow(
                                  color: AppTheme.neonOrange.withOpacity(0.15),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ]
                            : [],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (_fotoBytesLocali != null)
                              Image.memory(_fotoBytesLocali!, fit: BoxFit.cover)
                            else if (urlValido)
                              Image.network(
                                _fotoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        color: Colors.grey,
                                        size: 40,
                                      ),
                                    ),
                              )
                            else
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppTheme.neonOrange.withOpacity(
                                        0.1,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.add_a_photo_rounded,
                                      color: AppTheme.neonOrange,
                                      size: 30,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Carica immagine del campo',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Trascina o tocca per selezionare',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            if (haImmagine)
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: _selezionaFotoCampo,
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.7),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white24,
                                            width: 1,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.edit,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: _rimuoviFotoCampo,
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.redAccent.withOpacity(
                                            0.8,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.delete,
                                          color: Colors.white,
                                          size: 16,
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
                  ),

                  const SizedBox(height: 30),

                  // INFORMAZIONI GENERALI
                  const Text(
                    'DETTAGLI PRINCIPALI',
                    style: TextStyle(
                      color: AppTheme.neonOrange,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _nomeController,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: _stileInput(
                      'Nome Campo *',
                      Icons.sports_soccer_rounded,
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Inserisci il nome (es. Campo 1)'
                        : null,
                  ),

                  const SizedBox(height: 16),

                  // SWITCH COPERTO MODERN
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2026),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      title: const Text(
                        'Struttura Coperta',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        _isCoperto
                            ? 'Campo protetto da intemperie'
                            : 'Campo all\'aperto / Outdoor',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                      activeThumbColor: AppTheme.neonOrange,
                      value: _isCoperto,
                      onChanged: (val) => setState(() => _isCoperto = val),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // SPORT E TARIFFE
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'SPORT E TARIFFE ORARIE',
                        style: TextStyle(
                          color: AppTheme.neonOrange,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        '60 / 90 minuti',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // GRID / CARDS DEGLI SPORT
                  ..._sportDisponibili.map((sport) {
                    final sportId = sport['id'] as String;
                    final sportLabel = sport['label'] as String;
                    final sportIcon = sport['icon'] as IconData;
                    final bool isSelected = _sportSelezionati[sportId] ?? false;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF252830)
                            : const Color(0xFF1E2026),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.neonOrange
                              : Colors.white.withOpacity(0.05),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                _sportSelezionati[sportId] = !isSelected;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.neonOrange
                                        : Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    sportIcon,
                                    color: isSelected
                                        ? Colors.black
                                        : Colors.grey.shade400,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    sportLabel,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey.shade400,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? AppTheme.neonOrange
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected
                                          ? AppTheme.neonOrange
                                          : Colors.grey.shade600,
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.black,
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ),

                          if (isSelected) ...[
                            const SizedBox(height: 16),

                            for (final durata in [60, 90]) ...[
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  '$durata minuti',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                activeThumbColor: AppTheme.neonOrange,
                                value: _durateAbilitate[sportId]!.contains(
                                  durata,
                                ),
                                onChanged: (attivo) {
                                  setState(() {
                                    if (attivo) {
                                      _durateAbilitate[sportId]!.add(durata);
                                    } else {
                                      _durateAbilitate[sportId]!.remove(durata);
                                    }
                                  });
                                },
                              ),

                              if (_durateAbilitate[sportId]!.contains(durata))
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: TextFormField(
                                    controller:
                                        _prezziDurataControllers[sportId]![durata],
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    decoration: _stileInput(
                                      'Prezzo per $durata minuti',
                                      Icons.euro_symbol_rounded,
                                      prefixText: '€ ',
                                    ),
                                    validator: (val) {
                                      if (_sportSelezionati[sportId] != true ||
                                          !_durateAbilitate[sportId]!.contains(
                                            durata,
                                          )) {
                                        return null;
                                      }

                                      final prezzo = double.tryParse(
                                        (val ?? '').trim().replaceAll(',', '.'),
                                      );

                                      if (prezzo == null ||
                                          !prezzo.isFinite ||
                                          prezzo <= 0) {
                                        return 'Inserisci un prezzo valido';
                                      }

                                      return null;
                                    },
                                  ),
                                ),
                            ],
                          ],
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 35),

                  // BOTTONE SALVA
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.neonOrange.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isCaricamento ? null : _salvaCampo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.neonOrange,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: _isCaricamento
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              isModifica
                                  ? 'AGGIORNA CAMPO'
                                  : 'SALVA NUOVO CAMPO',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Mappa di default dei giocatori in base allo sport selezionato
  int _calcolaNumeroGiocatori(List<Map<String, dynamic>> tariffe) {
    if (tariffe.isEmpty) return 10;
    final primoSport = tariffe.first['sport'] as String;

    switch (primoSport) {
      case 'calcio_5':
        return 10;
      case 'calcio_6':
        return 12;
      case 'calcio_7':
        return 14;
      case 'calcio_8':
        return 16;
      case 'calcio_11':
        return 22;
      case 'padel':
        return 4;
      case 'tennis_singolo':
        return 2;
      case 'tennis_doppio':
        return 4;
      case 'basket':
        return 10;
      case 'pallavolo':
        return 12;
      default:
        return 10;
    }
  }
}
