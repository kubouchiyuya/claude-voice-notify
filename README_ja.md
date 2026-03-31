<div align="center">

<a href="./README.md"><img src="https://img.shields.io/badge/🌐%20English-gray?style=flat-square" /></a>
<a href="./README_ja.md"><img src="https://img.shields.io/badge/🇯🇵%20日本語-active-F97316?style=flat-square" /></a>

<br/><br/>

<img src="https://capsule-render.vercel.app/api?type=waving&color=gradient&customColorList=12,20,30&height=200&section=header&text=claude-voice-notify&fontSize=40&fontColor=fff&animation=fadeIn&desc=Claude%20Code%20に%20音声通知を届ける%20%E2%80%94%208%20プロバイダー対応&descSize=18&descAlignY=70" width="100%"/>

<img src="https://raw.githubusercontent.com/kubouchiyuya/kubouchiyuya/main/avatar.jpg" width="120" style="border-radius:50%; margin-top:16px"/>

[![Typing SVG](https://readme-typing-svg.demolab.com?font=Fira+Code&weight=700&size=22&duration=3000&pause=1000&color=F97316&center=true&vCenter=true&multiline=true&width=900&height=140&lines=Claude+Code+が声で知らせる+%F0%9F%8E%99%EF%B8%8F;8+つの音声エンジンに対応+%E2%80%94+無料から有料まで;デフォルトは+VOICEVOX+%28ずんだもん%29+%E2%80%94+API+キー不要)](https://github.com/DenverCoder1/readme-typing-svg)

[![GitHub](https://img.shields.io/badge/GitHub-kubouchiyuya-181717?style=for-the-badge&logo=github)](https://github.com/kubouchiyuya)
[![X](https://img.shields.io/badge/@kubouchiyuya-000000?style=for-the-badge&logo=x&logoColor=white)](https://x.com/kubouchiyuya)
[![LP](https://img.shields.io/badge/Consulting%20LP-F97316?style=for-the-badge&logo=vercel&logoColor=white)](https://consulting-payment-tool.vercel.app)

![Stars](https://img.shields.io/github/stars/kubouchiyuya/claude-voice-notify?style=flat-square&color=F97316)
![Forks](https://img.shields.io/github/forks/kubouchiyuya/claude-voice-notify?style=flat-square&color=gray)
![License](https://img.shields.io/github/license/kubouchiyuya/claude-voice-notify?style=flat-square)
<img src="https://komarev.com/ghpvc/?username=kubouchiyuya&label=Views&color=F97316&style=flat-square"/>

</div>

---

## このツールでできること

`claude-voice-notify` は、Claude Code に「声」を持たせるための仕組みです。タスク完了、確認待ち、エラー発生を音声で伝えるので、キーボードの前にいなくても状況を把握できます。

デフォルトはローカル動作の VOICEVOX。API キー不要で無料です。必要に応じて 8 種類の音声プロバイダーに切り替えられます。

---

## 何のためにあるか

MASA は、美容室オーナーとしての現場感覚を起点に、AI を実行基盤として使うための仕組みを作っています。

このリポジトリは、その中の「通知レイヤー」です。

| 層 | 役割 |
|---|---|
| 人間の意図 | MASA がゴールを決める |
| Claude Code | 実装と実行を担う |
| 音声レイヤー | 何が起きたかを伝える |
| 音声プロバイダー | 最適な読み上げ方式を選ぶ |

---

## ✨ 機能

| 機能 | 説明 |
|---|---|
| 8 プロバイダー対応 | VOICEVOX / COEIROINK / AivisSpeech / Style-Bert-VITS2 / Google TTS / Fish Audio / ElevenLabs / OpenAI |
| ローカル既定 | VOICEVOX はローカルで動作し、API キー不要 |
| スターゲート | GitHub Star で利用可否を確認 |
| 言語切り替え | 日本語 / 英語の通知に対応 |
| 用語説明モード | 専門用語を平易な言葉で説明 |
| VS Code 連携 | エディタから通知の ON/OFF を切り替え可能 |
| ワンコマンド更新 | `./update.sh` で更新を維持 |

---

## 🚀 はじめかた

### まずスターを押す

> このツールは GitHub Star を前提にした設計です。セットアップ前にスターを押してください。

### セットアップ

```bash
cd ~/Projects
git clone https://github.com/kubouchiyuya/claude-voice-notify.git
cd claude-voice-notify
./setup.sh
```

### テスト

```bash
./notify.sh "セットアップ成功"
```

### Hooks 設定

`~/.claude/settings.json` に追加します。

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

---

## 🏗️ アーキテクチャ

```mermaid
graph TD
    A[Claude Code] -->|Hook: Stop / Notification| B[notify.sh]
    A -->|MCP ツール呼び出し| C[MCP サーバー dist/index.js]
    B --> D{プロバイダー振り分け}
    C --> D
    D -->|voicevox| E[VOICEVOX ローカル API]
    D -->|coeiroink| F[COEIROINK ローカル API]
    D -->|aivis_speech| G[AivisSpeech ローカル API]
    D -->|style_bert_vits2| H[Style-Bert-VITS2]
    D -->|google| I[Google Cloud TTS]
    D -->|fish_audio| J[Fish Audio API]
    D -->|elevenlabs| K[ElevenLabs API]
    D -->|openai| L[OpenAI TTS API]
    E --> M[再生: afplay / paplay / PowerShell]
    F --> M
    G --> M
    H --> M
    I --> M
    J --> M
    K --> M
    L --> M
```

---

## 🛠️ 技術スタック

![TypeScript](https://img.shields.io/badge/TypeScript-3178C6?style=for-the-badge&logo=typescript&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=node.js&logoColor=white)
![MCP](https://img.shields.io/badge/MCP-Model%20Context%20Protocol-blue?style=for-the-badge)
![VOICEVOX](https://img.shields.io/badge/VOICEVOX-Free-brightgreen?style=for-the-badge)
![Shell](https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)

---

## 👤 作者

<div align="center">

| | |
|---|---|
| **窪内裕也（MASA2 / MASA サブ）** | 美容室オーナー → AI アーキテクト |
| 拠点 | 大阪 |
| 所属 | AKATSUKI / Miyabi Society |
| 重点 | AI × 美容業界 × 非エンジニア運用 |

*"私はコードを書く人ではなく、AI が実装する仕組みを設計する人です。"*

</div>

---

<div align="center">
<img src="https://capsule-render.vercel.app/api?type=waving&color=gradient&customColorList=12,20,30&height=100&section=footer" width="100%"/>

**時間を節約できたなら、スターで返してください。**

</div>
