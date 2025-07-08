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
    
    # Create plugins
    silero_plugin = silero.SileroPlugin()
    
    # Create LLM with Ollama
    llm = openai.LLM.with_ollama(
        model=os.environ.get("MODEL_NAME", "llama3.1"),
        base_url=os.environ.get("OLLAMA_URL", "http://localhost:11434/v1"),
        temperature=0.7,
    )
    
    # Create agent
    agent = Agent(
        instructions="You are a helpful assistant. Respond naturally and conversationally.",
        llm=llm,
        stt=silero_plugin,
        tts=silero_plugin,
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
        
        # Keep running
        await asyncio.Future()
        
    except KeyboardInterrupt:
        print("[Agent] Shutting down...")
    except Exception as e:
        print(f"[Agent] Error: {e}")
        import traceback
        traceback.print_exc()
    finally:
        if hasattr(session, 'aclose'):
            await session.aclose()
        elif hasattr(session, 'close'):
            await session.close()

if __name__ == "__main__":
    asyncio.run(main()) 