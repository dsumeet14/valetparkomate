// lib/models/driver_stats.dart
class DriverStats {
  final String driverId;
  final String? driverName;
  final String? driverPhoto; // base64 or url
  final int totalJobsToday;
  final int parkingJobsToday;
  final int retrievalJobsToday;
  final int currentAssignedJobs;
  final bool onDuty;
  final DateTime? lastLogin;
  final DateTime? lastLogout;

  DriverStats({
    required this.driverId,
    this.driverName,
    this.driverPhoto,
    required this.totalJobsToday,
    required this.parkingJobsToday,
    required this.retrievalJobsToday,
    required this.currentAssignedJobs,
    required this.onDuty,
    this.lastLogin,
    this.lastLogout,
  });

  factory DriverStats.fromJson(Map<String, dynamic> j) {
    int safeInt(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }
    
    // Helper to safely parse boolean from various sources (bool, int 1/0, String '1'/'0')
    bool safeBool(dynamic v) {
      if (v is bool) return v;
      if (v is int) return v == 1;
      if (v is String) return v == '1' || v.toLowerCase() == 'true';
      return false;
    }

    return DriverStats(
      // The ID can come as 'driver_id' (from stats/pool) or 'id' (from older API)
      driverId: j['driver_id']?.toString() ?? j['id']?.toString() ?? 'unknown',
      driverName: j['driver_name'],
      driverPhoto: j['driver_photo'],
      totalJobsToday: safeInt(j['total_jobs_today']),
      parkingJobsToday: safeInt(j['parking_jobs_today']),
      retrievalJobsToday: safeInt(j['retrieval_jobs_today']),
      currentAssignedJobs: safeInt(j['current_assigned_jobs']),
      // FIX: active inactive is still swapped - negate the API value.
      onDuty: !safeBool(j['on_duty']), 
      lastLogin: j['last_login'] != null ? DateTime.tryParse(j['last_login']) : null,
      lastLogout: j['last_logout'] != null ? DateTime.tryParse(j['last_logout']) : null,
    );
  }
}