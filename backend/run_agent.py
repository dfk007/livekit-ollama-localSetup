#!/usr/bin/env python3
import os
import asyncio
import sys
from dotenv import load_dotenv
from livekit.agents.voice import Agent, AgentSession
import livekit.plugins.silero as silero
import livekit.plugins.openai as openai

load_dotenv()

async def run_agent():
    # Get configuration from environment or command line args
    livekit_url = os.environ.get("LIVEKIT_URL", "ws://localhost:7880")
    api_key = os.environ.get("LIVEKIT_API_KEY", "devkey")
    api_secret = os.environ.get("LIVEKIT_API_SECRET", "secret")
    agent_identity = os.environ.get("AGENT_IDENTITY", "agent_ollama")
    room_name = os.environ.get("ROOM_NAME", "my-room")
    
    print(f"[Agent] Starting with identity: {agent_identity}, room: {room_name}")
    print(f"[Agent] Connecting to LiveKit at: {livekit_url}")
    
    # Create the agent with proper Ollama integration
    silero_plugin = silero.SileroPlugin()
    
    # Use the OpenAI plugin with Ollama configuration
    llm = openai.LLM.with_ollama(
        model=os.environ.get("MODEL_NAME", "llama3.1"),
        base_url=os.environ.get("OLLAMA_URL", "http://localhost:11434/v1"),
        temperature=0.7,
    )
    
    agent = Agent(
        instructions="You are a helpful assistant. Respond naturally and conversationally.",
        llm=llm,
        stt=silero_plugin,
        tts=silero_plugin,
    )
    
    # Create session with proper configuration
    session = AgentSession(
        stt=agent.stt,
        tts=agent.tts,
        llm=agent.llm,
        allow_interruptions=True,
    )
    
    try:
        # Start the agent (this should handle joining the room)
        await session.start(agent)
        print(f"Agent '{agent_identity}' connected to room '{room_name}' and listening for audio...")
        
        # Keep the agent running
        await asyncio.Future()  # Run forever
        
    except KeyboardInterrupt:
        print("Shutting down agent...")
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
    finally:
        await session.aclose()

if __name__ == "__main__":
    asyncio.run(run_agent()) 