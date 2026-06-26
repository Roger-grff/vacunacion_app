import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapPickerView extends StatefulWidget {
  final LatLng? initialPosition;

  const MapPickerView({super.key, this.initialPosition});

  @override
  State<MapPickerView> createState() => _MapPickerViewState();
}

class _MapPickerViewState extends State<MapPickerView> {
  LatLng? _selectedPosition;
  bool _isLoadingLocation = true;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    if (widget.initialPosition != null) {
      _selectedPosition = widget.initialPosition;
      _isLoadingLocation = false;
    } else {
      _getCurrentLocation();
    }
  }

  // Obtener la ubicación GPS actual del dispositivo
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verificar si el servicio GPS está activo
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor activa el GPS de tu dispositivo')),
        );
      }
      setState(() {
        _selectedPosition = const LatLng(-0.1807, -78.4678); // Quito, Ecuador por defecto
        _isLoadingLocation = false;
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permisos de ubicación denegados')),
          );
        }
        setState(() {
          _selectedPosition = const LatLng(-0.1807, -78.4678);
          _isLoadingLocation = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _selectedPosition = const LatLng(-0.1807, -78.4678);
        _isLoadingLocation = false;
      });
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() {
        _selectedPosition = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });
    } catch (e) {
      print('Error al obtener ubicación GPS: $e');
      setState(() {
        _selectedPosition = const LatLng(-0.1807, -78.4678);
        _isLoadingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Ubicación'),
        backgroundColor: const Color(0xFF203A43),
        foregroundColor: Colors.white,
        actions: [
          if (_selectedPosition != null)
            IconButton(
              icon: const Icon(Icons.check, size: 28),
              onPressed: () {
                Navigator.of(context).pop(_selectedPosition);
              },
            )
        ],
      ),
      body: _isLoadingLocation
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF203A43)),
                  SizedBox(height: 16),
                  Text('Obteniendo ubicación GPS actual...'),
                ],
              ),
            )
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedPosition!,
                    initialZoom: 16.0,
                    onTap: (tapPosition, point) {
                      setState(() {
                        _selectedPosition = point;
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.vacunacion.app',
                    ),
                    if (_selectedPosition != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedPosition!,
                            width: 60,
                            height: 60,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 45,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                // Botón flotante para regresar al GPS actual
                Positioned(
                  bottom: 90,
                  right: 16,
                  child: FloatingActionButton(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF203A43),
                    child: const Icon(Icons.my_location),
                    onPressed: () async {
                      setState(() {
                        _isLoadingLocation = true;
                      });
                      await _getCurrentLocation();
                      if (_selectedPosition != null) {
                        _mapController.move(_selectedPosition!, 16.0);
                      }
                    },
                  ),
                ),
                // Panel inferior de confirmación
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 6,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.pin_drop, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Coordenadas: ${_selectedPosition!.latitude.toStringAsFixed(6)}, ${_selectedPosition!.longitude.toStringAsFixed(6)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop(_selectedPosition);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF203A43),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Confirmar Ubicación'),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
    );
  }
}
