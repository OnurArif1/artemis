import 'package:dio/dio.dart';

class MessageService {
  MessageService(this._dio);

  final Dio _dio;

  Future<dynamic> getList([Map<String, dynamic>? filter]) async {
    final r = await _dio.get<dynamic>('/message/list', queryParameters: filter);
    return r.data;
  }
}
