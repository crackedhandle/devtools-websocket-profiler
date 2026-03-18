import 'dart:io';
import 'package:devtools_websocket_profiler/profileable_websocket.dart';

Future<void> main() async {
  print("Connecting to WebSocket...");

  final socket = await WebSocket.connect('ws://127.0.0.1:8081');
  final profiled = ProfileableWebSocket(socket);

  profiled.listen((data) {
    print("Received: $data");
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
  });
}