import 'package:socket_io_client/socket_io_client.dart' as socket_io;

typedef NotificationSocketHandler =
    void Function(Map<String, dynamic> payload);

/// Thin wrapper around the Notification Service's `/notifications`
/// Socket.IO gateway. Reconnection is handled by the socket_io_client
/// package's own defaults, so a dropped connection resumes automatically
/// once the network/socket is available again.
class NotificationSocketService {
  socket_io.Socket? _socket;

  bool get isConnected => _socket?.connected ?? false;

  void connect({
    required Uri baseUri,
    required String authorizationHeader,
    required String branchId,
    required NotificationSocketHandler onNew,
    required NotificationSocketHandler onRead,
    required NotificationSocketHandler onReadAll,
  }) {
    disconnect();
    final socket_io.Socket socket = socket_io.io(
      '$baseUri/notifications',
      socket_io.OptionBuilder()
          .setTransports(<String>['websocket'])
          .disableAutoConnect()
          .setAuth(<String, dynamic>{'token': authorizationHeader})
          .setQuery(<String, dynamic>{'branchId': branchId})
          .build(),
    );
    socket
      ..on('notification:new', (Object? data) => _emit(data, onNew))
      ..on('notification:read', (Object? data) => _emit(data, onRead))
      ..on('notification:read-all', (Object? data) => _emit(data, onReadAll))
      ..connect();
    _socket = socket;
  }

  void disconnect() {
    final socket_io.Socket? current = _socket;
    _socket = null;
    current
      ?..clearListeners()
      ..disconnect()
      ..dispose();
  }

  void _emit(Object? data, NotificationSocketHandler handler) {
    if (data is Map) handler(Map<String, dynamic>.from(data));
  }
}
