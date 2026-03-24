/// Backend API base URL. Must match the machine where the MEZAHUB backend is running.
///
/// • Physical device (same WiFi as your PC): use your PC's IP, e.g. http://192.168.x.x:5000/api/v1
///   Get IP: on Linux run `hostname -I | awk '{print \$1}'` or check your router.
/// • Android emulator: use http://10.0.2.2:5000/api/v1
///
/// Before running the app, start the backend: cd mezahub-backend && python run.py
const String kBackendBaseUrl = 'http://192.168.150.205:5000/api/v1';
