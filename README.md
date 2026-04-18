# WebSocket Profiling Prototype for Flutter DevTools

![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![GSoC 2026](https://img.shields.io/badge/GSoC-2026-orange?style=for-the-badge)

## Overview
Flutter DevTools currently does not support WebSocket traffic inspection.  
This project explores how WebSocket frame-level data can be captured, structured, and exposed in a way compatible with DevTools.

## Features
- WebSocket traffic interception (incoming + outgoing)
- Request–response pairing using message IDs
- Latency tracking for each frame
- Structured JSON event emission (VM Service-style)
- CLI-based real-time interaction
- Configurable logging (disabled in tests)
- End-to-end tests using real WebSocket connections
- 
- ## Potential DevTools Integration

The emitted events can map naturally into the DevTools Network panel:

- Each WebSocket connection can be represented as a parent row
- Individual frames (send/receive) can be displayed as child entries
- Latency and payload size can be surfaced as columns
- Frame-level details (type, timestamp) can be shown in the details pane

This aligns with how HTTP requests are currently structured in DevTools.

 ## Architecture Overview
```
Application Code
        │
        ▼
   Profiling WebSocket
   (dart:io wrapper)
        │
        ▼
Frame Events
(timestamp, direction, size, type, latency)
        │
        ▼
Timeline / Event Stream
(dart:developer)
        │
        ▼
Dart VM Service
(profiling APIs)
        │
        ▼
DevTools Network Panel
        │
        ▼
UI Representation
(connections + frames)
```

This flow mirrors how HTTP profiling is currently handled in DevTools, making WebSocket support a natural extension rather than a separate system.


## Sample Output:

<img width="1349" height="220" alt="image" src="https://github.com/user-attachments/assets/cc640737-b99d-4ce2-9427-48bd43836377" />


---

## Design Approach

### Layer 1 - Instrumentation (dart:io level)
A wrapper (`ProfileableWebSocket`) intercepts:
- `add()` → outgoing frames
- `listen()` → incoming frames

Each frame records:
- Timestamp
- Direction (in/out)
- Size
- Type (text/binary)
- Connection-level correlation (via ID)

---

### Layer 2 - Event Model & VM Service Alignment

Events are emitted directly to the Dart VM timeline using:

```dart
Timeline.instantSync('WebSocket Frame', arguments: event.toJson());
```

This is the same mechanism used by Flutter's HTTP profiling pipeline,
making WebSocket events immediately consumable by DevTools without
any additional translation layer.

This enables:
- Direct integration into the existing VM timeline infrastructure
- Compatibility with DevTools data consumption patterns
- A natural extension path to SDK-level instrumentation

The prototype validates this event model at the user-space level
before moving to dart:io / VM Service-level instrumentation.

---

### Layer 3 - DevTools Integration (Conceptual)
The emitted events can map naturally into the DevTools Network panel:

- Each WebSocket connection can appear as a parent row
- Individual frames (send/receive) can be shown as child entries
- Columns can include:
  - Timestamp
  - Direction
  - Size
  - Latency
  - Frame type
- A details panel can show:
  - Payload preview
  - Total bytes sent/received
  - Connection metadata

This follows a structure similar to HTTP request visualization in DevTools.

---

## Technical Challenges Addressed

### Stream Integrity
One of the primary hurdles in WebSocket profiling is intercepting data without "consuming" the stream, which would break the application's original logic. 
* **Solution:** Implemented a non-destructive `StreamTransformer`. This allows the profiler to "tap" into the data flow, capturing frame metadata while ensuring the original `Stream` remains intact and reactive for the end-user.

### Buffer Management
High-frequency WebSocket traffic can quickly lead to memory exhaustion if every frame is stored indefinitely.
* **Solution:** Developed a **Circular FIFO (First-In-First-Out) Buffer**. This mechanism enforces a configurable memory cap (e.g., 500 frames), automatically discarding the oldest data as new frames arrive. This ensures the profiler remains "memory-safe" even during high-throughput stress tests.

### Latency Logic (RTT)
Standard socket monitoring often misses the "developer's perspective" of request-response timing.
* **Solution:** Created a correlation engine that maps outbound request IDs to inbound response IDs. By calculating the delta between the `add()` timestamp and the corresponding `listen()` event, the profiler provides a real-time **Round Trip Time (RTT)** estimation for every message exchange.

## Relation to Existing DevTools Architecture

## Integration with Existing Profiling Pipeline

Instead of introducing a separate system, WebSocket events can be integrated into the existing `http_profile` pipeline used by DevTools. 

At the dart:io level, frame-level metadata can be captured and emitted as timeline events. These events can then be surfaced through the Dart VM Service using an extended profiling API, similar to how HTTP requests are currently exposed. 

On the DevTools side, WebSocket frames can be grouped under a connection and displayed alongside HTTP traffic, reusing the existing Network panel infrastructure. This approach ensures consistency, minimizes architectural changes, and allows WebSocket support to evolve naturally within the current profiling system.

---

## Testing

The project includes tests that validate:

- Event creation and metadata correctness
- Request–response pairing via IDs
- Latency calculation
- Event buffering behavior

All tests use real WebSocket connections to ensure correctness in async environments.

---

## Demo

Run the server:
* **Terminal 1 (Mock Server):**
```
dart run bin/server.dart
```

WebSocket server running on 
```
ws://127.0.0.1:8081
```


Run the CLI:
* **Terminal 2 (Profiler CLI):**
```
dart run bin/cli.dart
```
<img width="1467" height="528" alt="image" src="https://github.com/user-attachments/assets/c367fffe-5148-4ccf-b70d-8f050a4ebfea" />
<img width="1462" height="579" alt="image" src="https://github.com/user-attachments/assets/8a7857cd-d4a9-4711-a79c-dbd188dc9d70" />





---

## Future Work

- Integration with Dart VM Service (`getWebSocketProfile`)
- DevTools Network panel support
- Connection-level aggregation
- gRPC traffic support (HTTP/2 frames)
- Performance optimization for high-throughput streams

---

## Key Insight

This project focuses not just on capturing WebSocket traffic, but on structuring it in a way that aligns with how DevTools consumes and visualizes data.

The goal is to bridge the gap between low-level socket activity and developer-facing debugging tools.
