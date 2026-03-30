# Contributing

claude-voice-notify へのコントリビューションを歓迎します！

## 新しいプロバイダーの追加方法

1. `src/providers/` に新しいファイルを作成
2. `TTSProvider` インターフェースを実装

```typescript
import type { TTSProvider, SpeakOptions } from '../types.js';

export class MyProvider implements TTSProvider {
  readonly name = 'MyTTS';
  readonly description = '説明';
  readonly isFree = true;

  async synthesize(options: SpeakOptions): Promise<Buffer> {
    // TTS APIを呼んでWAVバッファを返す
  }
}
```

3. `src/providers/index.ts` の `PROVIDER_MAP` に登録

```typescript
import { MyProvider } from './my-provider.js';

const PROVIDER_MAP = {
  // ...existing
  my_tts: () => new MyProvider(),
};
```

4. PRを送る

## 開発環境

```bash
npm install
npm run dev   # TypeScript watch mode
```
