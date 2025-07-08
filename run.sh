#!/usr/bin/env bash
set -e

echo "[*] Building LiveKit docker image with --no-cache..."
docker-compose build --no-cache

echo "[*] Starting LiveKit server..."
docker-compose up -d livekit
sleep 5

# Check if Ollama is running locally
echo "[*] Checking Ollama status..."
if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "[✓] Ollama is running locally on port 11434"
else
    echo "[!] Ollama is not running locally. Please start Ollama first:"
    echo "    ollama serve"
    echo "    # or pull a model: ollama pull llama3.1"
    echo ""
    echo "Alternatively, uncomment the Ollama service in docker-compose.yml"
    exit 1
fi

echo "[*] Installing backend dependencies..."
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

echo "[*] Starting backend agent in background..."
# Use the working agent script
(
    cd backend
    source venv/bin/activate
    python working_agent.py &
    echo $! > /tmp/agent.pid
)
echo "[*] Agent started with PID: $(cat /tmp/agent.pid)"

echo "[*] Installing frontend dependencies..."
cd ../frontend
npm install
npm install livekit-server-sdk@^2.13.1
echo "[*] Starting frontend..."
npm run dev
