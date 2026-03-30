import type { TTSProvider, SpeakOptions } from '../types.js';

// --- AivisSpeech (VOICEVOX互換API) ---
export class AivisSpeechProvider implements TTSProvider {
  readonly name = 'AivisSpeech';
  readonly description = 'AivisSpeech - 高品質無料ローカルTTS（VOICEVOX互換）';
  readonly isFree = true;
  private baseUrl: string;
  private defaultSpeaker: number;

  constructor() {
    this.baseUrl = process.env.AIVIS_SPEECH_URL || 'http://localhost:10101';
    this.defaultSpeaker = parseInt(process.env.AIVIS_SPEECH_SPEAKER || '0', 10);
  }

  async synthesize(options: SpeakOptions): Promise<Buffer> {
    const speaker = options.speaker !== undefined ? Number(options.speaker) : this.defaultSpeaker;
    const queryRes = await fetch(
      `${this.baseUrl}/audio_query?text=${encodeURIComponent(options.text)}&speaker=${speaker}`,
      { method: 'POST' }
    );
    if (!queryRes.ok) throw new Error(`AivisSpeech audio_query failed: ${queryRes.status}`);
    const query = await queryRes.json() as Record<string, unknown>;
    query.speedScale = options.speed || 1.0;

    const synthRes = await fetch(`${this.baseUrl}/synthesis?speaker=${speaker}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(query),
    });
    if (!synthRes.ok) throw new Error(`AivisSpeech synthesis failed: ${synthRes.status}`);
    return Buffer.from(await synthRes.arrayBuffer());
  }
}

// --- Style-Bert-VITS2 ---
export class StyleBertVits2Provider implements TTSProvider {
  readonly name = 'Style-Bert-VITS2';
  readonly description = 'Style-Bert-VITS2 - 自分の声・好きなキャラの声を学習して使えるTTS';
  readonly isFree = true;
  private baseUrl: string;
  private defaultModel: string;

  constructor() {
    this.baseUrl = process.env.STYLE_BERT_VITS2_URL || 'http://localhost:5000';
    this.defaultModel = process.env.STYLE_BERT_VITS2_MODEL || 'default';
  }

  async synthesize(options: SpeakOptions): Promise<Buffer> {
    const model = (options.speaker as string) || this.defaultModel;
    const params = new URLSearchParams({
      text: options.text,
      model_name: model,
      speed: String(options.speed || 1.0),
      language: 'JP',
    });
    const res = await fetch(`${this.baseUrl}/voice?${params}`);
    if (!res.ok) throw new Error(`Style-Bert-VITS2 failed: ${res.status}`);
    return Buffer.from(await res.arrayBuffer());
  }
}

// --- Fish Audio ---
export class FishAudioProvider implements TTSProvider {
  readonly name = 'Fish Audio';
  readonly description = 'Fish Audio - 高品質クラウドTTS（有料）';
  readonly isFree = false;
  private apiKey: string;
  private defaultVoiceId: string;

  constructor() {
    this.apiKey = process.env.FISH_AUDIO_API_KEY || '';
    this.defaultVoiceId = process.env.FISH_AUDIO_VOICE_ID || '';
    if (!this.apiKey) throw new Error('FISH_AUDIO_API_KEY が設定されていません');
  }

  async synthesize(options: SpeakOptions): Promise<Buffer> {
    const voiceId = (options.speaker as string) || this.defaultVoiceId;
    const res = await fetch('https://api.fish.audio/v1/tts', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${this.apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        text: options.text,
        reference_id: voiceId,
        format: 'wav',
        latency: 'normal',
      }),
    });
    if (!res.ok) throw new Error(`Fish Audio failed: ${res.status} ${await res.text()}`);
    return Buffer.from(await res.arrayBuffer());
  }
}

// --- ElevenLabs ---
export class ElevenLabsProvider implements TTSProvider {
  readonly name = 'ElevenLabs';
  readonly description = 'ElevenLabs - 英語最強のクラウドTTS（有料/無料枠あり）';
  readonly isFree = false;
  private apiKey: string;
  private defaultVoiceId: string;

  constructor() {
    this.apiKey = process.env.ELEVENLABS_API_KEY || '';
    this.defaultVoiceId = process.env.ELEVENLABS_VOICE_ID || '21m00Tcm4TlvDq8ikWAM'; // Rachel
    if (!this.apiKey) throw new Error('ELEVENLABS_API_KEY が設定されていません');
  }

  async synthesize(options: SpeakOptions): Promise<Buffer> {
    const voiceId = (options.speaker as string) || this.defaultVoiceId;
    const res = await fetch(`https://api.elevenlabs.io/v1/text-to-speech/${voiceId}`, {
      method: 'POST',
      headers: {
        'xi-api-key': this.apiKey,
        'Content-Type': 'application/json',
        Accept: 'audio/wav',
      },
      body: JSON.stringify({
        text: options.text,
        model_id: 'eleven_multilingual_v2',
      }),
    });
    if (!res.ok) throw new Error(`ElevenLabs failed: ${res.status}`);
    return Buffer.from(await res.arrayBuffer());
  }
}

// --- OpenAI TTS ---
export class OpenAITTSProvider implements TTSProvider {
  readonly name = 'OpenAI TTS';
  readonly description = 'OpenAI TTS - nova/alloy等のOpenAI音声（有料）';
  readonly isFree = false;
  private apiKey: string;
  private defaultVoice: string;

  constructor() {
    this.apiKey = process.env.OPENAI_API_KEY || '';
    this.defaultVoice = process.env.OPENAI_TTS_VOICE || 'nova';
    if (!this.apiKey) throw new Error('OPENAI_API_KEY が設定されていません');
  }

  async synthesize(options: SpeakOptions): Promise<Buffer> {
    const voice = (options.speaker as string) || this.defaultVoice;
    const res = await fetch('https://api.openai.com/v1/audio/speech', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${this.apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'tts-1',
        input: options.text,
        voice,
        response_format: 'wav',
        speed: options.speed || 1.0,
      }),
    });
    if (!res.ok) throw new Error(`OpenAI TTS failed: ${res.status}`);
    return Buffer.from(await res.arrayBuffer());
  }
}
