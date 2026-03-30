export type NotificationType = 'complete' | 'confirm' | 'error' | 'info' | 'custom';

export interface SpeakOptions {
  text: string;
  type?: NotificationType;
  speed?: number;
  volume?: number;
  speaker?: number | string;
}

export interface TTSProvider {
  readonly name: string;
  readonly description: string;
  readonly isFree: boolean;
  synthesize(options: SpeakOptions): Promise<Buffer>;
  listSpeakers?(): Promise<Array<{ id: string | number; name: string }>>;
}

export interface ProviderConfig {
  provider: string;
  baseUrl?: string;
  apiKey?: string;
  speaker?: number | string;
  speed?: number;
  volume?: number;
}
