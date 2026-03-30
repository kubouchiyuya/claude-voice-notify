# アーキテクチャ

## 概要

```
Claude Code → MCP Protocol → claude-voice-notify → TTSプロバイダー → 音声再生
```

## プロバイダー差し替え式設計

`TTSProvider` インターフェースを実装するだけで新しい音声エンジンを追加できます。

```typescript
interface TTSProvider {
  readonly name: string;
  readonly description: string;
  readonly isFree: boolean;
  synthesize(options: SpeakOptions): Promise<Buffer>;
  listSpeakers?(): Promise<Array<{ id: string | number; name: string }>>;
}
```

## プロバイダー選択フロー

1. `NOTIFY_PROVIDER` 環境変数を読む
2. 未設定なら `voicevox` をデフォルトに
3. `providers/index.ts` のファクトリーが対応するクラスをインスタンス化

## 音声再生のクロスプラットフォーム対応

| OS | コマンド |
|----|---------|
| macOS | `afplay` |
| Windows | PowerShell `SoundPlayer` |
| Linux | `aplay` |

## 新プロバイダーの追加方法

1. `src/providers/` に新しいファイルを作成
2. `TTSProvider` を実装
3. `src/providers/index.ts` の `PROVIDER_MAP` に登録
