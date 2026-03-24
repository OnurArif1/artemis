import 'package:dio/dio.dart';

/// WebApi `RoomService.js`
class RoomService {
  RoomService(this._dio);

  final Dio _dio;

  Future<dynamic> getList([Map<String, dynamic>? filter]) async {
    final r = await _dio.get<dynamic>('/room/list', queryParameters: filter);
    return r.data;
  }

  Future<void> create(Map<String, dynamic> payload) async {
    await _dio.post<void>('/room/create', data: payload);
  }

  Future<void> addPartyToRoom(Map<String, dynamic> payload) async {
    await _dio.post<void>('/room/addParty', data: payload);
  }

  Future<void> addPartiesToRoom(int roomId, List<int> partyIds) async {
    await _dio.post<void>(
      '/room/addParty',
      data: {'roomId': roomId, 'partyIds': partyIds},
    );
  }

  Future<void> update(Map<String, dynamic> payload) async {
    await _dio.post<void>('/room/update', data: payload);
  }

  Future<void> delete(int roomId) async {
    await _dio.delete<void>('/room/delete/$roomId');
  }

  Future<dynamic> getLookup([Map<String, dynamic>? filter]) async {
    final r = await _dio.get<dynamic>('/room/lookup', queryParameters: filter);
    return r.data;
  }
}
