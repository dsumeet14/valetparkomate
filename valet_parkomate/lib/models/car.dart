// lib/models/car.dart
class Car {
  final String carNo;
  final String? valetId;
  final String? status;
  final String? parkingSpot;
  final String? driverAssignedForParking;
  final String? driverAssignedForBringing;
  final String? phoneNumber;
  final DateTime? timestampCarInRequest;
  final DateTime? timestampCarOutRequest; // Added missing field
  final bool seenParking; 
  final bool seenBringing; 

  Car({
    required this.carNo,
    this.valetId,
    this.status,
    this.parkingSpot,
    this.driverAssignedForParking,
    this.driverAssignedForBringing,
    this.phoneNumber,
    this.timestampCarInRequest,
    this.timestampCarOutRequest, // Added to constructor
    this.seenParking = false, 
    this.seenBringing = false, 
  });

  factory Car.fromJson(Map<String, dynamic> j) {
    DateTime? parseTs(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString());
      } catch (e) {
        return null;
      }
    }

    // Helper to safely parse boolean from various sources (bool, int 1/0, String '1'/'0')
    bool safeBool(dynamic v) {
      if (v is bool) return v;
      if (v is int) return v == 1;
      if (v is String) return v == '1' || v.toLowerCase() == 'true';
      return false;
    }

    return Car(
      carNo: j['car_no']?.toString() ?? '',
      valetId: j['valet_id']?.toString(),
      status: j['status']?.toString(),
      parkingSpot: j['parking_spot']?.toString(),
      driverAssignedForParking: j['driver_assigned_for_parking']?.toString(),
      driverAssignedForBringing: j['driver_assigned_for_bringing']?.toString(),
      phoneNumber: j['phone_number']?.toString(),
      timestampCarInRequest: parseTs(j['timestamp_car_in_request']),
      timestampCarOutRequest: parseTs(j['timestamp_car_out_request']), // Added to fromJson
      seenParking: safeBool(j['seen_parking']),
      seenBringing: safeBool(j['seen_bringing']),
    );
  }

  Map<String, dynamic> toJson() => {
        'car_no': carNo,
        'valet_id': valetId,
        'status': status,
        'parking_spot': parkingSpot,
        'driver_assigned_for_parking': driverAssignedForParking,
        'driver_assigned_for_bringing': driverAssignedForBringing,
        'phone_number': phoneNumber,
        'timestamp_car_in_request': timestampCarInRequest?.toIso8601String(),
        'timestamp_car_out_request': timestampCarOutRequest?.toIso8601String(),
        'seen_parking': seenParking ? 1 : 0,
        'seen_bringing': seenBringing ? 1 : 0,
      };
}