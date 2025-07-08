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

# Create a fixed version of the agent script
echo "[*] Creating fixed agent script..."
cat > /tmp/fixed_agent.py << 'EOF'
#!/usr/bin/env python3
import os
import asyncio
from dotenv import load_dotenv
from livekit.agents.voice import Agent, AgentSession
from livekit import RoomOptions
import livekit.plugins.silero as silero
import livekit.plugins.openai as openai

load_dotenv()

async def main():
    print("[Agent] Starting LiveKit agent with Ollama...")
    
    # Get configuration
    livekit_url = os.environ.get("LIVEKIT_URL", "ws://localhost:7880")
    api_key = os.environ.get("LIVEKIT_API_KEY", "devkey")
    api_secret = os.environ.get("LIVEKIT_API_SECRET", "secret")
    agent_identity = os.environ.get("AGENT_IDENTITY", "agent_ollama")
    room_name = os.environ.get("ROOM_NAME", "my-room")
    
    print(f"[Agent] Connecting to LiveKit at: {livekit_url}")
    print(f"[Agent] Room: {room_name}, Identity: {agent_identity}")
    
    # Create plugins
    silero_plugin = silero.SileroPlugin()
    
    # Use Ollama for LLM
    llm = openai.LLM.with_ollama(
        model=os.environ.get("MODEL_NAME", "llama3.1"),
        base_url=os.environ.get("OLLAMA_URL", "http://localhost:11434/v1"),
        temperature=0.7,
    )
    
    # Create agent
    agent = Agent(
        instructions="You are a helpful assistant. Respond naturally and conversationally.",
        llm=llm,
        stt=silero_plugin,  # Use Silero for STT
        tts=silero_plugin,  # Use Silero for TTS
    )
    
    # Create session with basic parameters
    session = AgentSession(
        stt=agent.stt,
        tts=agent.tts,
        llm=agent.llm,
        allow_interruptions=True
    )
    
    try:
        print("[Agent] Starting session...")
        
        # Create room options with LiveKit connection parameters
        room_options = RoomOptions(
            url=livekit_url,
            api_key=api_key,
            api_secret=api_secret,
            room_name=room_name,
            identity=agent_identity
        )
        
        # Start the session with the agent and room options
        await session.start(agent, room_options=room_options)
        
        print("[Agent] Session started successfully!")
        print("[Agent] Agent is now listening for voice input...")
        print("[Agent] Press Ctrl+C to stop...")
        
        # Keep running
        await asyncio.Future()
        
    except KeyboardInterrupt:
        print("[Agent] Shutting down...")
    except Exception as e:
        print(f"[Agent] Error: {e}")
        import traceback
        traceback.print_exc()
    finally:
        print("[Agent] Closing session...")
        await session.aclose()

if __name__ == "__main__":
    asyncio.run(main()) 
EOF

echo "[*] Installing backend dependencies..."
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

echo "[*] Starting backend agent in background..."
# Use the fixed agent script
(
    source venv/bin/activate
    python /tmp/fixed_agent.py &
    echo $! > /tmp/agent.pid
)
echo "[*] Agent started with PID: $(cat /tmp/agent.pid)"

echo "[*] Installing frontend dependencies..."
cd ../frontend
npm install
npm install livekit-server-sdk@^2.13.1
echo "[*] Starting frontend..."
npm run dev