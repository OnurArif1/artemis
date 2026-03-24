import 'package:dio/dio.dart';

/// WebApi `PartyPurposeService.js`
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
}
