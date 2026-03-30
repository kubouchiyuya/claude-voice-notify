# claude-voice-notify

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Node.js](https://img.shields.io/badge/node-%3E%3D18-brightgreen)](https://nodejs.org/)
[![MCP](https://img.shields.io/badge/MCP-Compatible-blue)](https://modelcontextprotocol.io/)

**Claude Code 用マルチプロバイダー音声通知 MCP サーバー**

Claude Code がタスク完了・確認要求・エラー発生時に**音声でユーザーに知らせる** MCP サーバーです。
デフォルトは **VOICEVOX（ずんだもん）** で完全無料・API キー不要。
環境変数 1 行で音声エンジンを差し替えられるプラグイン型設計。

> **⭐ このツールを使うには [Star](https://github.com/kubouchiyuya/claude-voice-notify) が必要です。**
> セットアップ時に GitHub ユーザー名を確認し、Star 済みの方のみ利用できます。

---

## 対応プロバイダー（8 種）

| 値 | 名前 | 料金 | 特徴 |
|----|------|------|------|
| `voicevox` | **VOICEVOX** | **無料** | デフォルト・ずんだもん含む100+キャラ |
| `coeiroink` | COEIROINK | **無料** | つくよみちゃん等 |
| `aivis_speech` | AivisSpeech | **無料** | 高品質ローカル・VOICEVOX 互換 |
| `style_bert_vits2` | Style-Bert-VITS2 | **無料** | 自分の声・好きなキャラの声を学習可能 |
| `google` | **Google Cloud TTS** | **無料枠あり** | 月100万文字無料・Neural2高品質 |
| `fish_audio` | Fish Audio | 有料 | 高品質クラウド TTS |
| `elevenlabs` | ElevenLabs | 有料(無料枠あり) | 英語最強 |
| `openai` | OpenAI TTS | 有料 | nova / alloy 等 |

---

## 導入手順

### 方法 A: ワンコマンドセットアップ（推奨）

**macOS / Linux:**

```bash
git clone https://github.com/kubouchiyuya/claude-voice-notify.git
cd claude-voice-notify
./setup.sh
```

**Windows:**

```cmd
git clone https://github.com/kubouchiyuya/claude-voice-notify.git
cd claude-voice-notify
setup.bat
```

セットアップスクリプトが以下を自動で行います：
- VOICEVOX の検出・自動インストール（macOS: GitHub Releases / Windows: winget）
- `npm install` & `npm run build`
- Claude Code Hooks の設定ガイド
- 音声テスト

**VOICEVOX がなくても動きます：**
- macOS → `say` コマンド（Kyoko）に自動フォールバック
- Windows → Windows SAPI（日本語音声）に自動フォールバック

後から VOICEVOX をインストール・起動すれば、自動的にずんだもんの声に切り替わります。

### 方法 B: 手動セットアップ

#### 1. リポジトリを clone してビルド

```bash
git clone https://github.com/kubouchiyuya/claude-voice-notify.git
cd claude-voice-notify
npm install
npm run build
```

#### 2. VOICEVOX をインストール（任意）

**macOS:**
```bash
# 公式サイトからダウンロード
open https://voicevox.hiroshiba.jp/
```

**Windows:**
```cmd
# winget でインストール
winget install Hiroshiba.VOICEVOX

# または公式サイトからダウンロード
# https://voicevox.hiroshiba.jp/
```

インストールしなくても macOS `say` / Windows SAPI で動作します。

### 3. Claude Code Hooks を設定（再起動不要）

`~/.claude/settings.json` の `hooks` に追加：

**macOS / Linux:**

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/claude-voice-notify/notify.sh 'タスクが完了しました' complete"
          }
        ]
      }
    ],
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/claude-voice-notify/notify.sh '確認をお願いします' confirm"
          }
        ]
      }
    ]
  }
}
```

**Windows:**

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "powershell -ExecutionPolicy Bypass -File C:\\path\\to\\claude-voice-notify\\notify.ps1 'タスクが完了しました' complete"
          }
        ]
      }
    ],
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "powershell -ExecutionPolicy Bypass -File C:\\path\\to\\claude-voice-notify\\notify.ps1 '確認をお願いします' confirm"
          }
        ]
      }
    ]
  }
}
```

### 4. (任意) MCP サーバーも追加

`~/.claude.json` の `mcpServers` に追加すると、Claude が状況に応じたカスタムメッセージを読み上げられます：

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

### 5. テスト

```bash
# 直接テスト（即実行）
./notify.sh "テスト成功"

# Claude Code 経由（MCP設定後）
# → 「notify_test を実行して」
```

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

### Google Cloud TTS

| 変数 | 説明 | 必須 |
|------|------|------|
| `GOOGLE_TTS_API_KEY` | API キー | ✅ |
| `GOOGLE_TTS_VOICE` | 音声名 | — (デフォルト: ja-JP-Neural2-B) |

Google Cloud TTS は月100万文字まで無料。`./notify.sh set-provider google` で切り替え。

---

## キャラクター管理

```bash
# 一覧表示（★ = 現在のデフォルト）
./notify.sh list

# デフォルトキャラを変更
./notify.sh set-speaker 8    # 春日部つむぎ

# 一時的に別キャラで喋らせる（デフォルトは変えない）
./notify.sh "メッセージ" complete 8
```

### VOICEVOX キャラクター一覧（主要）

| ID | キャラクター | ID | キャラクター |
|----|-----------|----|-----------|
| 3 | ずんだもん（ノーマル） | 1 | ずんだもん（あまあま） |
| 7 | ずんだもん（ツンツン） | 5 | ずんだもん（セクシー） |
| 22 | ずんだもん（ささやき） | 8 | 春日部つむぎ |
| 2 | 四国めたん（ノーマル） | 0 | 四国めたん（あまあま） |
| 10 | 雨晴はう | 9 | 波音リツ |
| 13 | 青山龍星 | 14 | 冥鳴ひまり |
| 20 | もち子さん | 46 | 小夜/SAYO |

100+ キャラクターが利用可能。`./notify.sh list` で全一覧を確認できます。

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
