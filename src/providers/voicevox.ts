import type { TTSProvider, SpeakOptions } from '../types.js';

const DEFAULT_BASE_URL = 'http://localhost:50021';
const DEFAULT_SPEAKER = 1; // ずんだもん（ノーマル）

// ずんだもん Speaker ID一覧
// 0: 四国めたん（あまあま）  1: ずんだもん（ノーマル）
// 2: 四国めたん（ノーマル）  3: ずんだもん（あまあま）
// 5: ずんだもん（ツンツン）  6: ずんだもん（セクシー）
// 7: ずんだもん（ささやき）  8: 春日部つむぎ
// 9: 雨晴はう  10: 波音リツ  11: 玄野武宏  等

export class VoicevoxProvider implements TTSProvider {
  readonly name = 'VOICEVOX';
  readonly description = 'VOICEVOX - 無料のローカルTTSエンジン（デフォルト: ずんだもん）';
  readonly isFree = true;

  private baseUrl: string;
  private defaultSpeaker: number;

  constructor() {
    this.baseUrl = process.env.VOICEVOX_URL || DEFAULT_BASE_URL;
    this.defaultSpeaker = parseInt(process.env.VOICEVOX_SPEAKER || String(DEFAULT_SPEAKER), 10);
  }

  async synthesize(options: SpeakOptions): Promise<Buffer> {
    const speaker = options.speaker !== undefined
      ? Number(options.speaker)
      : this.defaultSpeaker;
    const speed = options.speed || 1.0;

    // Step 1: audio_query
    const queryRes = await fetch(
      `${this.baseUrl}/audio_query?text=${encodeURIComponent(options.text)}&speaker=${speaker}`,
      { method: 'POST' }
    );
    if (!queryRes.ok) {
      throw new Error(`VOICEVOX audio_query failed: ${queryRes.status} ${queryRes.statusText}`);
    }
    const query = await queryRes.json() as Record<string, unknown>;

    // Apply speed and volume
    query.speedScale = speed;
    if (options.volume !== undefined) {
      query.volumeScale = options.volume;
    }

    // Step 2: synthesis
    const synthRes = await fetch(
      `${this.baseUrl}/synthesis?speaker=${speaker}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(query),
      }
    );
    if (!synthRes.ok) {
      throw new Error(`VOICEVOX synthesis failed: ${synthRes.status} ${synthRes.statusText}`);
    }

    const arrayBuffer = await synthRes.arrayBuffer();
    return Buffer.from(arrayBuffer);
  }

  async listSpeakers(): Promise<Array<{ id: string | number; name: string }>> {
    const res = await fetch(`${this.baseUrl}/speakers`);
    if (!res.ok) {
      throw new Error(`VOICEVOX speakers list failed: ${res.status}`);
    }
    const speakers = await res.json() as Array<{
      name: string;
      styles: Array<{ id: number; name: string }>;
    }>;

    return speakers.flatMap((s) =>
      s.styles.map((style) => ({
        id: style.id,
        name: `${s.name}（${style.name}）`,
      }))
    );
  }
}
