import type { TTSProvider, SpeakOptions } from '../types.js';

const DEFAULT_BASE_URL = 'http://localhost:50032';
const DEFAULT_SPEAKER = 0; // つくよみちゃん

export class CoeiroinkProvider implements TTSProvider {
  readonly name = 'COEIROINK';
  readonly description = 'COEIROINK - 無料のローカルTTSエンジン（つくよみちゃん等）';
  readonly isFree = true;

  private baseUrl: string;
  private defaultSpeaker: number;

  constructor() {
    this.baseUrl = process.env.COEIROINK_URL || DEFAULT_BASE_URL;
    this.defaultSpeaker = parseInt(process.env.COEIROINK_SPEAKER || String(DEFAULT_SPEAKER), 10);
  }

  async synthesize(options: SpeakOptions): Promise<Buffer> {
    const speaker = options.speaker !== undefined
      ? Number(options.speaker)
      : this.defaultSpeaker;
    const speed = options.speed || 1.0;

    // COEIROINK v2 API (VOICEVOX互換)
    const queryRes = await fetch(
      `${this.baseUrl}/audio_query?text=${encodeURIComponent(options.text)}&speaker=${speaker}`,
      { method: 'POST' }
    );
    if (!queryRes.ok) {
      throw new Error(`COEIROINK audio_query failed: ${queryRes.status}`);
    }
    const query = await queryRes.json() as Record<string, unknown>;
    query.speedScale = speed;

    const synthRes = await fetch(
      `${this.baseUrl}/synthesis?speaker=${speaker}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(query),
      }
    );
    if (!synthRes.ok) {
      throw new Error(`COEIROINK synthesis failed: ${synthRes.status}`);
    }

    return Buffer.from(await synthRes.arrayBuffer());
  }

  async listSpeakers(): Promise<Array<{ id: string | number; name: string }>> {
    const res = await fetch(`${this.baseUrl}/speakers`);
    if (!res.ok) throw new Error(`COEIROINK speakers failed: ${res.status}`);
    const speakers = await res.json() as Array<{
      name: string;
      styles: Array<{ id: number; name: string }>;
    }>;
    return speakers.flatMap((s) =>
      s.styles.map((style) => ({ id: style.id, name: `${s.name}（${style.name}）` }))
    );
  }
}
