import 'package:dio/dio.dart';

class PartyPurposeService {
  PartyPurposeService(this._dio);

  final Dio _dio;

  Future<dynamic> savePartyPurposes({
    required String email,
    required List<int> purposeTypes,
  }) async {
    final r = await _dio.post<dynamic>(
      '/partyPurpose/save',
      data: {'email': email, 'purposeTypes': purposeTypes},
    );
    return r.data;
  }

  Future<dynamic> getMyPurposes({String? email}) async {
    final r = await _dio.get<dynamic>(
      '/partyPurpose/my-purposes',
      queryParameters: {
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      },
      options: Options(
        validateStatus: (s) => s != null && s >= 200 && s < 300,
      ),
    );
    return r.data;
  }
}
