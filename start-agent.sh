#!/usr/bin/env bash
set -e

cd backend
source venv/bin/activate

echo "[*] Starting LiveKit agent..."
agents start \
  --signal-url "${LIVEKIT_URL}" \
  --api-key "${LIVEKIT_API_KEY}" \
  --api-secret "${LIVEKIT_API_SECRET}" \
  --identity "${AGENT_IDENTITY:-agent_ollama}" \
  --room "${ROOM_NAME:-my-room}" 