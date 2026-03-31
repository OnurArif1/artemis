import 'package:dio/dio.dart';

/// WebApi `CommentService.js`
class CommentService {
  CommentService(this._dio);

  final Dio _dio;

  Future<dynamic> getList([Map<String, dynamic>? filter]) async {
    final r = await _dio.get<dynamic>('/comment/list', queryParameters: filter);
    return r.data;
  }

  Future<dynamic> create(Map<String, dynamic> payload) async {
    final r = await _dio.post<dynamic>('/comment/create', data: payload);
    return r.data;
  }
}
