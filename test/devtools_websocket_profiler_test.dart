import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:devtools_websocket_profiler/profileable_websocket.dart';

void main() {
  group('ProfileableWebSocket', () {
    late HttpServer server;
    late int port;

    setUp(() async {
      server = await HttpServer.bind('127.0.0.1', 0);
      port = server.port;
      server.transform(WebSocketTransformer()).listen((WebSocket socket) {
        socket.listen((data) {
          socket.add(data);
        });
      });
    });

    tearDown(() async {
      await server.close(force: true);
    });

    test('captures outgoing event correctly', () async {
      final socket = await WebSocket.connect('ws://127.0.0.1:$port');
      final profiled = ProfileableWebSocket(socket, enableLogging: false);
      profiled.send("hello");
      await Future.delayed(Duration(milliseconds: 50));
      expect(profiled.events.isNotEmpty, true);
      expect(profiled.events.first.direction, "out");
      expect(profiled.events.first.size, 5);
    });

    test('captures incoming event and pairs with same id', () async {
      final socket = await WebSocket.connect('ws://127.0.0.1:$port');
      final profiled = ProfileableWebSocket(socket, enableLogging: false);
      final completer = Completer<void>();
      profiled.listen((_) {
        if (!completer.isCompleted) completer.complete();
      });
      profiled.send("test");
      await completer.future.timeout(Duration(seconds: 2));
      final outEvent = profiled.events.firstWhere((e) => e.direction == "out");
      final inEvent = profiled.events.firstWhere((e) => e.direction == "in");
      expect(outEvent.id, inEvent.id);
    });

    test('calculates latency for response', () async {
      final socket = await WebSocket.connect('ws://127.0.0.1:$port');
      final profiled = ProfileableWebSocket(socket, enableLogging: false);
      final completer = Completer<void>();
      profiled.listen((_) {
        if (!completer.isCompleted) completer.complete();
      });
      profiled.send("latency");
      await completer.future.timeout(Duration(seconds: 2));
      final inEvent = profiled.events.firstWhere((e) => e.direction == "in");
      expect(inEvent.latencyMs, isNotNull);
      expect(inEvent.latencyMs!, greaterThanOrEqualTo(0));
    });

    test('stores multiple events in buffer', () async {
      final socket = await WebSocket.connect('ws://127.0.0.1:$port');
      final profiled = ProfileableWebSocket(socket, enableLogging: false);
      final received = <dynamic>[];
      final done = Completer<void>();
      profiled.listen((data) {
        received.add(data);
        if (received.length == 3) done.complete();
      });
      profiled.send("one");
      profiled.send("two");
      profiled.send("three");
      await done.future.timeout(Duration(seconds: 2));
      expect(profiled.events, hasLength(6));
    });

    test('binary data recorded with binary type', () async {
      final socket = await WebSocket.connect('ws://127.0.0.1:$port');
      final profiled = ProfileableWebSocket(socket, enableLogging: false);
      final completer = Completer<void>();
      profiled.listen((_) {
        if (!completer.isCompleted) completer.complete();
      });
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      profiled.send(bytes);
      await completer.future.timeout(Duration(seconds: 2));
      final sent = profiled.events.firstWhere((e) => e.direction == "out");
      expect(sent.type, "binary");
      expect(sent.size, 4);
    });

    test('close shuts down connection cleanly', () async {
      final socket = await WebSocket.connect('ws://127.0.0.1:$port');
      final profiled = ProfileableWebSocket(socket, enableLogging: false);
      final doneFired = Completer<void>();
      profiled.listen(null, onDone: () => doneFired.complete());
      await socket.close(1000, 'done');
      await doneFired.future.timeout(Duration(seconds: 2));
      expect(socket.readyState, WebSocket.closed);
    });
  });
}