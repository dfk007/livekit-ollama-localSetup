import { NextApiRequest, NextApiResponse } from 'next';
import { AccessToken } from 'livekit-server-sdk';

export const config = { api: { revalidate: 0 } };

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  const { room, username } = req.query as { [key: string]: string };

  if (req.method !== 'GET') return res.status(405).json({ error: 'Method not allowed' });
  if (!room) return res.status(400).json({ error: 'Missing room' });
  if (!username) return res.status(400).json({ error: 'Missing username' });

  const apiKey = process.env.LIVEKIT_API_KEY;
  const apiSecret = process.env.LIVEKIT_API_SECRET;
  const wsUrl = process.env.NEXT_PUBLIC_LIVEKIT_URL;

  if (!apiKey || !apiSecret || !wsUrl) {
    return res.status(500).json({ error: 'Server misconfigured' });
  }

  const at = new AccessToken(apiKey, apiSecret, { identity: username });
  at.addGrant({
    room,
    roomJoin: true,
    canPublish: true,
    canSubscribe: true
  });

  const token = await at.toJwt();

  res.setHeader('Cache-Control', 'no-store');
  res.status(200).json({ token });
}
