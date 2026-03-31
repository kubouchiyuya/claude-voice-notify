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
echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ようこそ！クローンしてくださってありがとうございます。"
echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  このツールをダウンロード（クローン）してくださって"
echo "  ありがとうございます！"
echo "  もし便利だと思ったら、ぜひ GitHub でスターを押してください。"
echo "  あなたのスターが開発の励みになります！"
echo ""
echo "  このツールには、エンジニア以外の方向けに、"
echo "  専門用語をわかりやすく説明する機能が入っています。"
echo "  必要なければ、いつでもオフにできますので、"
echo "  まずはそのままお使いください。"
echo ""
echo "  ★ VS Code 拡張機能について:"
echo "    このリポジトリには VS Code 拡張機能が含まれています。"
echo "    セットアップが完了すると、VS Code からも音声を"
echo "    ON/OFF できるようになります。"
echo "    オンライン会議中は設定パネル（./settings.sh）から"
echo "    「音声 OFF」に設定できます。"
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
echo "  ※ 基本設計は VOICEVOX（無料）です。迷ったら 1 を選んでください。"
echo ""
echo "  ┌──┬───────────────────┬──────────────┬───────────────────────────────┐"
echo "  │# │ エンジン名        │ 料金         │ 特徴                          │"
echo "  ├──┼───────────────────┼──────────────┼───────────────────────────────┤"
echo "  │  │【無料エンジン】    │              │                               │"
echo "  ├──┼───────────────────┼──────────────┼───────────────────────────────┤"
echo "  │1 │ VOICEVOX          │ 完全無料     │ ★おすすめ★                   │"
echo "  │  │ ボイスボックス     │ APIキー不要  │ ずんだもん等 100+キャラ        │"
echo "  │  │                   │              │ インストールするだけで使える    │"
echo "  ├──┼───────────────────┼──────────────┼───────────────────────────────┤"
echo "  │2 │ COEIROINK         │ 完全無料     │ つくよみちゃん等               │"
echo "  │  │ コエイロインク     │ APIキー不要  │ VOICEVOX互換API               │"
echo "  ├──┼───────────────────┼──────────────┼───────────────────────────────┤"
echo "  │3 │ AivisSpeech       │ 完全無料     │ 高品質ローカルTTS             │"
echo "  │  │ アイビススピーチ   │ APIキー不要  │ VOICEVOX互換・高音質          │"
echo "  ├──┼───────────────────┼──────────────┼───────────────────────────────┤"
echo "  │4 │ Style-Bert-VITS2  │ 完全無料     │ 自分の声を学習して使える       │"
echo "  │  │ スタイルバートビッツ│ APIキー不要  │ 好きなキャラの声も学習可能     │"
echo "  │  │ ツー              │              │ Udemy動画の声をそのまま使える  │"
echo "  ├──┼───────────────────┼──────────────┼───────────────────────────────┤"
echo "  │  │【有料エンジン】    │              │                               │"
echo "  ├──┼───────────────────┼──────────────┼───────────────────────────────┤"
echo "  │5 │ Google Cloud TTS  │ 無料枠あり   │ 月100万文字まで無料            │"
echo "  │  │ グーグルクラウド   │ 超過: \$4/100万│ Neural2: 超高品質・自然な声    │"
echo "  │  │ ティーティーエス   │ 文字         │ Google APIキーが必要           │"
echo "  ├──┼───────────────────┼──────────────┼───────────────────────────────┤"
echo "  │6 │ Fish Audio        │ 従量課金     │ リアルタイム音声クローン       │"
echo "  │  │ フィッシュオーディオ│ \$0.01/100文字│ 多言語対応・カスタムボイス     │"
echo "  ├──┼───────────────────┼──────────────┼───────────────────────────────┤"
echo "  │7 │ ElevenLabs        │ 無料枠あり   │ 英語音声は業界最高品質         │"
echo "  │  │ イレブンラボ       │ 月\$5〜       │ 日本語も対応・感情表現が豊か   │"
echo "  ├──┼───────────────────┼──────────────┼───────────────────────────────┤"
echo "  │8 │ OpenAI TTS        │ 従量課金     │ nova/alloy/echo等6種の声      │"
echo "  │  │ オープンエーアイ   │ \$15/100万文字│ ChatGPTと同じ音声技術         │"
echo "  │  │ ティーティーエス   │              │ OpenAI APIキーが必要           │"
echo "  └──┴───────────────────┴──────────────┴───────────────────────────────┘"
echo ""
echo "  💡 一番簡単なのは 1 の VOICEVOX です。"
echo "     ずんだもんや春日部つむぎなどの声をすぐに使えます。"
echo "     有料課金しているサービスがあれば、そちらも選べます。"
echo ""
read -p "  番号を選択 [1]: " ENGINE_CHOICE
ENGINE_CHOICE="${ENGINE_CHOICE:-1}"

case "$ENGINE_CHOICE" in
  1)
    SELECTED_PROVIDER="voicevox"
    echo "  ✅ VOICEVOX を選択しました"
    ;;
  2)
    SELECTED_PROVIDER="coeiroink"
    echo "  ✅ COEIROINK を選択しました"
    echo "  ※ COEIROINKアプリの起動が必要です: https://coeiroink.com/"
    "$NOTIFY_SCRIPT" set-provider coeiroink 2>/dev/null || true
    ;;
  3)
    SELECTED_PROVIDER="aivis_speech"
    echo "  ✅ AivisSpeech を選択しました"
    echo "  ※ AivisSpeechアプリの起動が必要です: https://aivis-project.com/"
    "$NOTIFY_SCRIPT" set-provider aivis_speech 2>/dev/null || true
    ;;
  4)
    SELECTED_PROVIDER="style_bert_vits2"
    echo "  ✅ Style-Bert-VITS2 を選択しました"
    echo "  ※ サーバーの起動が必要です: https://github.com/litagin02/Style-Bert-VITS2"
    read -p "  モデル名 [default]: " SBV2_MODEL
    SBV2_MODEL="${SBV2_MODEL:-default}"
    "$NOTIFY_SCRIPT" set-provider style_bert_vits2 2>/dev/null || true
    ;;
  5)
    SELECTED_PROVIDER="google"
    echo "  ✅ Google Cloud TTS を選択しました"
    echo ""
    echo "  APIキーの取得方法:"
    echo "  1. https://console.cloud.google.com にアクセス"
    echo "  2. 「Text-to-Speech API」を有効化"
    echo "  3. 「認証情報」→「APIキーを作成」"
    echo ""
    read -p "  Google TTS APIキー (後で設定する場合は空Enter): " GOOGLE_KEY
    if [ -n "$GOOGLE_KEY" ]; then
      "$NOTIFY_SCRIPT" set-google-key "$GOOGLE_KEY"
    else
      echo "  → 後で: ./notify.sh set-google-key <KEY>"
    fi
    "$NOTIFY_SCRIPT" set-provider google 2>/dev/null || true
    ;;
  6)
    SELECTED_PROVIDER="fish_audio"
    echo "  ✅ Fish Audio を選択しました"
    read -p "  Fish Audio APIキー: " FA_KEY
    if [ -n "$FA_KEY" ]; then
      grep -v "^FISH_AUDIO_API_KEY=" "$CONFIG_FILE" > "$CONFIG_FILE.tmp" 2>/dev/null || true
      mv "$CONFIG_FILE.tmp" "$CONFIG_FILE" 2>/dev/null || true
      echo "FISH_AUDIO_API_KEY=$FA_KEY" >> "$CONFIG_FILE"
    fi
    read -p "  Voice ID: " FA_VOICE
    if [ -n "$FA_VOICE" ]; then
      grep -v "^FISH_AUDIO_VOICE_ID=" "$CONFIG_FILE" > "$CONFIG_FILE.tmp" 2>/dev/null || true
      mv "$CONFIG_FILE.tmp" "$CONFIG_FILE" 2>/dev/null || true
      echo "FISH_AUDIO_VOICE_ID=$FA_VOICE" >> "$CONFIG_FILE"
    fi
    "$NOTIFY_SCRIPT" set-provider fish_audio 2>/dev/null || true
    ;;
  7)
    SELECTED_PROVIDER="elevenlabs"
    echo "  ✅ ElevenLabs を選択しました"
    read -p "  ElevenLabs APIキー: " EL_KEY
    if [ -n "$EL_KEY" ]; then
      grep -v "^ELEVENLABS_API_KEY=" "$CONFIG_FILE" > "$CONFIG_FILE.tmp" 2>/dev/null || true
      mv "$CONFIG_FILE.tmp" "$CONFIG_FILE" 2>/dev/null || true
      echo "ELEVENLABS_API_KEY=$EL_KEY" >> "$CONFIG_FILE"
    fi
    "$NOTIFY_SCRIPT" set-provider elevenlabs 2>/dev/null || true
    ;;
  8)
    SELECTED_PROVIDER="openai"
    echo "  ✅ OpenAI TTS を選択しました"
    read -p "  OpenAI APIキー: " OA_KEY
    if [ -n "$OA_KEY" ]; then
      grep -v "^OPENAI_API_KEY=" "$CONFIG_FILE" > "$CONFIG_FILE.tmp" 2>/dev/null || true
      mv "$CONFIG_FILE.tmp" "$CONFIG_FILE" 2>/dev/null || true
      echo "OPENAI_API_KEY=$OA_KEY" >> "$CONFIG_FILE"
    fi
    echo ""
    echo "  音声: nova(女性) / alloy(中性) / echo(男性) / fable / onyx / shimmer"
    read -p "  音声名 [nova]: " OA_VOICE
    OA_VOICE="${OA_VOICE:-nova}"
    grep -v "^OPENAI_TTS_VOICE=" "$CONFIG_FILE" > "$CONFIG_FILE.tmp" 2>/dev/null || true
    mv "$CONFIG_FILE.tmp" "$CONFIG_FILE" 2>/dev/null || true
    echo "OPENAI_TTS_VOICE=$OA_VOICE" >> "$CONFIG_FILE"
    "$NOTIFY_SCRIPT" set-provider openai 2>/dev/null || true
    ;;
  *)
    SELECTED_PROVIDER="voicevox"
    echo "  ✅ デフォルト: VOICEVOX を選択しました"
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
# STEP 5: VS Code 拡張機能インストール
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  STEP 5: VS Code 拡張機能"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

VSCODE_EXT_DIR="$SCRIPT_DIR/vscode-extension"
VSCODE_EXT_INSTALLED=false

# VS Code の code コマンドを探す
VSCODE_CMD=""
if command -v code > /dev/null 2>&1; then
  VSCODE_CMD="code"
elif [ -f "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ]; then
  VSCODE_CMD="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
elif [ -f "$HOME/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ]; then
  VSCODE_CMD="$HOME/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
elif command -v cursor > /dev/null 2>&1; then
  VSCODE_CMD="cursor"
fi

if [ -n "$VSCODE_CMD" ] && [ -d "$VSCODE_EXT_DIR" ]; then
  echo "  ✅ VS Code を検出しました"
  echo "  📦 拡張機能をビルド中..."

  # 依存関係インストール
  if [ ! -d "$VSCODE_EXT_DIR/node_modules/@types/vscode" ]; then
    (cd "$VSCODE_EXT_DIR" && npm install --silent 2>/dev/null)
  fi

  # TypeScript コンパイル
  (cd "$VSCODE_EXT_DIR" && npm run compile --silent 2>/dev/null)

  if [ -f "$VSCODE_EXT_DIR/out/extension.js" ]; then
    # VSIX パッケージ作成
    VSIX_FILE="$VSCODE_EXT_DIR/claude-voice-notify-panel-1.0.0.vsix"

    if command -v vsce > /dev/null 2>&1; then
      (cd "$VSCODE_EXT_DIR" && vsce package --allow-missing-repository -o "$VSIX_FILE" 2>/dev/null)
    elif command -v npx > /dev/null 2>&1; then
      (cd "$VSCODE_EXT_DIR" && npx --yes @vscode/vsce package --allow-missing-repository -o "$VSIX_FILE" 2>/dev/null)
    fi

    if [ -f "$VSIX_FILE" ]; then
      echo "  📦 拡張機能をインストール中..."
      "$VSCODE_CMD" --install-extension "$VSIX_FILE" --force 2>/dev/null
      if [ $? -eq 0 ]; then
        VSCODE_EXT_INSTALLED=true
        echo "  ✅ VS Code 拡張機能インストール完了！"
        echo "     ステータスバーに 🔊 Voice ON / ⚙️ VB設定 が表示されます"
        echo "     ※ VS Code のリロードが必要な場合: Cmd+Shift+P → Reload Window"
      else
        echo "  ⚠️  拡張機能のインストールに失敗しました"
        echo "     手動: $VSCODE_CMD --install-extension $VSIX_FILE"
      fi
    else
      echo "  ⚠️  VSIXパッケージの作成に失敗しました"
      echo "     vsce がインストールされていない可能性があります"
      echo "     → npm install -g @vscode/vsce してから再実行してください"
    fi
  else
    echo "  ⚠️  TypeScript コンパイルに失敗しました"
  fi
else
  if [ -z "$VSCODE_CMD" ]; then
    echo "  ⏭️  VS Code が見つかりません（スキップ）"
    echo "     後からインストールする場合:"
    echo "     cd vscode-extension && npm install && npm run compile"
    echo "     vsce package --allow-missing-repository"
    echo "     code --install-extension claude-voice-notify-panel-1.0.0.vsix"
  else
    echo "  ⏭️  vscode-extension ディレクトリが見つかりません（スキップ）"
  fi
fi

# ============================================
# STEP 6: キャラクター選択（VOICEVOX時のみ）
# ============================================
if [ "$SELECTED_PROVIDER" = "voicevox" ] && [ "$VOICEVOX_RUNNING" = true ]; then
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  STEP 6: キャラクターを選ぶ 🎤"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "  まず、どんな声がいいか教えてください。"
  echo ""
  echo "  【性別で選ぶ】"
  echo "    1) 女性キャラクター"
  echo "    2) 男性キャラクター"
  echo "    3) 全て表示"
  echo ""
  read -p "  選択 [1]: " GENDER_CHOICE
  GENDER_CHOICE="${GENDER_CHOICE:-1}"

  echo ""
  echo "  【性格・雰囲気で選ぶ】"
  echo "    1) やさしい・初心者にわかりやすい（あまあま・ノーマル）"
  echo "    2) 元気・明るい（ノーマル・うきうき・元気）"
  echo "    3) クール・かっこいい（ツンツン・クイーン・シリアス）"
  echo "    4) かわいい・癒し系（ささやき・ヒソヒソ・あまあま）"
  echo "    5) 全スタイル表示"
  echo ""
  read -p "  選択 [1]: " PERSONALITY_CHOICE
  PERSONALITY_CHOICE="${PERSONALITY_CHOICE:-1}"

  # Pythonでフィルタリング表示
  curl -s "$VOICEVOX_URL/speakers" 2>/dev/null | python3 -c "
import json, sys

speakers = json.load(sys.stdin)
gender = '$GENDER_CHOICE'
personality = '$PERSONALITY_CHOICE'

# キャラの性別データ
female_chars = [
    'ずんだもん', '四国めたん', '春日部つむぎ', '雨晴はう', '波音リツ',
    '冥鳴ひまり', '九州そら', 'もち子さん', 'WhiteCUL', '櫻歌ミコ',
    '小夜/SAYO', '春歌ナナ', '猫使アル', '猫使ビィ', '中国うさぎ',
    '栗田まろん', 'あいえるたん', '満別花丸', '琴詠ニア', 'ぞん子',
    'ユーレイちゃん', '東北ずん子', '東北きりたん', '東北イタコ',
    'あんこもん', 'ナースロボ＿タイプＴ', 'No.7', '黒沢冴白',
]
male_chars = [
    '玄野武宏', '白上虎太郎', '青山龍星', '剣崎雌雄',
    '後鬼', 'ちび式じい', '雀松朱司', '麒ヶ島宗麟',
    '†聖騎士 紅桜†', '中部つるぎ', '離途', 'Voidoll',
]

# 性格フィルタ
gentle_styles = ['ノーマル', 'あまあま', 'ふつう', '読み聞かせ', 'のんびり', '甘々', 'おちつき']
energetic_styles = ['ノーマル', 'ふつう', 'うきうき', '元気', 'わーい', '熱血', '喜び', '覚醒', 'つよつよ']
cool_styles = ['ツンツン', 'クイーン', 'シリアス', 'ツンギレ', '不機嫌', 'セクシー', '実況風', 'アナウンス']
cute_styles = ['ささやき', 'ヒソヒソ', 'あまあま', '甘々', 'ロリ', 'びくびく', '人見知り', '内緒話', 'よわよわ', 'へろへろ']

style_filter = None
if personality == '1': style_filter = gentle_styles
elif personality == '2': style_filter = energetic_styles
elif personality == '3': style_filter = cool_styles
elif personality == '4': style_filter = cute_styles

results = []
for s in speakers:
    # 性別フィルタ
    if gender == '1' and s['name'] not in female_chars: continue
    if gender == '2' and s['name'] not in male_chars: continue

    for st in s['styles']:
        # 性格フィルタ
        if style_filter and st['name'] not in style_filter: continue
        results.append((st['id'], s['name'], st['name']))

if not results:
    print('  該当するキャラクターがありません。全て表示します。')
    for s in speakers:
        for st in s['styles']:
            results.append((st['id'], s['name'], st['name']))

# 性格の日本語説明
personality_desc = {
    'ノーマル': '標準', 'あまあま': 'やさしい', 'ツンツン': 'クール',
    'セクシー': '大人っぽい', 'ささやき': '囁き声', 'ヒソヒソ': '小声',
    'ヘロヘロ': '疲れ気味', 'なみだめ': '泣きそう', 'ふつう': '標準',
    'わーい': '喜び', 'びくびく': '怖がり', 'おこ': '怒り',
    'びえーん': '泣き', '熱血': '情熱的', '不機嫌': '不機嫌',
    '喜び': '嬉しい', 'しっとり': '落ち着き', 'かなしい': '悲しい',
    'かなしみ': '悲しい', '囁き': '囁き声', 'たのしい': '楽しい',
    'クイーン': '威厳', 'ロリ': 'かわいい', 'アナウンス': '丁寧',
    '読み聞かせ': 'やさしい', '楽々': 'リラックス', '恐怖': '怖い',
    '内緒話': 'ひそひそ', 'おちつき': '落ち着き', 'うきうき': 'ワクワク',
    'つよつよ': '力強い', 'へろへろ': 'ゆるい', '人見知り': 'おとなしい',
    'おどろき': 'びっくり', 'こわがり': '怖がり', '元気': '元気',
    'ぶりっ子': 'かわいこぶり', 'ボーイ': 'ボーイッシュ',
    'のんびり': 'のんびり', '泣き': '泣き', '怒り': '怒り',
    'シリアス': '真剣', '実況風': 'テンション高い', '覚醒': '覚醒',
    '低血圧': 'けだるい', 'おどおど': 'おどおど', '絶望と敗北': '絶望',
    '第二形態': '強気', 'セクシー／あん子': '大人っぽい',
    '甘々': 'やさしい', '哀しみ': '悲しい', 'ツクモちゃん': '元気',
    'よわよわ': '弱々しい', 'けだるげ': 'だるそう',
    '鬼ver.': '力強い', 'ぬいぐるみver.': 'かわいい',
    '人間ver.': '標準', '人間（怒り）ver.': '怒り',
    'ツンギレ': 'ツンデレ', '悲しみ': '悲しい',
}

print(f'  該当: {len(results)}件')
print()
for sid, name, style in results[:30]:
    desc = personality_desc.get(style, '')
    desc_str = f' [{desc}]' if desc else ''
    print(f'    {sid:3d}: {name}（{style}）{desc_str}')

if len(results) > 30:
    print(f'    ... 他 {len(results)-30} 件（./notify.sh list で全表示）')
print()
" 2>/dev/null || true

  echo "  💡 おすすめ:"
  echo "    3: ずんだもん（ノーマル）  [初心者向け・やさしい]"
  echo "    1: ずんだもん（あまあま）  [とてもやさしい]"
  echo "    8: 春日部つむぎ（ノーマル）[元気・明るい]"
  echo ""
  read -p "  スピーカーID [3]: " SELECTED_SPEAKER
  SELECTED_SPEAKER="${SELECTED_SPEAKER:-3}"
  "$NOTIFY_SCRIPT" set-speaker "$SELECTED_SPEAKER"

  # 試し聞き
  echo ""
  echo "  🔊 声をテストします..."
  "$NOTIFY_SCRIPT" "こんにちは！これから音声通知でお知らせするね！よろしくね！" complete
  echo ""
  read -p "  この声でOKですか？ [Y/n]: " VOICE_OK
  if [ "$VOICE_OK" = "n" ] || [ "$VOICE_OK" = "N" ]; then
    echo ""
    echo "  別のIDで試してみましょう。"
    read -p "  スピーカーID: " RETRY_SPEAKER
    if [ -n "$RETRY_SPEAKER" ]; then
      "$NOTIFY_SCRIPT" set-speaker "$RETRY_SPEAKER"
      "$NOTIFY_SCRIPT" "この声はどうかな？気に入ってもらえると嬉しいな！" complete
      read -p "  OKですか？ [Y/n]: " VOICE_OK2
      if [ "$VOICE_OK2" = "n" ] || [ "$VOICE_OK2" = "N" ]; then
        echo "  → 後から ./notify.sh set-speaker <ID> で変更してください"
      fi
    fi
  fi
  echo "  ✅ キャラクター設定完了！"
fi

# ============================================
# STEP 6.5: デフォルト設定の書き込み
# ============================================
if [ ! -f "$CONFIG_FILE" ]; then
  touch "$CONFIG_FILE"
  chmod 600 "$CONFIG_FILE"
fi
# VOICE_LANG がなければ追加
if ! grep -q "^VOICE_LANG=" "$CONFIG_FILE" 2>/dev/null; then
  echo "VOICE_LANG=ja" >> "$CONFIG_FILE"
fi
# TERM_EXPLAIN がなければ追加
if ! grep -q "^TERM_EXPLAIN=" "$CONFIG_FILE" 2>/dev/null; then
  echo "TERM_EXPLAIN=on" >> "$CONFIG_FILE"
fi
# VOICE_ENABLED がなければ追加
if ! grep -q "^VOICE_ENABLED=" "$CONFIG_FILE" 2>/dev/null; then
  echo "VOICE_ENABLED=on" >> "$CONFIG_FILE"
fi

# ============================================
# STEP 7: Claude Code 設定ガイド
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  STEP 7: Claude Code との連携"
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
if [ "$VSCODE_EXT_INSTALLED" = true ]; then
  echo ""
  echo "  VS Code 拡張機能:"
  echo "  ────────────────────────────────────────────"
  echo "  ステータスバー 🔊 Voice ON    → クリックで ON/OFF"
  echo "  ステータスバー ⚙️ VB設定      → 設定パネルを開く"
  echo "  Cmd+Shift+P → Claude Voice   → 全コマンド表示"
  echo "  ────────────────────────────────────────────"
fi
echo ""
echo "  お楽しみください！ 🎉"
echo ""
