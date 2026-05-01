import 'package:dio/dio.dart';

class PartyService {
  PartyService(this._dio);

  final Dio _dio;

  Future<dynamic> getList([Map<String, dynamic>? filter]) async {
    final r = await _dio.get<dynamic>('/party/list', queryParameters: filter);
    return r.data;
  }

  Future<dynamic> getLookup([Map<String, dynamic>? filter]) async {
    final r = await _dio.get<dynamic>('/party/lookup', queryParameters: filter);
    return r.data;
  }

  /// [email] isteğe bağlı; Bearer token varsa sunucu JWT claim'lerinden çözer.
  Future<dynamic> getProfile({String? email}) async {
    final r = await _dio.get<dynamic>(
      '/party/profile',
      queryParameters: {
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      },
      options: Options(
        validateStatus: (s) => s != null && s >= 200 && s < 300,
      ),
    );
    return r.data;
  }

  Future<void> create(Map<String, dynamic> payload) async {
    await _dio.post<void>('/party/create', data: payload);
  }

  Future<void> update(Map<String, dynamic> payload) async {
    await _dio.post<void>('/party/update', data: payload);
  }

  Future<void> delete(int partyId) async {
    await _dio.delete<void>('/party/delete/$partyId');
  }

  Future<void> updateProfile({
    required String email,
    String? partyName,
    String? description,
  }) async {
    await _dio.post<void>(
      '/party/update-profile',
      data: {
        'email': email,
        if (partyName != null && partyName.trim().isNotEmpty)
          'partyName': partyName.trim(),
        'description': description,
      },
    );
  }

  Future<void> updateSubscription({
    required String email,
    required int subscriptionType,
  }) async {
    await _dio.post<void>(
      '/party/update-subscription',
      data: {
        'email': email.trim(),
        'subscriptionType': subscriptionType,
      },
    );
  }
}
