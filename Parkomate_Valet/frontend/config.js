window.APP_CONFIG = {
  API_BASE_URL: window.location.hostname === "localhost"
    ? "http://localhost:3000"
    : "https://102b12fe77dd.ngrok-free.app"   // replace with your LAN IP or AWS domain
};
