# WebSocket Profiling Prototype for Flutter DevTools

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

## Architecture
App → ProfileableWebSocket (wrapper) → Event Model (SocketEvent) → Structured JSON Events (VM-style)→ Consumer (CLI / DevTools)

## Sample Output
<img width="1349" height="220" alt="image" src="https://github.com/user-attachments/assets/cc640737-b99d-4ce2-9427-48bd43836377" />


---

## Design Approach

### Layer 1 — Instrumentation (dart:io level)
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

### Layer 2 — Event Model & VM Service Alignment
Events are structured as JSON to resemble how data is typically exposed via the Dart VM Service.

This enables:
- Easy integration into existing profiling pipelines
- Compatibility with DevTools data consumption patterns

The prototype focuses on validating this event model before moving to SDK-level instrumentation.

---

### Layer 3 — DevTools Integration (Conceptual)
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

## Relation to Existing DevTools Architecture

Instead of introducing a separate system, this approach can integrate with the existing `http_profile` pipeline by extending it to support WebSocket frame events.

This keeps the system consistent and avoids fragmentation.

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
dart run bin/server.dart

Run the CLI:
dart run bin/cli.dart



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
