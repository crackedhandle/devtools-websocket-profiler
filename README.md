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
