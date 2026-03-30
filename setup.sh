#!/bin/bash
# claude-voice-notify セットアップスクリプト
# VOICEVOX のインストール確認 → 自動インストール → Hooks登録を一括で行う

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NOTIFY_SCRIPT="$SCRIPT_DIR/notify.sh"

echo "=========================================="
echo "  claude-voice-notify セットアップ"
echo "=========================================="
echo ""

# --- 1. Node.js 確認 ---
echo "🔍 Node.js を確認..."
if command -v node > /dev/null 2>&1; then
  echo "   ✅ Node.js $(node -v)"
else
  echo "   ❌ Node.js が見つかりません。インストールしてください。"
  echo "      https://nodejs.org/"
  exit 1
fi

# --- 2. VOICEVOX 確認 & インストール ---
echo ""
echo "🔍 VOICEVOX を確認..."

VOICEVOX_INSTALLED=false
VOICEVOX_RUNNING=false

# インストール確認
if [ -d "/Applications/VOICEVOX.app" ] || mdfind "kMDItemCFBundleIdentifier == 'jp.hiroshiba.voicevox'" 2>/dev/null | grep -q .; then
  VOICEVOX_INSTALLED=true
  echo "   ✅ VOICEVOX がインストールされています"
fi

# 起動確認
if curl -s --max-time 1 "http://localhost:50021/version" > /dev/null 2>&1; then
  VOICEVOX_RUNNING=true
  VERSION=$(curl -s --max-time 1 "http://localhost:50021/version" 2>/dev/null | tr -d '"')
  echo "   ✅ VOICEVOX が起動しています (v$VERSION)"
fi

if [ "$VOICEVOX_INSTALLED" = false ]; then
  echo "   ⚠️  VOICEVOX が見つかりません"
  echo ""
  echo "   VOICEVOXをインストールしますか？"
  echo "   1) 自動ダウンロード＆インストール (推奨)"
  echo "   2) 公式サイトからダウンロード"
  echo "   3) スキップ (macOS say で代替)"
  echo ""
  read -p "   選択 [1/2/3]: " choice

  case "$choice" in
    1)
      echo "   📦 VOICEVOX を GitHub Releases からダウンロード中..."
      # アーキテクチャ判定
      ARCH=$(uname -m)
      if [ "$ARCH" = "arm64" ]; then
        ZIP_NAME="voicevox-macos-cpu-arm64"
      else
        ZIP_NAME="voicevox-macos-cpu-x64"
      fi
      # 最新バージョン取得
      LATEST_TAG=$(curl -sL "https://api.github.com/repos/VOICEVOX/voicevox/releases/latest" | python3 -c "import json,sys; print(json.load(sys.stdin)['tag_name'])" 2>/dev/null)
      if [ -z "$LATEST_TAG" ]; then
        LATEST_TAG="0.25.1"
      fi
      DL_URL="https://github.com/VOICEVOX/voicevox/releases/download/${LATEST_TAG}/${ZIP_NAME}-${LATEST_TAG}.zip"
      echo "   URL: $DL_URL"
      echo "   (約1.8GB - 数分かかります)"
      curl -L -o /tmp/voicevox-macos.zip "$DL_URL"
      if [ $? -eq 0 ]; then
        echo "   📂 展開中..."
        unzip -o -q /tmp/voicevox-macos.zip -d /tmp/voicevox-extract
        cp -R /tmp/voicevox-extract/VOICEVOX/VOICEVOX.app /Applications/
        rm -rf /tmp/voicevox-macos.zip /tmp/voicevox-extract
        VOICEVOX_INSTALLED=true
        echo "   ✅ /Applications/VOICEVOX.app にインストール完了"
      else
        echo "   ❌ ダウンロードに失敗しました"
        echo "   公式サイトからダウンロードしてください: https://voicevox.hiroshiba.jp/"
      fi
      ;;
    2)
      echo "   🌐 公式サイトを開きます..."
      open "https://voicevox.hiroshiba.jp/"
      echo "   ダウンロード・インストール後、再度このスクリプトを実行してください。"
      ;;
    3)
      echo "   ⏭️  スキップ。macOS say (Kyoko) を使用します。"
      echo "   後からVOICEVOXをインストールすれば自動的にずんだもんに切り替わります。"
      ;;
  esac
fi

# --- 3. VOICEVOX 起動 ---
if [ "$VOICEVOX_INSTALLED" = true ] && [ "$VOICEVOX_RUNNING" = false ]; then
  echo ""
  echo "🚀 VOICEVOX を起動しています..."
  open -a VOICEVOX 2>/dev/null || true
  echo "   起動中... (APIが利用可能になるまで数秒かかります)"
  for i in $(seq 1 15); do
    if curl -s --max-time 1 "http://localhost:50021/version" > /dev/null 2>&1; then
      VOICEVOX_RUNNING=true
      echo "   ✅ VOICEVOX 起動完了"
      break
    fi
    sleep 1
  done
  if [ "$VOICEVOX_RUNNING" = false ]; then
    echo "   ⚠️  VOICEVOX の起動に時間がかかっています。手動で起動してください。"
  fi
fi

# --- 4. npm build ---
echo ""
echo "🔨 プロジェクトをビルド..."
cd "$SCRIPT_DIR"
if [ ! -d "node_modules" ]; then
  npm install
fi
npm run build
echo "   ✅ ビルド完了"

# --- 5. Claude Code 設定 ---
echo ""
echo "🔧 Claude Code の設定..."
CLAUDE_SETTINGS="$HOME/.claude/settings.json"

if [ -f "$CLAUDE_SETTINGS" ]; then
  if grep -q "voice-notify" "$CLAUDE_SETTINGS" 2>/dev/null; then
    echo "   ✅ Hooks は既に設定されています"
  else
    echo "   ⚠️  以下を $CLAUDE_SETTINGS の hooks に追加してください:"
    echo ""
    cat <<HOOKEOF
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "$NOTIFY_SCRIPT 'タスクが完了しました' complete"
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
            "command": "$NOTIFY_SCRIPT '確認をお願いします' confirm"
          }
        ]
      }
    ]
HOOKEOF
  fi
else
  echo "   ⚠️  Claude Code の設定ファイルが見つかりません"
fi

# --- 6. テスト ---
echo ""
echo "🔊 音声テスト..."
"$NOTIFY_SCRIPT" "セットアップが完了しました。音声通知が正常に動作しています。" complete
echo "   音声が聞こえましたか？"

echo ""
echo "=========================================="
echo "  セットアップ完了！"
echo "=========================================="
echo ""
if [ "$VOICEVOX_RUNNING" = true ]; then
  echo "  🎉 VOICEVOX（ずんだもん）で通知します"
else
  echo "  🎉 macOS say（Kyoko）で通知します"
  echo "  💡 VOICEVOXをインストール・起動すると自動的にずんだもんに切り替わります"
fi
echo ""
echo "  次のステップ:"
echo "  - Claude Code を使って作業すると、タスク完了時に音声で通知されます"
echo "  - CLAUDE.md に templates/CLAUDE.md の内容を追加すると、より細かい通知が可能です"
echo ""
