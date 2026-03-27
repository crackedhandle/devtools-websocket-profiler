import 'dart:io';
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

      final events = profiled.events;

      expect(events.isNotEmpty, true);
      expect(events.first.direction, "out");
      expect(events.first.size, 5);
    });

    test('captures incoming event and pairs with same id', () async {
      final socket = await WebSocket.connect('ws://127.0.0.1:$port');
      final profiled = ProfileableWebSocket(socket, enableLogging: false);

      profiled.listen((_) {});

      profiled.send("test");

      await Future.delayed(Duration(milliseconds: 100));

      final events = profiled.events;

      expect(events.length >= 2, true);

      final outEvent = events.firstWhere((e) => e.direction == "out");
      final inEvent = events.firstWhere((e) => e.direction == "in");

      expect(outEvent.id, inEvent.id);
    });

    test('calculates latency for response', () async {
      final socket = await WebSocket.connect('ws://127.0.0.1:$port');
      final profiled = ProfileableWebSocket(socket, enableLogging: false);
      

      profiled.listen((_) {});

      profiled.send("latency");

      await Future.delayed(Duration(milliseconds: 100));

      final inEvent =
          profiled.events.firstWhere((e) => e.direction == "in");

      expect(inEvent.latencyMs != null, true);
      expect(inEvent.latencyMs! >= 0, true);
    });

    test('stores multiple events in buffer', () async {
      final socket = await WebSocket.connect('ws://127.0.0.1:$port');
      final profiled = ProfileableWebSocket(socket, enableLogging: false);

      profiled.listen((_) {});

      profiled.send("one");
      profiled.send("two");
      profiled.send("three");

      await Future.delayed(Duration(milliseconds: 150));

      expect(profiled.events.length >= 3, true);
    });
  });
}