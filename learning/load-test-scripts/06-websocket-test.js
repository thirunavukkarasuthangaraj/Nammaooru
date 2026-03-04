// ============================================
// 06 - WEBSOCKET LOAD TEST
// ============================================
// Purpose: Test real-time WebSocket connections
//          Simulates multiple users connected for live orders
// Run:     k6 run 06-websocket-test.js
// ============================================

import ws from "k6/ws";
import { check, sleep } from "k6";
import { Counter } from "k6/metrics";
import { CONFIG } from "./config.js";

const wsErrors = new Counter("websocket_errors");
const wsMessages = new Counter("websocket_messages_received");

export const options = {
  stages: [
    { duration: "30s", target: 10 },  // 10 WebSocket connections
    { duration: "1m", target: 50 },   // 50 WebSocket connections
    { duration: "2m", target: 50 },   // Hold 50 connections
    { duration: "30s", target: 0 },   // Close all
  ],
};

export default function () {
  // WebSocket URL (wss:// for secure)
  const wsUrl = `wss://api.YOUR_DOMAIN.com/ws`;

  const res = ws.connect(wsUrl, {}, function (socket) {
    socket.on("open", function () {
      console.log(`VU ${__VU}: WebSocket connected`);

      // Subscribe to order updates (STOMP protocol)
      socket.send(
        "CONNECT\naccept-version:1.1\nheart-beat:10000,10000\n\n\0"
      );

      // Subscribe to a topic
      socket.send(
        "SUBSCRIBE\nid:sub-0\ndestination:/topic/orders\n\n\0"
      );
    });

    socket.on("message", function (message) {
      wsMessages.add(1);
      // console.log(`VU ${__VU}: Received message`);
    });

    socket.on("error", function (e) {
      wsErrors.add(1);
      console.log(`VU ${__VU}: WebSocket error: ${e.error()}`);
    });

    socket.on("close", function () {
      // console.log(`VU ${__VU}: WebSocket closed`);
    });

    // Keep connection open for 30 seconds (simulating user watching orders)
    sleep(30);

    // Disconnect
    socket.send("DISCONNECT\n\n\0");
    socket.close();
  });

  check(res, {
    "WebSocket connected": (r) => r && r.status === 101,
  });
}

/*
WHAT THIS TESTS:
================
1. Can your server handle 50 simultaneous WebSocket connections?
2. Does it run out of file descriptors?
3. Does memory usage spike with many connections?
4. Does Nginx properly proxy WebSocket?

EXPECTED RESULTS:
  CX33 server should handle 100-500 WebSocket connections easily.
  Each connection uses ~50KB RAM.
  50 connections = ~2.5MB (negligible)

COMMON ISSUES:
  - Nginx timeout closes idle WebSocket after 60s
    Fix: proxy_read_timeout 86400;
  - Too many connections: "Too many open files"
    Fix: ulimit -n 65535 (increase file descriptor limit)
  - STOMP broker memory fills up
    Fix: Configure message buffer limits in Spring
*/
