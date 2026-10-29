import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final String formattedCoordinates;
  final bool isLiveGps;
  final String? errorMessage;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.formattedCoordinates,
    required this.isLiveGps,
    this.errorMessage,
  });
}

class LocationService {
  /// Obtiene la ubicación geográfica actual del dispositivo/navegador
  static Future<LocationResult> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationResult(
          latitude: 18.4861,
          longitude: -69.9312,
          formattedCoordinates: '18.4861, -69.9312',
          isLiveGps: false,
          errorMessage: 'Los servicios de geolocalización están desactivados en el navegador/dispositivo.',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const LocationResult(
            latitude: 18.4861,
            longitude: -69.9312,
            formattedCoordinates: '18.4861, -69.9312',
            isLiveGps: false,
            errorMessage: 'Permiso de ubicación denegado por el usuario.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(
          latitude: 18.4861,
          longitude: -69.9312,
          formattedCoordinates: '18.4861, -69.9312',
          isLiveGps: false,
          errorMessage: 'El permiso de ubicación fue denegado permanentemente en el navegador.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      final lat = double.parse(position.latitude.toStringAsFixed(6));
      final lng = double.parse(position.longitude.toStringAsFixed(6));

      return LocationResult(
        latitude: lat,
        longitude: lng,
        formattedCoordinates: '$lat, $lng',
        isLiveGps: true,
      );
    } catch (e) {
      debugPrint('Aviso obteniendo geolocalización: $e');
      return LocationResult(
        latitude: 18.4861,
        longitude: -69.9312,
        formattedCoordinates: '18.4861, -69.9312',
        isLiveGps: false,
        errorMessage: e.toString(),
      );
    }
  }
}
