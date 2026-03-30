# claude-voice-notify

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Node.js](https://img.shields.io/badge/node-%3E%3D18-brightgreen)](https://nodejs.org/)
[![MCP](https://img.shields.io/badge/MCP-Compatible-blue)](https://modelcontextprotocol.io/)

**Claude Code 用マルチプロバイダー音声通知 MCP サーバー**

Claude Code がタスク完了・確認要求・エラー発生時に**音声でユーザーに知らせる** MCP サーバーです。
デフォルトは **VOICEVOX（ずんだもん）** で完全無料・API キー不要。
環境変数 1 行で音声エンジンを差し替えられるプラグイン型設計。

---

## 対応プロバイダー（7 種）

| 環境変数値 | 名前 | 料金 | 特徴 |
|-----------|------|------|------|
| `voicevox` | **VOICEVOX** | **無料** | デフォルト・ずんだもん |
| `coeiroink` | COEIROINK | **無料** | つくよみちゃん等 |
| `aivis_speech` | AivisSpeech | **無料** | 高品質ローカル・VOICEVOX 互換 |
| `style_bert_vits2` | Style-Bert-VITS2 | **無料** | 自分の声・好きなキャラの声を学習可能 |
| `fish_audio` | Fish Audio | 有料 | 高品質クラウド TTS |
| `elevenlabs` | ElevenLabs | 有料(無料枠あり) | 英語最強 |
| `openai` | OpenAI TTS | 有料 | nova / alloy 等 |

---

## 導入手順（5 分）

### 1. VOICEVOX をインストール（無料プロバイダーの場合）

[VOICEVOX 公式サイト](https://voicevox.hiroshiba.jp/) からダウンロード・起動するだけ。API キー不要。

### 2. リポジトリを clone してビルド

```bash
git clone https://github.com/Masa_AIcreater/claude-voice-notify.git
cd claude-voice-notify
npm install
npm run build
```

### 3. Claude Code の設定に追加

`~/.claude.json` に以下を追加：

```json
{
  "mcpServers": {
    "voice-notify": {
      "command": "node",
      "args": ["/path/to/claude-voice-notify/dist/index.js"],
      "env": {
        "NOTIFY_PROVIDER": "voicevox",
        "VOICEVOX_SPEAKER": "1"
      }
    }
  }
}
```

### 4. VS Code を再起動

### 5. テスト

Claude Code で「`notify_test` を実行して」と伝えて、ずんだもんの声が聞こえれば成功！

---

## MCP ツール一覧

| ツール名 | 用途 | デフォルトメッセージ |
|---------|------|-------------------|
| `notify_complete` | タスク完了通知 | 「タスクが完了しました」 |
| `notify_confirm` | 確認要求通知 | 「確認をお願いします」 |
| `notify_speak` | カスタム読み上げ | （text 必須） |
| `notify_test` | 接続テスト | 「テスト成功」 |
| `notify_list_providers` | プロバイダー一覧表示 | — |

---

## 環境変数リファレンス

### 共通

| 変数 | 説明 | デフォルト |
|------|------|----------|
| `NOTIFY_PROVIDER` | 使用するプロバイダー | `voicevox` |

### VOICEVOX

| 変数 | 説明 | デフォルト |
|------|------|----------|
| `VOICEVOX_URL` | API エンドポイント | `http://localhost:50021` |
| `VOICEVOX_SPEAKER` | スピーカー ID | `1`（ずんだもん） |

### COEIROINK

| 変数 | 説明 | デフォルト |
|------|------|----------|
| `COEIROINK_URL` | API エンドポイント | `http://localhost:50032` |
| `COEIROINK_SPEAKER` | スピーカー ID | `0` |

### AivisSpeech

| 変数 | 説明 | デフォルト |
|------|------|----------|
| `AIVIS_SPEECH_URL` | API エンドポイント | `http://localhost:10101` |
| `AIVIS_SPEECH_SPEAKER` | スピーカー ID | `0` |

### Style-Bert-VITS2

| 変数 | 説明 | デフォルト |
|------|------|----------|
| `STYLE_BERT_VITS2_URL` | API エンドポイント | `http://localhost:5000` |
| `STYLE_BERT_VITS2_MODEL` | モデル名 | `default` |

### Fish Audio

| 変数 | 説明 | 必須 |
|------|------|------|
| `FISH_AUDIO_API_KEY` | API キー | ✅ |
| `FISH_AUDIO_VOICE_ID` | ボイス ID | 推奨 |

### ElevenLabs

| 変数 | 説明 | 必須 |
|------|------|------|
| `ELEVENLABS_API_KEY` | API キー | ✅ |
| `ELEVENLABS_VOICE_ID` | ボイス ID | — (デフォルト: Rachel) |

### OpenAI TTS

| 変数 | 説明 | 必須 |
|------|------|------|
| `OPENAI_API_KEY` | API キー | ✅ |
| `OPENAI_TTS_VOICE` | ボイス名 | — (デフォルト: nova) |

---

## VOICEVOX キャラクター一覧（主要）

| ID | キャラクター |
|----|------------|
| 0 | 四国めたん（あまあま） |
| 1 | ずんだもん（ノーマル）★デフォルト |
| 2 | 四国めたん（ノーマル） |
| 3 | ずんだもん（あまあま） |
| 5 | ずんだもん（ツンツン） |
| 6 | ずんだもん（セクシー） |
| 7 | ずんだもん（ささやき） |
| 8 | 春日部つむぎ |

---

## 自分の声を使う（Style-Bert-VITS2）

1. [Style-Bert-VITS2](https://github.com/litagin02/Style-Bert-VITS2) をセットアップ
2. 自分の音声データで学習
3. 環境変数を設定：

```json
{
  "env": {
    "NOTIFY_PROVIDER": "style_bert_vits2",
    "STYLE_BERT_VITS2_MODEL": "my-voice"
  }
}
```

Udemy や動画制作で使った自分の声をそのまま通知音声にすることもできます。

---

## CLAUDE.md への組み込み

プロジェクトの `CLAUDE.md` に以下を追加すると、Claude Code が自動的に音声通知を使うようになります。
[templates/CLAUDE.md](templates/CLAUDE.md) を参照してください。

---

## トラブルシューティング

| 症状 | 原因 | 対処 |
|------|------|------|
| VOICEVOX に接続できない | アプリが起動していない | VOICEVOX を起動する |
| 音声が鳴らない（macOS） | afplay の問題 | `afplay /tmp/test.wav` で確認 |
| 音声が鳴らない（Windows） | WMP の問題 | PowerShell で手動テスト |
| ビルドエラー | node_modules がない | `npm install` を実行 |

---

## ライセンス

MIT License - [Masa_AIcreater](https://github.com/Masa_AIcreater)

## 謝辞

- [VOICEVOX](https://voicevox.hiroshiba.jp/) - 無料の音声合成エンジン
- [COEIROINK](https://coeiroink.com/) - 無料の音声合成ソフトウェア
- [AivisSpeech](https://aivis-project.com/) - 高品質ローカル TTS
- [Style-Bert-VITS2](https://github.com/litagin02/Style-Bert-VITS2) - カスタム音声学習
- [MCP](https://modelcontextprotocol.io/) - Model Context Protocol
