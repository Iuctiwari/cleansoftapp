import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';

enum LocationFailure { serviceOff, denied, deniedForever, unavailable }

class LocationResult {
  const LocationResult.success(this.latitude, this.longitude) : failure = null;
  const LocationResult.failed(this.failure) : latitude = null, longitude = null;

  final double? latitude;
  final double? longitude;
  final LocationFailure? failure;

  bool get ok => failure == null;
}

/// Parts of an address guessed from a GPS position by the phone's own
/// geocoder (free, no API key). Any part may be empty.
class AddressGuess {
  const AddressGuess({
    this.streetArea = '',
    this.city = '',
    this.state = '',
    this.pincode = '',
  });

  final String streetArea;
  final String city;
  final String state;
  final String pincode;
}

/// GPS for "Use my current location". Asks for permission when needed.
class LocationService {
  const LocationService();

  Future<LocationResult> currentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationResult.failed(LocationFailure.serviceOff);
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationResult.failed(LocationFailure.deniedForever);
      }
      if (permission == LocationPermission.denied) {
        return const LocationResult.failed(LocationFailure.denied);
      }
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return LocationResult.success(position.latitude, position.longitude);
    } on Object {
      return const LocationResult.failed(LocationFailure.unavailable);
    }
  }

  Future<void> openSettings(LocationFailure failure) async {
    if (failure == LocationFailure.serviceOff) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }

  /// Best-effort reverse geocoding; returns an empty guess when unavailable.
  Future<AddressGuess> guessAddress(double latitude, double longitude) async {
    try {
      final List<geocoding.Placemark> places =
          await geocoding.Geocoding().placemarkFromCoordinates(latitude, longitude);
      if (places.isEmpty) return const AddressGuess();
      final geocoding.Placemark place = places.first;
      final String street = <String?>[place.street, place.subLocality]
          .where((String? part) => part != null && part.trim().isNotEmpty)
          .map((String? part) => part!.trim())
          .toSet()
          .join(', ');
      return AddressGuess(
        streetArea: street,
        city: place.locality ?? place.subAdministrativeArea ?? '',
        state: place.administrativeArea ?? '',
        pincode: place.postalCode ?? '',
      );
    } on Object {
      return const AddressGuess();
    }
  }
}
