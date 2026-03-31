<div align="center">

<a href="./README.md"><img src="https://img.shields.io/badge/🌐%20English-active-F97316?style=flat-square" /></a>
<a href="./README_ja.md"><img src="https://img.shields.io/badge/🇯🇵%20日本語-gray?style=flat-square" /></a>

<br/><br/>

<img src="https://capsule-render.vercel.app/api?type=waving&color=gradient&customColorList=12,20,30&height=200&section=header&text=claude-voice-notify&fontSize=40&fontColor=fff&animation=fadeIn&desc=Multi-Provider%20Voice%20Notifications%20for%20Claude%20Code&descSize=18&descAlignY=70" width="100%"/>

<img src="https://raw.githubusercontent.com/kubouchiyuya/kubouchiyuya/main/avatar.jpg" width="120" style="border-radius:50%; margin-top:16px"/>

[![Typing SVG](https://readme-typing-svg.demolab.com?font=Fira+Code&weight=700&size=22&duration=3000&pause=1000&color=F97316&center=true&vCenter=true&multiline=true&width=900&height=140&lines=Voice+Notifications+for+Claude+Code+%F0%9F%8E%99%EF%B8%8F;8+Providers+Supported+%E2%80%94+Free+to+Paid;Default%3A+VOICEVOX+%28Zundamon%29+%E2%80%94+No+API+Key+Needed)](https://github.com/DenverCoder1/readme-typing-svg)

[![GitHub](https://img.shields.io/badge/GitHub-kubouchiyuya-181717?style=for-the-badge&logo=github)](https://github.com/kubouchiyuya)
[![X](https://img.shields.io/badge/@kubouchiyuya-000000?style=for-the-badge&logo=x&logoColor=white)](https://x.com/kubouchiyuya)
[![LP](https://img.shields.io/badge/Consulting%20LP-F97316?style=for-the-badge&logo=vercel&logoColor=white)](https://consulting-payment-tool.vercel.app)

![Stars](https://img.shields.io/github/stars/kubouchiyuya/claude-voice-notify?style=flat-square&color=F97316)
![Forks](https://img.shields.io/github/forks/kubouchiyuya/claude-voice-notify?style=flat-square&color=gray)
![License](https://img.shields.io/github/license/kubouchiyuya/claude-voice-notify?style=flat-square)
<img src="https://komarev.com/ghpvc/?username=kubouchiyuya&label=Views&color=F97316&style=flat-square"/>

</div>

---

## What This Does

`claude-voice-notify` turns Claude Code into a voice-aware workflow. It speaks when a task completes, when a confirmation is needed, or when an error appears, so you can keep moving even if you are away from the keyboard.

The default engine is VOICEVOX, which runs locally and costs nothing to use. If you want to change the sound or the provider, the repository supports eight backends and a guided setup flow for non-engineers.

---

## Why This Exists

MASA builds tools from the perspective of a salon owner who uses AI as the execution layer.

This repository is one of the interfaces in that system:

| Layer | Role |
|---|---|
| Human intent | MASA defines the outcome |
| Claude Code | Implements the work |
| Voice layer | Tells the human what happened |
| Provider layer | Selects the best TTS engine |

---

## ✨ Features

| Feature | Description |
|---|---|
| 8 providers | VOICEVOX, COEIROINK, AivisSpeech, Style-Bert-VITS2, Google TTS, Fish Audio, ElevenLabs, OpenAI |
| Local default | VOICEVOX runs locally with no API key |
| Star gate | GitHub Star verification for community access control |
| Language switch | Japanese and English notification output |
| Terminology mode | Explains technical terms in plain language |
| VS Code support | Toggle notification behavior from the editor |
| One-command update | Keep the setup current with `./update.sh` |

---

## 🚀 Quick Start

### Star First

> This tool is designed with a GitHub Star gate. Star the repo before setup.

### Setup

```bash
cd ~/Projects
git clone https://github.com/kubouchiyuya/claude-voice-notify.git
cd claude-voice-notify
./setup.sh
```

### Test

```bash
./notify.sh "Setup successful"
```

### Hooks

Add this to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/claude-voice-notify/notify.sh 'Task complete' complete"
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
            "command": "/path/to/claude-voice-notify/notify.sh 'Please confirm' confirm"
          }
        ]
      }
    ]
  }
}
```

---

## 🏗️ Architecture

```mermaid
graph TD
    A[Claude Code] -->|Hook: Stop / Notification| B[notify.sh]
    A -->|MCP tool call| C[MCP server dist/index.js]
    B --> D{Provider router}
    C --> D
    D -->|voicevox| E[VOICEVOX local API]
    D -->|coeiroink| F[COEIROINK local API]
    D -->|aivis_speech| G[AivisSpeech local API]
    D -->|style_bert_vits2| H[Style-Bert-VITS2]
    D -->|google| I[Google Cloud TTS]
    D -->|fish_audio| J[Fish Audio API]
    D -->|elevenlabs| K[ElevenLabs API]
    D -->|openai| L[OpenAI TTS API]
    E --> M[Playback: afplay / paplay / PowerShell]
    F --> M
    G --> M
    H --> M
    I --> M
    J --> M
    K --> M
    L --> M
```

---

## 🛠️ Tech Stack

![TypeScript](https://img.shields.io/badge/TypeScript-3178C6?style=for-the-badge&logo=typescript&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=node.js&logoColor=white)
![MCP](https://img.shields.io/badge/MCP-Model%20Context%20Protocol-blue?style=for-the-badge)
![VOICEVOX](https://img.shields.io/badge/VOICEVOX-Free-brightgreen?style=for-the-badge)
![Shell](https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)

---

## 👤 Author

<div align="center">

| | |
|---|---|
| **Yuya Kubouchi (MASA2 / MASA Sub)** | Beauty Salon Owner → AI Architect |
| Location | Osaka, Japan |
| System | AKATSUKI / Miyabi Society |
| Focus | AI × Beauty Industry × Non-Engineer Operations |

*"I do not code first. I design the system, and AI executes it."*

</div>

---

<div align="center">
<img src="https://capsule-render.vercel.app/api?type=waving&color=gradient&customColorList=12,20,30&height=100&section=footer" width="100%"/>

**If this saved you time, please give it a star.**

</div>
