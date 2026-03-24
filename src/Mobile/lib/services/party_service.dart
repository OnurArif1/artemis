import 'package:dio/dio.dart';

/// WebApi `PartyService.js`
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
    required String partyName,
    String? description,
  }) async {
    await _dio.post<void>(
      '/party/update-profile',
      data: {
        'email': email,
        'partyName': partyName,
        'description': description,
      },
    );
  }
}
