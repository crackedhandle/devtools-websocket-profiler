class SocketEvent {
  final String id;
  final DateTime timestamp;
  final String direction;
  final String type;
  final int size;
  final int? latencyMs; 

  SocketEvent({
    required this.id,
    required this.timestamp,
    required this.direction,
    required this.type,
    required this.size,
    this.latencyMs,
  });

  @override
  String toString() {
    return "${timestamp.toIso8601String()} | $direction | $type | ${size}B | latency: ${latencyMs ?? '-'} ms";
  }
  Map<String, dynamic> toJson() {
  return {
    "id": id,
    "timestamp": timestamp.toIso8601String(),
    "direction": direction,
    "size": size,
    "latencyMs": latencyMs,
    "type": type,
  };
}
}