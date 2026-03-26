# WebSocket Profiling Prototype for Flutter DevTools

## Overview
Flutter DevTools currently does not support WebSocket traffic inspection.  
This project explores how WebSocket frame-level data can be captured, structured, and exposed in a way compatible with DevTools.

## Features
- WebSocket traffic interception
- Request response pairing using message IDs
- Latency tracking
- Structured JSON event emission (VM Service-style)
- CLI-based real-time interaction
- 
- ## Potential DevTools Integration

The emitted events can map naturally into the DevTools Network panel:

- Each WebSocket connection can be represented as a parent row
- Individual frames (send/receive) can be displayed as child entries
- Latency and payload size can be surfaced as columns
- Frame-level details (type, timestamp) can be shown in the details pane

This aligns with how HTTP requests are currently structured in DevTools.

## Architecture
App → ProfileableWebSocket → Event Model → JSON Events → Output

## Sample Output
<img width="1349" height="220" alt="image" src="https://github.com/user-attachments/assets/cc640737-b99d-4ce2-9427-48bd43836377" />

## Key Idea
This prototype simulates how WebSocket traffic could be surfaced through structured events similar to Dart VM Service events, which are consumed by Flutter DevTools.

## Future Work
- Integration with Dart VM Service
- DevTools Network panel support
- gRPC traffic support

- 
