import 'dart:io';

Future<void> main() async {
  final server = await HttpServer.bind('127.0.0.1', 8081);
  print('WebSocket server running on ws://127.0.0.1:8081');

  await for (HttpRequest request in server) {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      final socket = await WebSocketTransformer.upgrade(request);

      socket.listen((data) {
        socket.add(data); // echo back
      });
    }
  }
}