class UserSession {
  final String id;
  final String role;
  final int siteNo;
  String? token; // The authentication token

  UserSession({
    required this.id,
    required this.role,
    required this.siteNo,
    this.token,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      id: json['id'] as String,
      role: json['role'] as String,
      siteNo: (json['site_no'] is int) ? json['site_no'] as int : int.parse(json['site_no'].toString()),
      token: json['token'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'site_no': siteNo,
      'token': token,
    };
  }
}