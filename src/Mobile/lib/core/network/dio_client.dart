import 'package:dio/dio.dart';

import '../constants/api_config.dart';

typedef TokenReader = String? Function();
typedef OnUnauthorized = void Function();

/// WebApi `request.js` ile aynı mantık: Bearer token + 401’de oturumu kapat.
class DioClient {
  DioClient({
    required TokenReader readToken,
    OnUnauthorized? onUnauthorized,
  })  : _readToken = readToken,
        _onUnauthorized = onUnauthorized {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        headers: {'Accept': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          if (response.statusCode == 201) {
            final loc = response.headers.value('location');
            final data = response.data;
            if (loc != null && (data == '' || data == null)) {
              final id = loc.split('/').lastWhere((s) => s.isNotEmpty, orElse: () => '');
              response.data = {'id': id};
            }
          }
          handler.next(response);
        },
        onError: (err, handler) {
          if (err.response?.statusCode == 401) {
            _onUnauthorized?.call();
          }
          handler.next(err);
        },
      ),
    );
  }

  final TokenReader _readToken;
  final OnUnauthorized? _onUnauthorized;
  late final Dio _dio;

  Dio get dio => _dio;
}
