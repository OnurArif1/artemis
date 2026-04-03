/// Gateway (WebApi vite proxy ile aynı): http://localhost:5091
///
/// Android emülatör: `flutter run --dart-define=API_HOST=10.0.2.2`
/// Fiziksel cihaz: bilgisayarınızın LAN IP’si (ör. 192.168.1.10)
class ApiConfig {
  ApiConfig._();

  static const String host = String.fromEnvironment(
    'API_HOST',
    defaultValue: 'localhost',
  );

  static const int port = int.fromEnvironment(
    'API_PORT',
    defaultValue: 5091,
  );

  /// WebApi `VITE_SIGNALR_HUB_URL` — Artemis.API SignalR (varsayılan 5094).
  static const int signalRPort = int.fromEnvironment(
    'SIGNALR_PORT',
    defaultValue: 5094,
  );

  static String get origin => 'http://$host:$port';

  /// `/api/topic/list` vb.
  static String get apiBaseUrl => '$origin/api';

  /// `/identity/connect/token`, `/identity/account/register`
  static String get identityBaseUrl => origin;

  /// `ChatHub` — `Program.cs` `MapHub<ChatHub>("/hubs/chat")`
  static String get signalRHubUrl => 'http://$host:$signalRPort/hubs/chat';
}
