class ApiConfig {
  // Default API base URL - change this if needed (e.g., your LAN IP)
  // Example: "http://192.168.1.36:3000"
  static String baseUrl = "https://102b12fe77dd.ngrok-free.app";

  // Helper to build API urls
  static String api(String path) {
    if (path.startsWith('/')) path = path.substring(1);
    return '$baseUrl/$path';
  }
}
