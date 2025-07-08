import { useEffect, useRef, useState } from 'react';
import { Room, createLocalAudioTrack } from 'livekit-client';

export default function Home() {
  const [transcript, setTranscript] = useState([]);
  const [connected, setConnected] = useState(false);
  const audioRef = useRef(null);

  useEffect(() => {
    let room;
    let audioTrack;
    let cleanup = () => {};
    (async () => {
      const username = 'user_' + Math.floor(Math.random() * 1000);
      const roomName = 'my-room';
      // Get token from backend
      const res = await fetch(`/api/token?room=${roomName}&username=${username}`);
      const { token } = await res.json();
      // Connect to LiveKit
      room = new Room({ autoSubscribe: true });
      const livekitUrl = process.env.NEXT_PUBLIC_LIVEKIT_URL || 'ws://localhost:7880';
      await room.connect(livekitUrl, token);
      setConnected(true);
      // Publish mic audio
      audioTrack = await createLocalAudioTrack();
      await room.localParticipant.publishTrack(audioTrack);
      // Listen for agent's audio
      room.on('trackSubscribed', (track, publication, participant) => {
        if (participant.identity.startsWith('agent')) {
          const audioElement = track.attach();
          audioElement.autoplay = true;
          audioElement.controls = false;
          audioRef.current.appendChild(audioElement);
        }
      });
      // Listen for data messages (transcripts)
      room.on('dataReceived', (payload, participant) => {
        setTranscript((prev) => [...prev, { from: participant.identity, text: new TextDecoder().decode(payload) }]);
      });
      // Cleanup on unmount
      cleanup = async () => {
        if (audioTrack) await audioTrack.stop();
        if (room) await room.disconnect();
      };
    })();
    return () => { cleanup(); };
  }, []);

  return (
    <div style={{ background: '#181a1b', color: '#fff', minHeight: '100vh', padding: 32 }}>
      <h1>LiveKit + Ollama Assistant</h1>
      <div>{connected ? 'Listening…' : 'Connecting…'}</div>
      <div ref={audioRef}></div>
      <div style={{ marginTop: 24 }}>
        {transcript.map((msg, i) => (
          <div key={i}><b>{msg.from}:</b> {msg.text}</div>
        ))}
      </div>
    </div>
  );
}
