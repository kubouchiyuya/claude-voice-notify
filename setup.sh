#!/bin/bash
# claude-voice-notify セットアップウィザード
# ⭐ Star確認 → プロバイダー選択ガイド → インストール → キャラ選択 → テスト

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NOTIFY_SCRIPT="$SCRIPT_DIR/notify.sh"
CONFIG_FILE="$SCRIPT_DIR/.voice-config"
REPO_OWNER="kubouchiyuya"
REPO_NAME="claude-voice-notify"
REPO_URL="https://github.com/$REPO_OWNER/$REPO_NAME"
VOICEVOX_URL="http://localhost:50021"

echo ""
echo "  ╔══════════════════════════════════════════════╗"
echo "  ║   claude-voice-notify セットアップウィザード    ║"
echo "  ║   Claude Code が声で報告するようになります     ║"
echo "  ╚══════════════════════════════════════════════╝"
echo ""

# ============================================
# STEP 0: ⭐ Star ゲート
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  STEP 0: ⭐ Star 確認"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  このツールを使うには、リポジトリへの Star が必要です。"
echo "  $REPO_URL"
echo ""
read -p "  GitHubユーザー名を入力: " GITHUB_USER

if [ -z "$GITHUB_USER" ]; then
  echo "  ❌ ユーザー名が入力されませんでした"
  exit 1
fi

STAR_CHECK=$(curl -s -o /dev/null -w "%{http_code}" \
  "https://api.github.com/users/$GITHUB_USER/starred/$REPO_OWNER/$REPO_NAME" 2>/dev/null)

if [ "$STAR_CHECK" = "204" ]; then
  echo "  ✅ @$GITHUB_USER さん、Star ありがとうございます！"
else
  echo ""
  echo "  ❌ @$GITHUB_USER のStar が確認できません。"
  echo ""
  echo "  → $REPO_URL を開いて ☆ Star をクリックしてください"
  read -p "  ブラウザで開きますか？ [y/N]: " OPEN
  if [ "$OPEN" = "y" ] || [ "$OPEN" = "Y" ]; then
    open "$REPO_URL" 2>/dev/null || xdg-open "$REPO_URL" 2>/dev/null || true
    echo "  Star後、再度 ./setup.sh を実行してください"
  fi
  exit 1
fi

# ============================================
# STEP 1: Node.js 確認
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  STEP 1: 環境チェック"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
if command -v node > /dev/null 2>&1; then
  echo "  ✅ Node.js $(node -v)"
else
  echo "  ❌ Node.js が必要です → https://nodejs.org/"
  exit 1
fi

# ============================================
# STEP 2: 音声エンジン選択ガイド
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  STEP 2: 音声エンジンを選ぶ"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Claude Code が喋る声を選びます。"
echo "  おすすめは ①VOICEVOX です（無料・かわいい声・すぐ使える）"
echo ""
echo "  ┌─────────────────────────────────────────────────────────┐"
echo "  │ #  エンジン名         料金         特徴                  │"
echo "  ├─────────────────────────────────────────────────────────┤"
echo "  │ 1  VOICEVOX          無料 ★おすすめ ずんだもん等100+キャラ │"
echo "  │                                    インストールするだけ   │"
echo "  │                                    APIキー不要           │"
echo "  ├─────────────────────────────────────────────────────────┤"
echo "  │ 2  Google Cloud TTS  無料枠あり    月100万文字まで無料    │"
echo "  │                      (超過後有料)  高品質・自然な声       │"
echo "  │                                    Google APIキーが必要   │"
echo "  ├─────────────────────────────────────────────────────────┤"
echo "  │ 3  その他            様々          Fish Audio, ElevenLabs │"
echo "  │    (上級者向け)                    OpenAI TTS, 自分の声等 │"
echo "  │                                    後から切り替え可能     │"
echo "  └─────────────────────────────────────────────────────────┘"
echo ""
echo "  💡 迷ったら 1 を選んでください。"
echo "     VOICEVOXは無料で、ずんだもんや春日部つむぎなど"
echo "     100以上のキャラクターの声が使えます。"
echo "     後から別のエンジンに切り替えることもできます。"
echo ""
read -p "  番号を選択 [1]: " ENGINE_CHOICE
ENGINE_CHOICE="${ENGINE_CHOICE:-1}"

case "$ENGINE_CHOICE" in
  1)
    SELECTED_PROVIDER="voicevox"
    echo ""
    echo "  ✅ VOICEVOX を選択しました"
    ;;
  2)
    SELECTED_PROVIDER="google"
    echo ""
    echo "  ✅ Google Cloud TTS を選択しました"
    echo ""
    echo "  Google Cloud TTS を使うには APIキーが必要です。"
    echo "  取得方法: https://console.cloud.google.com/apis/credentials"
    echo "  → 「Text-to-Speech API」を有効化 → APIキーを作成"
    echo ""
    read -p "  Google TTS APIキーを入力 (後で設定する場合は空Enter): " GOOGLE_KEY
    if [ -n "$GOOGLE_KEY" ]; then
      "$NOTIFY_SCRIPT" set-google-key "$GOOGLE_KEY"
    else
      echo "  ⏭️  後で ./notify.sh set-google-key <KEY> で設定してください"
    fi
    echo ""
    read -p "  Google TTS 音声名 [ja-JP-Neural2-B]: " GOOGLE_VOICE_NAME
    if [ -n "$GOOGLE_VOICE_NAME" ]; then
      "$NOTIFY_SCRIPT" set-google-voice "$GOOGLE_VOICE_NAME"
    fi
    "$NOTIFY_SCRIPT" set-provider google
    ;;
  3)
    SELECTED_PROVIDER="voicevox"
    echo ""
    echo "  まずはVOICEVOXでセットアップします。"
    echo "  後から ./notify.sh set-provider <名前> で切り替えできます。"
    echo ""
    echo "  対応エンジン:"
    echo "    voicevox       - 無料・ローカル（デフォルト）"
    echo "    google          - Google Cloud TTS（無料枠あり）"
    echo "    coeiroink       - 無料・ローカル"
    echo "    aivis_speech    - 無料・高品質ローカル"
    echo "    style_bert_vits2- 無料・自分の声を学習可能"
    echo "    fish_audio      - 有料・クラウド"
    echo "    elevenlabs      - 有料（無料枠あり）・英語最強"
    echo "    openai          - 有料・OpenAI TTS"
    ;;
esac

# ============================================
# STEP 3: VOICEVOX インストール（選択時のみ）
# ============================================
if [ "$SELECTED_PROVIDER" = "voicevox" ]; then
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  STEP 3: VOICEVOX セットアップ"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  VOICEVOX_INSTALLED=false
  VOICEVOX_RUNNING=false

  # 起動確認
  if curl -s --max-time 1 "$VOICEVOX_URL/version" > /dev/null 2>&1; then
    VOICEVOX_RUNNING=true
    VERSION=$(curl -s --max-time 1 "$VOICEVOX_URL/version" 2>/dev/null | tr -d '"')
    echo "  ✅ VOICEVOX v$VERSION が起動中です（セットアップ済み！）"
  # インストール確認
  elif [ -d "/Applications/VOICEVOX.app" ] || mdfind "kMDItemCFBundleIdentifier == 'jp.hiroshiba.voicevox'" 2>/dev/null | grep -q . 2>/dev/null; then
    VOICEVOX_INSTALLED=true
    echo "  ✅ VOICEVOX がインストール済みです（起動が必要）"
  else
    echo "  VOICEVOXがまだインストールされていません。"
    echo ""
    echo "  VOICEVOXとは？"
    echo "  → 無料の音声合成ソフトです"
    echo "  → ずんだもん、春日部つむぎなど100以上のキャラの声で喋れます"
    echo "  → インストールして起動するだけ。APIキーや登録は一切不要"
    echo ""
    echo "  1) 自動ダウンロード＆インストール（約1.8GB・数分かかります）"
    echo "  2) 公式サイトを開いて自分でダウンロード"
    echo ""
    read -p "  選択 [1]: " INSTALL_CHOICE
    INSTALL_CHOICE="${INSTALL_CHOICE:-1}"

    case "$INSTALL_CHOICE" in
      1)
        echo ""
        echo "  📦 ダウンロード中... (約1.8GB)"
        ARCH=$(uname -m)
        if [ "$ARCH" = "arm64" ]; then
          ZIP_NAME="voicevox-macos-cpu-arm64"
        else
          ZIP_NAME="voicevox-macos-cpu-x64"
        fi
        LATEST_TAG=$(curl -sL "https://api.github.com/repos/VOICEVOX/voicevox/releases/latest" | python3 -c "import json,sys; print(json.load(sys.stdin)['tag_name'])" 2>/dev/null || echo "0.25.1")
        DL_URL="https://github.com/VOICEVOX/voicevox/releases/download/${LATEST_TAG}/${ZIP_NAME}-${LATEST_TAG}.zip"

        curl -L --progress-bar -o /tmp/voicevox-macos.zip "$DL_URL"
        if [ $? -eq 0 ]; then
          echo "  📂 展開中..."
          unzip -o -q /tmp/voicevox-macos.zip -d /tmp/voicevox-extract
          cp -R /tmp/voicevox-extract/VOICEVOX/VOICEVOX.app /Applications/
          rm -rf /tmp/voicevox-macos.zip /tmp/voicevox-extract
          VOICEVOX_INSTALLED=true
          echo "  ✅ インストール完了！"
        else
          echo "  ❌ ダウンロード失敗。公式サイトからどうぞ: https://voicevox.hiroshiba.jp/"
        fi
        ;;
      2)
        open "https://voicevox.hiroshiba.jp/" 2>/dev/null || xdg-open "https://voicevox.hiroshiba.jp/" 2>/dev/null || true
        echo "  インストール後、再度 ./setup.sh を実行してください"
        exit 0
        ;;
    esac
  fi

  # 起動
  if [ "$VOICEVOX_INSTALLED" = true ] && [ "$VOICEVOX_RUNNING" = false ]; then
    echo ""
    echo "  🚀 VOICEVOXを起動しています..."
    open -a VOICEVOX 2>/dev/null || true
    for i in $(seq 1 25); do
      if curl -s --max-time 1 "$VOICEVOX_URL/version" > /dev/null 2>&1; then
        VOICEVOX_RUNNING=true
        echo "  ✅ VOICEVOX 起動完了！"
        break
      fi
      printf "  起動中... (%d秒)\r" $((i*2))
      sleep 2
    done
    echo ""
    if [ "$VOICEVOX_RUNNING" = false ]; then
      echo "  ⚠️  起動に時間がかかっています。手動でVOICEVOXアプリを起動してください。"
    fi
  fi

  "$NOTIFY_SCRIPT" set-provider voicevox 2>/dev/null || true
fi

# ============================================
# STEP 4: npm build
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  STEP 4: ビルド"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
cd "$SCRIPT_DIR"
if [ ! -d "node_modules" ]; then
  echo "  📦 パッケージをインストール中..."
  npm install --silent
fi
npm run build --silent
echo "  ✅ ビルド完了"

# ============================================
# STEP 5: キャラクター選択（VOICEVOX時のみ）
# ============================================
if [ "$SELECTED_PROVIDER" = "voicevox" ] && [ "$VOICEVOX_RUNNING" = true ]; then
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  STEP 5: キャラクターを選ぶ 🎤"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "  VOICEVOXのキャラクターを選んでください。"
  echo "  （後から ./notify.sh set-speaker <ID> で変更できます）"
  echo ""

  curl -s "$VOICEVOX_URL/speakers" 2>/dev/null | python3 -c "
import json, sys
speakers = json.load(sys.stdin)

# 人気キャラをグループ表示
groups = {
    'ずんだもん': [],
    '四国めたん': [],
    'その他（人気）': [],
}

popular_other = [8, 10, 9, 13, 14, 20, 46, 107, 108, 109]

for s in speakers:
    for st in s['styles']:
        entry = f'    {st[\"id\"]:3d}: {s[\"name\"]}（{st[\"name\"]}）'
        if 'ずんだもん' in s['name']:
            groups['ずんだもん'].append(entry)
        elif '四国めたん' in s['name']:
            groups['四国めたん'].append(entry)
        elif st['id'] in popular_other:
            groups['その他（人気）'].append(entry)

for group, entries in groups.items():
    print(f'  【{group}】')
    for e in entries[:6]:
        print(e)
    if len(entries) > 6:
        print(f'    ... 他 {len(entries)-6} スタイル')
    print()

total = sum(len(s['styles']) for s in speakers)
print(f'  全{total}キャラの一覧: ./notify.sh list')
" 2>/dev/null || true

  echo ""
  echo "  💡 おすすめ: 3（ずんだもん ノーマル）"
  echo ""
  read -p "  スピーカーID [3]: " SELECTED_SPEAKER
  SELECTED_SPEAKER="${SELECTED_SPEAKER:-3}"
  "$NOTIFY_SCRIPT" set-speaker "$SELECTED_SPEAKER"

  # 選んだキャラで試し聞き
  echo ""
  echo "  🔊 選んだキャラクターの声をテストします..."
  "$NOTIFY_SCRIPT" "こんにちは！これから音声通知でお知らせするね！" complete
  echo ""
  read -p "  この声でOKですか？ [Y/n]: " VOICE_OK
  if [ "$VOICE_OK" = "n" ] || [ "$VOICE_OK" = "N" ]; then
    echo "  → ./notify.sh list で一覧を確認して"
    echo "    ./notify.sh set-speaker <ID> で変更してください"
  else
    echo "  ✅ キャラクター設定完了！"
  fi
fi

# ============================================
# STEP 6: Claude Code 設定ガイド
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  STEP 6: Claude Code との連携"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

CLAUDE_SETTINGS="$HOME/.claude/settings.json"
if [ -f "$CLAUDE_SETTINGS" ] && grep -q "voice-notify" "$CLAUDE_SETTINGS" 2>/dev/null; then
  echo "  ✅ Claude Code Hooks は設定済みです"
else
  echo "  Claude Code と連携するには、以下を設定ファイルに追加してください："
  echo ""
  echo "  ファイル: $CLAUDE_SETTINGS"
  echo "  hooks セクションに追加："
  echo ""
  echo "    \"Notification\": ["
  echo "      {"
  echo "        \"matcher\": \"\","
  echo "        \"hooks\": ["
  echo "          {"
  echo "            \"type\": \"command\","
  echo "            \"command\": \"$NOTIFY_SCRIPT '確認をお願いします' confirm\""
  echo "          }"
  echo "        ]"
  echo "      }"
  echo "    ]"
  echo ""
  echo "  また、プロジェクトのCLAUDE.mdに templates/CLAUDE.md の内容を"
  echo "  コピーすると、Claudeが自動的に音声で報告するようになります。"
fi

# ============================================
# 完了
# ============================================
echo ""
echo ""
echo "  ╔══════════════════════════════════════════════╗"
echo "  ║         ⭐ セットアップ完了！                 ║"
echo "  ╚══════════════════════════════════════════════╝"
echo ""
echo "  使い方:"
echo "  ────────────────────────────────────────────"
echo "  ./notify.sh \"メッセージ\"       → 声で読み上げ"
echo "  ./notify.sh list               → キャラ一覧"
echo "  ./notify.sh set-speaker <ID>   → キャラ変更"
echo "  ./notify.sh off                → 音声OFF（会議中に便利）"
echo "  ./notify.sh on                 → 音声ON"
echo "  ./notify.sh set-provider google→ Google TTSに切り替え"
echo "  ────────────────────────────────────────────"
echo ""
echo "  お楽しみください！ 🎉"
echo ""
