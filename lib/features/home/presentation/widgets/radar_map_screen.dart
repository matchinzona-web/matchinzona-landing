import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app_campi/core/services/location_provider.dart';
import 'package:app_campi/core/shared_widget/gps_banner.dart';
import 'package:app_campi/core/theme/app_theme.dart';
import 'package:app_campi/features/admin/presentation/pages/lista_campi_screen.dart';

class RadarMapScreen extends ConsumerStatefulWidget {
  const RadarMapScreen({super.key});

  @override
  ConsumerState<RadarMapScreen> createState() => _RadarMapScreenState();
}

class _RadarMapScreenState extends ConsumerState<RadarMapScreen>
    with WidgetsBindingObserver {
  final MapController _mapController = MapController();

  latlng.LatLng _posizioneUtente = const latlng.LatLng(41.9028, 12.4964);

  latlng.LatLng _centroRadar = const latlng.LatLng(41.9028, 12.4964);

  bool _mappaPronta = false;
  bool _isLoadingLocation = true;
  bool _permessoPosizioneConcesso = false;

  double _raggioKm = 5;

  List<Map<String, dynamic>> _centri = [];

  Timer? _cameraDebounce;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _ottieniPosizioneAttuale();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraDebounce?.cancel();
    _mapController.dispose();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _ottieniPosizioneAttuale();
    }
  }

  double _zoomPerRaggio() {
    if (_raggioKm <= 2) {
      return 13.2;
    }

    if (_raggioKm <= 5) {
      return 12.0;
    }

    return 11.0;
  }

  Future<void> _ottieniPosizioneAttuale() async {
    if (!mounted) return;

    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final gpsAttivo = await Geolocator.isLocationServiceEnabled();

      if (!gpsAttivo) {
        if (mounted) {
          setState(() {
            _permessoPosizioneConcesso = false;
            _isLoadingLocation = false;
          });
        }

        return;
      }

      final permission = await Geolocator.checkPermission();

      final concesso =
          permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;

      if (!concesso) {
        if (mounted) {
          setState(() {
            _permessoPosizioneConcesso = false;
            _isLoadingLocation = false;
          });
        }

        return;
      }

      if (mounted) {
        setState(() {
          _permessoPosizioneConcesso = true;
        });
      }

      Position? posizione;

      try {
        posizione = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 5));
      } catch (_) {
        posizione = await Geolocator.getLastKnownPosition();
      }

      if (posizione == null || !mounted) {
        setState(() {
          _isLoadingLocation = false;
        });

        return;
      }

      final nuovaPosizione = latlng.LatLng(
        posizione.latitude,
        posizione.longitude,
      );

      setState(() {
        _posizioneUtente = nuovaPosizione;
        _centroRadar = nuovaPosizione;
      });

      if (_mappaPronta) {
        _mapController.move(nuovaPosizione, _zoomPerRaggio());
      }

      await _caricaCentriSportiviVicini();
    } catch (e) {
      debugPrint('Errore posizione Radar: $e');

      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _caricaCentriSportiviVicini() async {
    if (!mounted || !_permessoPosizioneConcesso) {
      return;
    }

    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final List<dynamic> response = await Supabase.instance.client.rpc(
        'get_centri_vicini',
        params: {
          'lat_utente': _centroRadar.latitude,
          'lon_utente': _centroRadar.longitude,
          'raggio_km': _raggioKm,
        },
      );

      final risultati = <Map<String, dynamic>>[];

      for (final elemento in response) {
        try {
          final societa = Map<String, dynamic>.from(elemento as Map);

          final lat = (societa['latitudine'] as num).toDouble();

          final lng = (societa['longitudine'] as num).toDouble();

          final distanzaMetri = Geolocator.distanceBetween(
            _centroRadar.latitude,
            _centroRadar.longitude,
            lat,
            lng,
          );

          if (distanzaMetri > _raggioKm * 1000) {
            continue;
          }

          societa['_distanza_metri'] = distanzaMetri;

          risultati.add(societa);
        } catch (e) {
          debugPrint('Centro Radar non valido: $e');
        }
      }

      risultati.sort((a, b) {
        final distanzaA =
            (a['_distanza_metri'] as num?)?.toDouble() ?? double.infinity;

        final distanzaB =
            (b['_distanza_metri'] as num?)?.toDouble() ?? double.infinity;

        return distanzaA.compareTo(distanzaB);
      });

      if (!mounted) return;

      setState(() {
        _centri = risultati;
        _isLoadingLocation = false;
      });
    } catch (e) {
      debugPrint('Errore caricamento centri Radar: $e');

      if (mounted) {
        setState(() {
          _centri = [];
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    _centroRadar = camera.center;

    if (!hasGesture) {
      return;
    }

    _cameraDebounce?.cancel();

    _cameraDebounce = Timer(const Duration(milliseconds: 650), () {
      if (mounted) {
        _caricaCentriSportiviVicini();
      }
    });
  }

  Future<void> _centraSuDiMe() async {
    if (!_permessoPosizioneConcesso) {
      await _ottieniPosizioneAttuale();
      return;
    }

    _centroRadar = _posizioneUtente;

    _mapController.move(_posizioneUtente, _zoomPerRaggio());

    await _caricaCentriSportiviVicini();
  }

  Future<void> _impostaRaggio(double nuovoRaggio) async {
    if (_raggioKm == nuovoRaggio) {
      return;
    }

    setState(() {
      _raggioKm = nuovoRaggio;
    });

    _mapController.move(_centroRadar, _zoomPerRaggio());

    await _caricaCentriSportiviVicini();
  }

  String _testoDistanza(Map<String, dynamic> societa) {
    final metri = (societa['_distanza_metri'] as num?)?.toDouble();

    if (metri == null) {
      return '';
    }

    if (metri < 1000) {
      return '${metri.round()} m';
    }

    return '${(metri / 1000).toStringAsFixed(1)} km';
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    if (_permessoPosizioneConcesso) {
      markers.add(
        Marker(
          point: _posizioneUtente,
          width: 46,
          height: 46,
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.18),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.accent, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accent.withOpacity(0.35),
                  blurRadius: 14,
                ),
              ],
            ),
            child: const Icon(
              Icons.person_pin_circle_rounded,
              color: AppTheme.accent,
              size: 30,
            ),
          ),
        ),
      );
    }

    for (final societa in _centri) {
      try {
        final lat = (societa['latitudine'] as num).toDouble();

        final lng = (societa['longitudine'] as num).toDouble();

        markers.add(
          Marker(
            point: latlng.LatLng(lat, lng),
            width: 48,
            height: 48,
            child: GestureDetector(
              onTap: () {
                _mostraDettaglioCentro(context, societa);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.accent, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accent.withOpacity(0.25),
                      blurRadius: 12,
                    ),
                    const BoxShadow(
                      color: Colors.black38,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.stadium_rounded,
                  color: AppTheme.accent,
                  size: 24,
                ),
              ),
            ),
          ),
        );
      } catch (_) {}
    }

    return markers;
  }

  void _mostraDettaglioCentro(
    BuildContext context,
    Map<String, dynamic> societa,
  ) {
    final distanza = _testoDistanza(societa);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 18,
              bottom: MediaQuery.of(context).viewInsets.bottom + 28,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade700,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withOpacity(0.14),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.stadium_rounded,
                        color: AppTheme.accent,
                        size: 28,
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            societa['nome_societa'] ?? 'Centro Sportivo',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          if (distanza.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Text(
                              distanza,
                              style: const TextStyle(
                                color: AppTheme.accent,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: AppTheme.textSecondary,
                      size: 18,
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: Text(
                        societa['indirizzo'] ?? 'Indirizzo non disponibile',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ListaCampiScreen(societa: societa),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: AppTheme.darkBg,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text(
                      'ESPLORA QUESTO CENTRO',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<bool>>(gpsAttivoProvider, (previous, next) {
      final primaSpento = previous?.value == false;

      final oraAcceso = next.value == true;

      if (primaSpento && oraAcceso && mounted) {
        _ottieniPosizioneAttuale();
      }
    });

    ref.listen<AsyncValue<LocationPermission>>(permessoPosizioneProvider, (
      previous,
      next,
    ) {
      final permission = next.value;

      final concesso =
          permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;

      if (concesso && mounted) {
        _ottieniPosizioneAttuale();
      }
    });

    final gpsAttivo = ref.watch(gpsAttivoProvider).value ?? false;

    final permission =
        ref.watch(permessoPosizioneProvider).value ?? LocationPermission.denied;

    final permessoConcesso =
        permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _centroRadar,
                initialZoom: _zoomPerRaggio(),
                minZoom: 5,
                maxZoom: 18,
                onMapReady: () {
                  _mappaPronta = true;

                  if (_permessoPosizioneConcesso) {
                    _mapController.move(_centroRadar, _zoomPerRaggio());
                  }
                },
                onPositionChanged: _onPositionChanged,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.matchly.app',
                  maxZoom: 19,
                ),

                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _centroRadar,
                      radius: _raggioKm * 1000,
                      useRadiusInMeter: true,
                      color: AppTheme.accent.withOpacity(0.08),
                      borderColor: AppTheme.accent.withOpacity(0.9),
                      borderStrokeWidth: 2.5,
                    ),
                  ],
                ),

                MarkerLayer(markers: _buildMarkers()),
              ],
            ),
          ),

          Positioned.fill(
            child: IgnorePointer(
              child: Container(color: AppTheme.darkBg.withOpacity(0.12)),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.darkBg.withOpacity(0.88),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.cardBorder),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.radar_rounded,
                          color: AppTheme.accent,
                          size: 24,
                        ),

                        const SizedBox(width: 10),

                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'RADAR CENTRI',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Sposta la mappa per esplorare',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (_isLoadingLocation)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.accent,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                if (!gpsAttivo || !permessoConcesso)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: GpsBanner(),
                  ),

                const Spacer(),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
                      _RaggioButton(
                        label: '2 km',
                        selected: _raggioKm == 2,
                        onTap: () => _impostaRaggio(2),
                      ),

                      const SizedBox(width: 8),

                      _RaggioButton(
                        label: '5 km',
                        selected: _raggioKm == 5,
                        onTap: () => _impostaRaggio(5),
                      ),

                      const SizedBox(width: 8),

                      _RaggioButton(
                        label: '10 km',
                        selected: _raggioKm == 10,
                        onTap: () => _impostaRaggio(10),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.darkBg.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.cardBorder),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black45,
                          blurRadius: 14,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _isLoadingLocation
                                ? 'Scansione in corso...'
                                : _centri.isEmpty
                                ? 'Nessun centro entro ${_raggioKm.toStringAsFixed(0)} km'
                                : '${_centri.length} ${_centri.length == 1 ? 'centro trovato' : 'centri trovati'}',
                            style: TextStyle(
                              color: _isLoadingLocation
                                  ? AppTheme.accent
                                  : AppTheme.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        GestureDetector(
                          onTap: _isLoadingLocation
                              ? null
                              : _caricaCentriSportiviVicini,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withOpacity(0.12),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.accent.withOpacity(0.45),
                              ),
                            ),
                            child: const Icon(
                              Icons.refresh_rounded,
                              color: AppTheme.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            right: 18,
            bottom: 185,
            child: SafeArea(
              child: GestureDetector(
                onTap: _centraSuDiMe,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.darkBg.withOpacity(0.92),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.accent.withOpacity(0.6)),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.my_location_rounded,
                    color: AppTheme.accent,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            right: 10,
            bottom: 4,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                color: Colors.white.withOpacity(0.78),
                child: const Text(
                  '© OpenStreetMap contributors',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RaggioButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RaggioButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.accent
                : AppTheme.darkBg.withOpacity(0.9),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selected ? AppTheme.accent : AppTheme.cardBorder,
            ),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
          ),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              color: selected ? AppTheme.darkBg : AppTheme.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
