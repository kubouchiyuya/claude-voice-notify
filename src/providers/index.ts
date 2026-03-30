import type { TTSProvider } from '../types.js';
import { VoicevoxProvider } from './voicevox.js';
import { CoeiroinkProvider } from './coeiroink.js';
import {
  AivisSpeechProvider,
  StyleBertVits2Provider,
  FishAudioProvider,
  ElevenLabsProvider,
  OpenAITTSProvider,
  GoogleTTSProvider,
} from './all-providers.js';

const PROVIDER_MAP: Record<string, () => TTSProvider> = {
  voicevox: () => new VoicevoxProvider(),
  coeiroink: () => new CoeiroinkProvider(),
  aivis_speech: () => new AivisSpeechProvider(),
  style_bert_vits2: () => new StyleBertVits2Provider(),
  fish_audio: () => new FishAudioProvider(),
  elevenlabs: () => new ElevenLabsProvider(),
  openai: () => new OpenAITTSProvider(),
  google: () => new GoogleTTSProvider(),
};

export function createProvider(name?: string): TTSProvider {
  const providerName = (name || process.env.NOTIFY_PROVIDER || 'voicevox').toLowerCase();
  const factory = PROVIDER_MAP[providerName];
  if (!factory) {
    const available = Object.keys(PROVIDER_MAP).join(', ');
    throw new Error(`Unknown provider: "${providerName}". Available: ${available}`);
  }
  return factory();
}

export function listAvailableProviders(): Array<{ name: string; description: string; isFree: boolean }> {
  return Object.entries(PROVIDER_MAP).map(([key, factory]) => {
    try {
      const p = factory();
      return { name: key, description: p.description, isFree: p.isFree };
    } catch {
      // Provider requires API key - still list it
      const descriptions: Record<string, { desc: string; free: boolean }> = {
        fish_audio: { desc: 'Fish Audio - 高品質クラウドTTS（有料）', free: false },
        elevenlabs: { desc: 'ElevenLabs - 英語最強クラウドTTS（有料/無料枠あり）', free: false },
        openai: { desc: 'OpenAI TTS - nova/alloy等（有料）', free: false },
        google: { desc: 'Google Cloud TTS - 高品質多言語TTS（無料枠: 月100万文字）', free: false },
      };
      const info = descriptions[key] || { desc: key, free: false };
      return { name: key, description: info.desc, isFree: info.free };
    }
  });
}
