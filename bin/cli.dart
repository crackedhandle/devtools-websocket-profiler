import 'dart:io';
import 'package:devtools_websocket_profiler/profileable_websocket.dart';
import 'package:devtools_websocket_profiler/socket_event.dart';

void printTable(List<SocketEvent> events) {
  final last10 = events.reversed.take(10).toList().reversed.toList();
  final line = '─' * 72;
  print('\n$line');
  print(
    ' ${'#'.padRight(4)}'
    '${'Time'.padRight(12)}'
    '${'Dir'.padRight(10)}'
    '${'Type'.padRight(8)}'
    '${'Size'.padRight(8)}'
    '${'Latency'.padRight(10)}'
    'Preview',
  );
  print(line);
  for (var i = 0; i < last10.length; i++) {
    final e = last10[i];
    final time =
        '${e.timestamp.hour.toString().padLeft(2, '0')}:'
        '${e.timestamp.minute.toString().padLeft(2, '0')}:'
        '${e.timestamp.second.toString().padLeft(2, '0')}';
    final dir = e.direction == 'out' ? '↑ SENT' : '↓ RECV';
    final latency = e.latencyMs != null ? '${e.latencyMs}ms' : '-';
    print(
      ' ${'${i + 1}'.padRight(4)}'
      '${time.padRight(12)}'
      '${dir.padRight(10)}'
      '${e.type.padRight(8)}'
      '${('${e.size} B').padRight(8)}'
      '${latency.padRight(10)}',
    );
  }
  print(line);
}

Future<void> main() async {
  print("Connecting to WebSocket...");

  final socket = await WebSocket.connect('ws://127.0.0.1:8081');
  final profiled = ProfileableWebSocket(socket);

  profiled.listen((data) {
    print("Received: $data");
    printTable(profiled.events);
  });

  print("\nType messages (type 'exit' to quit):");

  stdin.listen((inputBytes) {
    final input = String.fromCharCodes(inputBytes).trim();

    if (input == "exit") {
      print("Closing connection...");
      socket.close();
      exit(0);
    }

    profiled.send(input);
    printTable(profiled.events);
  });
}