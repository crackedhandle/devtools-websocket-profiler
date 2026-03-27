import 'dart:io';
import 'socket_event.dart';
import 'dart:convert';

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

    final event = SocketEvent(
      id: id,
      timestamp: DateTime.now(),
      direction: "out",
      type: data is String ? "text" : "binary",
      size: data is String ? data.length : (data as List).length,
    );

    _events.add(event);

    if (enableLogging) {
      print("\n[VM EVENT]");
      print(jsonEncode(event.toJson()));
    }

    _socket.add("$id|$data");
  }

  void listen(void Function(dynamic) onData) {
    _socket.listen((data) {
      final parts = data.toString().split("|");
      final id = parts.first;
      final actualData = parts.sublist(1).join("|");

      final sentTime = _pending[id];
      final latency = sentTime != null
          ? DateTime.now().difference(sentTime).inMilliseconds
          : null;

      _pending.remove(id);

      final event = SocketEvent(
        id: id,
        timestamp: DateTime.now(),
        direction: "in",
        type: "text",
        size: actualData.length,
        latencyMs: latency,
      );

      _events.add(event);

      if (enableLogging) {
        print("\n[VM EVENT]");
        print(jsonEncode(event.toJson()));
      }

      onData(actualData);
    });
  }
}