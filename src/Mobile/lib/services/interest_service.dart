import 'package:dio/dio.dart';

class InterestService {
  InterestService(this._dio);

  final Dio _dio;

  Future<dynamic> getList() async {
    final r = await _dio.get<dynamic>('/interest/list');
    return r.data;
  }

  Future<dynamic> savePartyInterests({
    required String email,
    required List<int> interestIds,
  }) async {
    final r = await _dio.post<dynamic>(
      '/partyInterest/save',
      data: {'email': email, 'interestIds': interestIds},
    );
    return r.data;
  }

  Future<dynamic> getMyInterests() async {
    final r = await _dio.get<dynamic>('/partyInterest/my-interests');
    return r.data;
  }
}
