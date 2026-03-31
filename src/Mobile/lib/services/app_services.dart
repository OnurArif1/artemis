import 'package:dio/dio.dart';

import 'category_service.dart';
import 'comment_service.dart';
import 'interest_service.dart';
import 'party_purpose_service.dart';
import 'party_service.dart';
import 'room_service.dart';
import 'topic_service.dart';

/// WebApi’deki servis sınıflarının tek giriş noktası.
class AppServices {
  AppServices(Dio dio)
      : topics = TopicService(dio),
        categories = CategoryService(dio),
        rooms = RoomService(dio),
        parties = PartyService(dio),
        interests = InterestService(dio),
        partyPurposes = PartyPurposeService(dio),
        comments = CommentService(dio);

  final TopicService topics;
  final CategoryService categories;
  final RoomService rooms;
  final PartyService parties;
  final InterestService interests;
  final PartyPurposeService partyPurposes;
  final CommentService comments;
}
