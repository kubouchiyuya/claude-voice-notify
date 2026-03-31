# claude-voice-notify

> ⭐ **クローン（ダウンロード）してくれた方へ**: このツールが役立ったら、ぜひ上の「Star」ボタンを押してください！あなたのスターが開発の励みになります！

> 💡 **エンジニア以外の方へ**: このツールは専門知識がなくても使えるよう設計されています。
> 初回セットアップ時に音声で使い方を案内します。用語がわからない場合は「用語説明モード」（デフォルトON）が自動的に説明します。

> 🎙️ **VS Code拡張機能について**: このリポジトリにはVS Code拡張機能が含まれています。
> セットアップするだけで自動的に使えるようになります。オンライン会議中は設定パネル（`./settings.sh`）から音声をOFFにできます。

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

## MCP ツール一覧

| ツール名 | 用途 | デフォルトメッセージ |
|---------|------|-------------------|
| `notify_complete` | タスク完了通知 | 「タスクが完了しました」 |
| `notify_confirm` | 確認要求通知 | 「確認をお願いします」 |
| `notify_speak` | カスタム読み上げ | （text 必須） |
| `notify_test` | 接続テスト | 「テスト成功」 |
| `notify_list_providers` | プロバイダー一覧表示 | — |

すべてのツールは `.voice-config` の設定（音量・速度・スピーカー）を自動的に反映します。

---

<details>
<summary><strong>導入手順（10ステップ）</strong></summary>

### 方法 A: ワンコマンドセットアップ（推奨）

> お好きな場所にクローンしてください。おすすめ:
> - macOS / Linux: `~/Projects/` または `~/dev/`
> - Windows: `C:\Users\<ユーザー名>\Projects\`

**macOS / Linux:**

```bash
# 1. Star する（必須） → https://github.com/kubouchiyuya/claude-voice-notify
# 2. 好きなディレクトリに移動（例: ~/Projects）
cd ~/Projects

# 3. クローン
git clone https://github.com/kubouchiyuya/claude-voice-notify.git

# 4. ディレクトリに入る
cd claude-voice-notify

# 5. セットアップ実行（あとは全自動）
./setup.sh
```

**Windows:**

```cmd
cd %USERPROFILE%\Projects
git clone https://github.com/kubouchiyuya/claude-voice-notify.git
cd claude-voice-notify
setup.bat
```

**setup.sh / setup.bat が自動で行うこと：**

| ステップ | 内容 |
|---------|------|
| 5-1 | GitHub Star の確認（ユーザー名を聞かれます） |
| 5-2 | VOICEVOX の検出・インストール案内 |
| 5-3 | `npm install` & `npm run build` |
| 5-4 | プロバイダー選択（対話式で8種から選べる） |
| 5-5 | キャラクター選択（性別・方言フィルター付き） |
| 5-6 | VS Code 拡張機能の自動インストール |
| 5-7 | Claude Code Hooks 設定ガイド表示 |
| 5-8 | 音声テスト再生 |

**セットアップ後にやること：**

```bash
# 6. VOICEVOX を起動（まだの場合）
# 7. Claude Code Hooks を ~/.claude/settings.json にコピペ（画面の指示に従う）
# 8. テスト
./notify.sh "テスト成功"

# 9. 設定パネルでカスタマイズ（キャラ・速度・音量・エンジン）
./settings.sh

# 10. 完了！Claude Code が音声で通知してくれます
```

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

</details>

<details>
<summary><strong>音量・速度・キャラクター設定</strong></summary>

### 音量・速度調整

```bash
# 音量調整（0.0〜1.0、デフォルト: 1.0）
./notify.sh set-volume 0.5    # 半分の音量
./notify.sh set-volume 0.3    # 控えめ（会議中のお隣さん対策）
./notify.sh set-volume 1.0    # 最大音量

# 速度調整（0.5〜2.0、デフォルト: 1.0）
./notify.sh set-speed 1.2     # やや速め
./notify.sh set-speed 0.8     # ゆっくり

# 設定パネル（GUIライクな対話式メニュー）
./settings.sh
```

### キャラクター管理

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

</details>

<details>
<summary><strong>環境変数リファレンス</strong></summary>

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
| `FISH_AUDIO_API_KEY` | API キー | はい |
| `FISH_AUDIO_VOICE_ID` | ボイス ID | 推奨 |

### ElevenLabs

| 変数 | 説明 | 必須 |
|------|------|------|
| `ELEVENLABS_API_KEY` | API キー | はい |
| `ELEVENLABS_VOICE_ID` | ボイス ID | — (デフォルト: Rachel) |

### OpenAI TTS

| 変数 | 説明 | 必須 |
|------|------|------|
| `OPENAI_API_KEY` | API キー | はい |
| `OPENAI_TTS_VOICE` | ボイス名 | — (デフォルト: nova) |

### Google Cloud TTS

| 変数 | 説明 | 必須 |
|------|------|------|
| `GOOGLE_TTS_API_KEY` | API キー | はい |
| `GOOGLE_TTS_VOICE` | 音声名 | — (デフォルト: ja-JP-Neural2-B) |

Google Cloud TTS は月100万文字まで無料。`./notify.sh set-provider google` で切り替え。

</details>

<details>
<summary><strong>自分の声を使う（Style-Bert-VITS2）</strong></summary>

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

</details>

<details>
<summary><strong>CLAUDE.md への組み込み</strong></summary>

プロジェクトの `CLAUDE.md` に以下を追加すると、Claude Code が自動的に音声通知を使うようになります。
[templates/CLAUDE.md](templates/CLAUDE.md) を参照してください。

</details>

<details>
<summary><strong>アップデート</strong></summary>

クローンした人はワンコマンドで最新版に更新できます：

```bash
./update.sh
```

- 更新内容を確認 → 確認後に `git pull` & `npm run build` を自動実行
- リリース通知を受け取るには、リポジトリを **Watch > Releases only** に設定してください

</details>

<details>
<summary><strong>ディレクトリ構成</strong></summary>

```
claude-voice-notify/
├── notify.sh          ← 音声通知の本体（bashから直接呼べる）
├── settings.sh        ← 設定パネル（キャラ・速度・音量・エンジン）
├── setup.sh           ← 初回セットアップ（自動インストール）
├── update.sh          ← ワンコマンド更新
├── .voice-config      ← 設定ファイル（自動生成・gitignore済み）
├── .voice-enabled     ← ON/OFF状態（自動生成）
├── src/               ← MCP サーバー本体（TypeScript）
│   ├── index.ts       ← MCPエントリーポイント
│   ├── provider-base.ts ← 音声再生共通処理
│   └── providers/     ← 各プロバイダー実装
├── dist/              ← ビルド済み（npm run build で生成）
├── templates/
│   └── CLAUDE.md      ← プロジェクトに組み込むテンプレート
├── vscode-extension/  ← VS Code 拡張機能
└── CLAUDE.md          ← Claude Code 用の設定指示
```

**設定ファイル（`.voice-config`）の保存場所：**
- クローンしたディレクトリ直下に自動生成されます
- Git にはコミットされません（`.gitignore` 済み）
- 手動で編集も可能（key=value 形式）

</details>

<details>
<summary><strong>トラブルシューティング</strong></summary>

| 症状 | 原因 | 対処 |
|------|------|------|
| VOICEVOX に接続できない | アプリが起動していない | VOICEVOX を起動する |
| 音声が鳴らない（macOS） | afplay の問題 | `afplay /tmp/test.wav` で確認 |
| 音声が鳴らない（Windows） | WMP の問題 | PowerShell で手動テスト |
| ビルドエラー | node_modules がない | `npm install` を実行 |
| 設定が反映されない（MCP） | サーバー未再起動 | VS Code: Cmd+Shift+P → Developer: Reload Window |

</details>

---

## 免責事項・法的注意事項

### 音声合成に関する重要事項

本ソフトウェアは音声合成エンジンを利用して音声を生成します。音声合成の利用にあたっては、以下の点にご注意ください。

1. **各音声合成エンジンの利用規約を遵守してください。** 本ソフトウェアが対応する各プロバイダー（VOICEVOX、COEIROINK、AivisSpeech、Style-Bert-VITS2、Google Cloud TTS、Fish Audio、ElevenLabs、OpenAI TTS）には、それぞれ独自の利用規約・ライセンスがあります。ユーザーは使用するプロバイダーの規約を確認し、遵守する責任を負います。

2. **キャラクターの音声には著作権・利用条件があります。** VOICEVOX や COEIROINK 等のキャラクター音声は、各キャラクターの権利者が定めるガイドラインに従って使用する必要があります。商用利用・配信・公開等を行う場合は、必ず各キャラクターの利用規約をご確認ください。

3. **音声クローン技術の利用について。** Style-Bert-VITS2、Fish Audio 等の音声クローン技術を使用する場合、他者の声を無断で複製・使用することは、肖像権・パブリシティ権・著作権等の侵害となる可能性があります。音声クローンは必ず本人の同意を得た上で、または自分自身の声のみで使用してください。

4. **生成された音声コンテンツの責任。** 本ソフトウェアを使用して生成された音声コンテンツに関する一切の責任は、ユーザーが負うものとします。生成物を公開・配信・商用利用する場合は、適用される法律（著作権法、不正競争防止法、個人情報保護法等）を遵守してください。

### 免責条項

本ソフトウェアは「現状のまま（AS IS）」で提供されます。作者および貢献者は、本ソフトウェアの使用に起因する**いかなる損害（直接的・間接的・偶発的・特別・結果的損害を含む）についても一切の責任を負いません**。これには以下が含まれますが、これに限定されません：

- 音声合成エンジンの利用規約違反に起因する損害
- 著作権・肖像権・パブリシティ権その他の権利侵害に起因する損害
- 音声データの不正使用・漏洩に起因する損害
- 第三者の知的財産権の侵害に起因する損害
- 本ソフトウェアの不具合・動作不良に起因する損害

ユーザーは、本ソフトウェアの使用が適用される全ての法令に準拠していることを自ら確認する責任を負います。

---

## ライセンス

MIT License - [kubouchiyuya](https://github.com/kubouchiyuya)

## 謝辞

- [VOICEVOX](https://voicevox.hiroshiba.jp/) - 無料の音声合成エンジン（ずんだもん等）
- [COEIROINK](https://coeiroink.com/) - 無料の音声合成ソフトウェア（つくよみちゃん等）
- [AivisSpeech](https://aivis-project.com/) - 高品質ローカル TTS
- [Style-Bert-VITS2](https://github.com/litagin02/Style-Bert-VITS2) - カスタム音声学習
- [Google Cloud TTS](https://cloud.google.com/text-to-speech) - 高品質クラウド TTS
- [Fish Audio](https://fish.audio/) - リアルタイム音声クローン
- [ElevenLabs](https://elevenlabs.io/) - 感情豊かな音声合成
- [OpenAI TTS](https://platform.openai.com/docs/guides/text-to-speech) - OpenAI 音声技術
- [MCP](https://modelcontextprotocol.io/) - Model Context Protocol
