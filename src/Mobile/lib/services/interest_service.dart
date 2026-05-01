import 'package:dio/dio.dart';

class InterestService {
  InterestService(this._dio);

  final Dio _dio;

  static Options _okOnly() => Options(
        validateStatus: (s) => s != null && s >= 200 && s < 300,
      );

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

  /// [email] isteğe bağlı; Authorization Bearer ile gönderildiğinde sunucu JWT içindeki e-postayı kullanır.
  Future<dynamic> getMyInterests({String? email}) async {
    final r = await _dio.get<dynamic>(
      '/partyInterest/my-interests',
      queryParameters: {
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      },
      options: _okOnly(),
    );
    return r.data;
  }
}
