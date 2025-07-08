#!/usr/bin/env python3
import os
import asyncio
from dotenv import load_dotenv
from livekit.agents.voice import Agent, AgentSession
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
    
    # Use Whisper for STT
    whisper_plugin = openai.WhisperPlugin()
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
        stt=whisper_plugin,  # <--- Use Whisper for STT
        tts=whisper_plugin,  # (or use Silero for TTS if you want)
    )
    
    # Create session
    session = AgentSession(
        stt=agent.stt,
        tts=agent.tts,
        llm=agent.llm,
        allow_interruptions=True,
    )
    
    try:
        print("[Agent] Starting session...")
        await session.start(agent)
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