import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'socket_event.dart';

class ProfileableWebSocket {
  final WebSocket _socket;
  final List<SocketEvent> _events = [];
  int _counter = 0;
  final Map<String, DateTime> _pending = {};
  final bool enableLogging;

  ProfileableWebSocket(this._socket, {this.enableLogging = true});

  List<SocketEvent> get events => _events;

  void send(dynamic data) {
    final id = (_counter++).toString();
    _pending[id] = DateTime.now();
    final isBinary = data is List;
    final event = SocketEvent(
      id: id,
      timestamp: DateTime.now(),
      direction: "out",
      type: isBinary ? "binary" : "text",
      size: isBinary ? (data as List).length : (data as String).length,
    );
    _events.add(event);
   if (enableLogging) {
  print("\n[VM EVENT]");
  print(jsonEncode(event.toJson()));
  Timeline.instantSync('WebSocket Frame', arguments: event.toJson());
}
    _socket.add(isBinary ? data : "$id|$data");
  }

  void listen(
    void Function(dynamic)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    _socket.listen(
      (data) {
        final isBinary = data is List;
        String id = "";
        dynamic actualData = data;

        if (!isBinary) {
          final parts = data.toString().split("|");
          id = parts.first;
          actualData = parts.sublist(1).join("|");
        }

        final sentTime = _pending[id];
        final latency = sentTime != null
            ? DateTime.now().difference(sentTime).inMilliseconds
            : null;
        _pending.remove(id);

        final event = SocketEvent(
          id: id,
          timestamp: DateTime.now(),
          direction: "in",
          type: isBinary ? "binary" : "text",
          size: isBinary ? (data as List).length : actualData.toString().length,
          latencyMs: latency,
        );
        _events.add(event);
        if (enableLogging) {
  print("\n[VM EVENT]");
  print(jsonEncode(event.toJson()));
  Timeline.instantSync('WebSocket Frame', arguments: event.toJson());
}
        onData?.call(actualData);
      },
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}