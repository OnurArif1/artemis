import 'package:dio/dio.dart';

/// WebApi `TopicService.js`
class TopicService {
  TopicService(this._dio);

  final Dio _dio;

  Future<dynamic> getList([Map<String, dynamic>? filter]) async {
    final r = await _dio.get<dynamic>('/topic/list', queryParameters: filter);
    return r.data;
  }

  Future<dynamic> getById(int id) async {
    final r = await _dio.get<dynamic>('/topic/$id');
    return r.data;
  }

  Future<dynamic> create(Map<String, dynamic> payload) async {
    final r = await _dio.post<dynamic>('/topic/create', data: payload);
    return r.data;
  }

  Future<dynamic> update(Map<String, dynamic> payload) async {
    final r = await _dio.post<dynamic>('/topic/update', data: payload);
    return r.data;
  }
}
