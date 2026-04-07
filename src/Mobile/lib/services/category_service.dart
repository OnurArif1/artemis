import 'package:dio/dio.dart';

class CategoryService {
  CategoryService(this._dio);

  final Dio _dio;

  Future<dynamic> getList([Map<String, dynamic>? filter]) async {
    final r = await _dio.get<dynamic>('/category/list', queryParameters: filter);
    return r.data;
  }

  Future<void> create(Map<String, dynamic> payload) async {
    await _dio.post<void>('/category/create', data: payload);
  }

  Future<void> update(Map<String, dynamic> payload) async {
    await _dio.post<void>('/category/update', data: payload);
  }

  Future<void> delete(int categoryId) async {
    await _dio.delete<void>('/category/delete/$categoryId');
  }

  Future<dynamic> getLookup([Map<String, dynamic>? filter]) async {
    final r = await _dio.get<dynamic>('/category/lookup', queryParameters: filter);
    return r.data;
  }
}
