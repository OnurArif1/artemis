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

  static const int signalRPort = int.fromEnvironment(
    'SIGNALR_PORT',
    defaultValue: 5094,
  );

  static String get origin => 'http://$host:$port';

  static String get apiBaseUrl => '$origin/api';

  static String get identityBaseUrl => origin;

  static String get signalRHubUrl => 'http://$host:$signalRPort/hubs/chat';
}
