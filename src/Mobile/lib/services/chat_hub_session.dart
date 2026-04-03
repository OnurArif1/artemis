import 'package:signalr_netcore/signalr_client.dart';

import '../core/constants/api_config.dart';

/// WebApi `SignalRService.js` ile aynı hub: `JoinRoom`, `ReceiveMessage`, `SendComment` vb.
class ChatHubSession {
  ChatHubSession({required this.getAccessToken});

  final Future<String?> Function() getAccessToken;

  HubConnection? _hub;

  bool get isConnected =>
      _hub != null && _hub!.state == HubConnectionState.Connected;

  HubConnection get requireHub {
    final h = _hub;
    if (h == null) {
      throw StateError('SignalR bağlı değil');
    }
    return h;
  }

  Future<void> connect() async {
    if (_hub != null) {
      if (_hub!.state == HubConnectionState.Connected) return;
      await _hub!.stop();
      _hub = null;
    }

    final token = await getAccessToken();
    final builder = HubConnectionBuilder()
      ..withUrl(
        ApiConfig.signalRHubUrl,
        options: HttpConnectionOptions(
          accessTokenFactory: (token == null || token.isEmpty)
              ? null
              : () async => token,
          transport: HttpTransportType.WebSockets,
        ),
      )
      ..withAutomaticReconnect();

    _hub = builder.build();
    await _hub!.start();
    try {
      await _hub!.invoke('GetConnectionId');
    } catch (_) {
      // Bazı sürümlerde isteğe bağlı
    }
  }

  Future<void> disconnect() async {
    final h = _hub;
    if (h == null) return;
    try {
      await h.stop();
    } catch (_) {
      // ignore
    }
    _hub = null;
  }

  Future<void> joinRoom(int roomId) async {
    await requireHub.invoke('JoinRoom', args: [roomId]);
  }

  Future<void> leaveRoom(int roomId) async {
    if (!isConnected) return;
    try {
      await requireHub.invoke('LeaveRoom', args: [roomId]);
    } catch (_) {
      // ignore
    }
  }

  Future<void> joinTopic(int topicId) async {
    await requireHub.invoke('JoinTopic', args: [topicId]);
  }

  Future<void> leaveTopic(int topicId) async {
    if (!isConnected) return;
    try {
      await requireHub.invoke('LeaveTopic', args: [topicId]);
    } catch (_) {
      // ignore
    }
  }

  Future<void> sendRoomMessage({
    required int partyId,
    required int roomId,
    required String message,
    List<int>? mentionedPartyIds,
  }) async {
    await requireHub.invoke(
      'SendMessage',
      args: <Object>[
        partyId,
        roomId,
        message,
        mentionedPartyIds ?? <int>[],
      ],
    );
  }

  Future<void> sendTopicComment({
    required int partyId,
    required int topicId,
    required String message,
  }) async {
    await requireHub.invoke(
      'SendComment',
      args: [partyId, topicId, message],
    );
  }

  void onReceiveMessage(MethodInvocationFunc handler) {
    requireHub.on('ReceiveMessage', handler);
  }

  void offReceiveMessage(MethodInvocationFunc handler) {
    requireHub.off('ReceiveMessage', method: handler);
  }

  void onReceiveComment(MethodInvocationFunc handler) {
    requireHub.on('ReceiveComment', handler);
  }

  void offReceiveComment(MethodInvocationFunc handler) {
    requireHub.off('ReceiveComment', method: handler);
  }

  void onReceiveError(MethodInvocationFunc handler) {
    requireHub.on('ReceiveError', handler);
  }

  void offReceiveError(MethodInvocationFunc handler) {
    requireHub.off('ReceiveError', method: handler);
  }
}
