import * as vscode from 'vscode';
import { execSync, exec } from 'child_process';
import { existsSync, readFileSync } from 'fs';
import { homedir } from 'os';
import { join } from 'path';

const NOTIFY_DIR = join(homedir(), 'Projects', 'claude-voice-notify');
const NOTIFY_SH = join(NOTIFY_DIR, 'notify.sh');
const STATE_FILE = join(NOTIFY_DIR, '.voice-enabled');
const CONFIG_FILE = join(NOTIFY_DIR, '.voice-config');

let statusBarToggle: vscode.StatusBarItem;
let statusBarSettings: vscode.StatusBarItem;

export function activate(context: vscode.ExtensionContext) {

  // ── ステータスバー: ON/OFF トグル ──
  statusBarToggle = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Left, 100);
  statusBarToggle.command = 'claude-voice.toggleOnOff';
  statusBarToggle.tooltip = 'クリックで音声通知の ON/OFF を切り替え';
  updateToggleStatus();
  statusBarToggle.show();

  // ── ステータスバー: 設定ボタン ──
  statusBarSettings = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Left, 99);
  statusBarSettings.text = '$(gear) VB設定';
  statusBarSettings.command = 'claude-voice.openSettings';
  statusBarSettings.tooltip = 'VOICEVOX 音声通知の設定を開く';
  statusBarSettings.show();

  // ── コマンド登録 ──

  // ON/OFF 切り替え
  context.subscriptions.push(
    vscode.commands.registerCommand('claude-voice.toggleOnOff', () => {
      const isOff = isVoiceOff();
      runNotify(isOff ? 'on' : 'off');
      updateToggleStatus();
      vscode.window.showInformationMessage(
        `音声通知: ${isOff ? '🔊 ON' : '🔇 OFF'}`
      );
    })
  );

  // 設定パネル（クイックピック）
  context.subscriptions.push(
    vscode.commands.registerCommand('claude-voice.openSettings', async () => {
      const charName = getCharacterName();
      const speed = getConfigValue('DEFAULT_SPEED', '1.0');
      const provider = getConfigValue('DEFAULT_PROVIDER', 'voicevox');
      const voiceState = isVoiceOff() ? '🔇 OFF' : '🔊 ON';

      const volume = getConfigValue('DEFAULT_VOLUME', '1.0');

      const items: vscode.QuickPickItem[] = [
        { label: `${voiceState}`, description: 'クリックで切り替え', detail: '音声通知の ON/OFF' },
        { label: '$(separator)', kind: vscode.QuickPickItemKind.Separator } as any,
        { label: `🎤 キャラ: ${charName}`, description: 'キャラクター変更', detail: 'VOICEVOX のキャラクターを変更' },
        { label: `⏩ 速度: ${speed}x`, description: '速度調整', detail: '読み上げ速度を変更' },
        { label: `🔉 音量: ${volume}`, description: '音量調整', detail: '読み上げ音量を変更 (0.0〜1.0)' },
        { label: `🗾 方言で選ぶ`, description: '方言・地域選択', detail: '東北弁・九州弁などから選ぶ' },
        { label: `🔧 エンジン: ${provider}`, description: 'エンジン変更', detail: '音声エンジンを切り替え' },
        { label: '$(separator)', kind: vscode.QuickPickItemKind.Separator } as any,
        { label: '🔊 テスト再生', description: '現在の設定でテスト', detail: '' },
      ];

      const selected = await vscode.window.showQuickPick(items, {
        title: '⚙️ VB 設定パネル',
        placeHolder: '設定を選択してください',
      });

      if (!selected) return;

      if (selected.label.includes('OFF') || selected.label.includes('ON')) {
        vscode.commands.executeCommand('claude-voice.toggleOnOff');
      } else if (selected.label.includes('キャラ')) {
        vscode.commands.executeCommand('claude-voice.selectCharacter');
      } else if (selected.label.includes('速度')) {
        vscode.commands.executeCommand('claude-voice.adjustSpeed');
      } else if (selected.label.includes('音量')) {
        vscode.commands.executeCommand('claude-voice.adjustVolume');
      } else if (selected.label.includes('方言')) {
        selectDialect();
      } else if (selected.label.includes('エンジン')) {
        selectEngine();
      } else if (selected.label.includes('テスト')) {
        vscode.commands.executeCommand('claude-voice.testPlay');
      }
    })
  );

  // キャラクター選択
  context.subscriptions.push(
    vscode.commands.registerCommand('claude-voice.selectCharacter', async () => {
      const speakers = getSpeakers();
      if (!speakers.length) {
        vscode.window.showErrorMessage('VOICEVOX に接続できません。起動してください。');
        return;
      }

      const items = speakers.map(s => ({
        label: `${s.id}: ${s.name}（${s.style}）`,
        description: s.gender,
        detail: s.personality,
        id: s.id,
      }));

      const selected = await vscode.window.showQuickPick(items, {
        title: '🎤 キャラクター選択',
        placeHolder: '検索: ずんだもん、つむぎ、男性、やさしい...',
        matchOnDescription: true,
        matchOnDetail: true,
      });

      if (selected) {
        runNotify(`set-speaker ${(selected as any).id}`);
        updateToggleStatus();
        runNotifyAsync(`"キャラクターを変更しました！" complete`);
        vscode.window.showInformationMessage(`キャラ変更: ${selected.label}`);
      }
    })
  );

  // 速度調整
  context.subscriptions.push(
    vscode.commands.registerCommand('claude-voice.adjustSpeed', async () => {
      const currentSpeed = getConfigValue('DEFAULT_SPEED', '1.0');
      const speeds = ['0.5', '0.7', '0.8', '0.9', '1.0', '1.1', '1.2', '1.3', '1.5', '1.8', '2.0'];

      const items = speeds.map(s => {
        const bar = '█'.repeat(Math.round((parseFloat(s) - 0.5) / 1.5 * 20));
        const empty = '░'.repeat(20 - bar.length);
        const marker = s === currentSpeed ? ' ← 現在' : '';
        return {
          label: `${s}x  ${bar}${empty}${marker}`,
          speed: s,
        };
      });

      const selected = await vscode.window.showQuickPick(items, {
        title: '⏩ 速度調整',
        placeHolder: `現在: ${currentSpeed}x`,
      });

      if (selected) {
        runNotify(`set-speed ${(selected as any).speed}`);
        runNotifyAsync(`"この速度はどうですか？" complete`);
        vscode.window.showInformationMessage(`速度変更: ${(selected as any).speed}x`);
      }
    })
  );

  // 音量調整
  context.subscriptions.push(
    vscode.commands.registerCommand('claude-voice.adjustVolume', async () => {
      const currentVolume = getConfigValue('DEFAULT_VOLUME', '1.0');
      const volumes = ['0.0', '0.1', '0.2', '0.3', '0.4', '0.5', '0.6', '0.7', '0.8', '0.9', '1.0'];

      const items = volumes.map(v => {
        const filled = Math.round(parseFloat(v) * 20);
        const bar = '█'.repeat(filled);
        const empty = '░'.repeat(20 - filled);
        const marker = v === currentVolume ? ' ← 現在' : '';
        return {
          label: `${v}  ${bar}${empty}${marker}`,
          volume: v,
        };
      });

      const selected = await vscode.window.showQuickPick(items, {
        title: '🔉 音量調整',
        placeHolder: `現在: ${currentVolume}`,
      });

      if (selected) {
        runNotify(`set-volume ${(selected as any).volume}`);
        runNotifyAsync(`"この音量はどうですか？" complete`);
        vscode.window.showInformationMessage(`音量変更: ${(selected as any).volume}`);
      }
    })
  );

  // テスト再生
  context.subscriptions.push(
    vscode.commands.registerCommand('claude-voice.testPlay', () => {
      runNotifyAsync(`"テスト再生です。この声とスピードで通知されます" complete`);
    })
  );

  // 定期的にステータスバーを更新
  setInterval(updateToggleStatus, 5000);

  context.subscriptions.push(statusBarToggle, statusBarSettings);
}

// ── ヘルパー関数 ──

function isVoiceOff(): boolean {
  try {
    if (existsSync(STATE_FILE)) {
      return readFileSync(STATE_FILE, 'utf8').trim() === '0';
    }
  } catch {}
  return false;
}

function updateToggleStatus() {
  if (isVoiceOff()) {
    statusBarToggle.text = '$(mute) Voice OFF';
    statusBarToggle.backgroundColor = new vscode.ThemeColor('statusBarItem.warningBackground');
  } else {
    statusBarToggle.text = '$(unmute) Voice ON';
    statusBarToggle.backgroundColor = undefined;
  }
}

function runNotify(args: string): string {
  try {
    return execSync(`${NOTIFY_SH} ${args}`, { encoding: 'utf8', timeout: 3000 });
  } catch {
    return '';
  }
}

function runNotifyAsync(args: string) {
  exec(`${NOTIFY_SH} ${args}`, { timeout: 30000 });
}

function getConfigValue(key: string, defaultValue: string): string {
  try {
    if (existsSync(CONFIG_FILE)) {
      const content = readFileSync(CONFIG_FILE, 'utf8');
      const match = content.match(new RegExp(`^${key}=(.+)$`, 'm'));
      if (match) return match[1];
    }
  } catch {}
  return defaultValue;
}

function getCharacterName(): string {
  const speakerId = getConfigValue('DEFAULT_SPEAKER', '3');
  const speakers = getSpeakers();
  const found = speakers.find(s => String(s.id) === speakerId);
  return found ? `${found.name}（${found.style}）` : `ID:${speakerId}`;
}

interface SpeakerInfo {
  id: number;
  name: string;
  style: string;
  gender: string;
  personality: string;
}

function getSpeakers(): SpeakerInfo[] {
  try {
    const result = execSync(
      `curl -s --max-time 2 http://localhost:50021/speakers`,
      { encoding: 'utf8', timeout: 5000 }
    );
    const speakers = JSON.parse(result);

    const femaleChars = new Set([
      'ずんだもん', '四国めたん', '春日部つむぎ', '雨晴はう', '波音リツ',
      '冥鳴ひまり', '九州そら', 'もち子さん', 'WhiteCUL', '櫻歌ミコ',
      '小夜/SAYO', '春歌ナナ', '猫使アル', '猫使ビィ', '中国うさぎ',
      '栗田まろん', 'あいえるたん', '満別花丸', '琴詠ニア', 'ぞん子',
      'ユーレイちゃん', '東北ずん子', '東北きりたん', '東北イタコ',
      'あんこもん', 'ナースロボ＿タイプＴ', 'No.7', '黒沢冴白',
    ]);

    const personalityMap: Record<string, string> = {
      'ノーマル': 'やさしい・標準', 'あまあま': 'とてもやさしい・甘い',
      'ツンツン': 'クール・ツンデレ', 'セクシー': '大人っぽい',
      'ささやき': '囁き・落ち着き', 'ヒソヒソ': '小声・ひそひそ',
      'ヘロヘロ': 'ゆるい・疲れ気味', 'なみだめ': '泣きそう・切ない',
      'ふつう': '標準・親しみやすい', 'わーい': '喜び・元気',
      'びくびく': '怖がり・おとなしい', 'おこ': '怒り・強め',
      'びえーん': '泣き・悲しい', '熱血': '情熱的・力強い',
      '不機嫌': '不機嫌・クール', '喜び': '嬉しい・明るい',
      'しっとり': '落ち着き・穏やか', 'かなしみ': '悲しい',
      '囁き': '囁き・やさしい', 'たのしい': '楽しい・明るい',
      'かなしい': '悲しい・切ない', 'クイーン': '威厳・かっこいい',
      'ロリ': 'かわいい', 'アナウンス': '丁寧・フォーマル',
      '読み聞かせ': 'やさしい・初心者向け', '楽々': 'リラックス',
      'おちつき': '落ち着き・穏やか', 'うきうき': 'ワクワク・元気',
      'つよつよ': '力強い・自信', 'へろへろ': 'ゆるい・脱力',
      '人見知り': 'おとなしい・控えめ', '元気': '元気・明るい',
      'のんびり': 'のんびり・リラックス', 'シリアス': '真剣・クール',
      '実況風': 'テンション高い', '覚醒': '覚醒・強い',
      '低血圧': 'けだるい・ゆるい', 'よわよわ': '弱々しい・かわいい',
      'けだるげ': 'だるそう・リラックス', '第二形態': '強気・かっこいい',
    };

    const results: SpeakerInfo[] = [];
    for (const s of speakers) {
      for (const st of s.styles) {
        results.push({
          id: st.id,
          name: s.name,
          style: st.name,
          gender: femaleChars.has(s.name) ? '♀ 女性' : '♂ 男性',
          personality: personalityMap[st.name] || st.name,
        });
      }
    }
    return results;
  } catch {
    return [];
  }
}

async function selectDialect() {
  const dialects = [
    { label: '🗾 東北弁', description: 'ずんだもん、東北ずん子、東北きりたん、東北イタコ、あんこもん', chars: ['ずんだもん', '東北ずん子', '東北きりたん', '東北イタコ', 'あんこもん'] },
    { label: '🗾 九州弁', description: '九州そら', chars: ['九州そら'] },
    { label: '🗾 中部弁', description: '中部つるぎ', chars: ['中部つるぎ'] },
    { label: '🗾 中国地方', description: '中国うさぎ', chars: ['中国うさぎ'] },
    { label: '🗾 標準語', description: '四国めたん、春日部つむぎ 他多数', chars: ['四国めたん', '春日部つむぎ', '冥鳴ひまり', 'もち子さん', 'WhiteCUL', '櫻歌ミコ', '小夜/SAYO', '春歌ナナ', '琴詠ニア', 'No.7'] },
  ];

  const selected = await vscode.window.showQuickPick(dialects, {
    title: '🗾 方言・地域で選ぶ',
    placeHolder: '地域を選択',
  });

  if (!selected) return;

  const speakers = getSpeakers().filter(s => (selected as any).chars.includes(s.name));
  const items = speakers.map(s => ({
    label: `${s.id}: ${s.name}（${s.style}）`,
    description: s.personality,
    id: s.id,
  }));

  const charSelected = await vscode.window.showQuickPick(items, {
    title: `${selected.label} のキャラクター`,
    placeHolder: 'キャラクターを選択',
  });

  if (charSelected) {
    runNotify(`set-speaker ${(charSelected as any).id}`);
    updateToggleStatus();
    runNotifyAsync(`"方言キャラクターを変更しました！" complete`);
  }
}

async function selectEngine() {
  const engines = [
    { label: 'VOICEVOX (ボイスボックス)', description: '無料 ★おすすめ', detail: 'ずんだもん等100+キャラ・APIキー不要', value: 'voicevox' },
    { label: 'COEIROINK (コエイロインク)', description: '無料', detail: 'つくよみちゃん等・VOICEVOX互換', value: 'coeiroink' },
    { label: 'AivisSpeech (アイビススピーチ)', description: '無料', detail: '高品質ローカルTTS', value: 'aivis_speech' },
    { label: 'Style-Bert-VITS2 (スタイルバートビッツツー)', description: '無料', detail: '自分の声を学習して使える', value: 'style_bert_vits2' },
    { label: 'Google Cloud TTS (グーグルTTS)', description: '無料枠あり', detail: '月100万文字無料・APIキー必要', value: 'google' },
    { label: 'Fish Audio (フィッシュオーディオ)', description: '有料', detail: 'リアルタイム音声クローン', value: 'fish_audio' },
    { label: 'ElevenLabs (イレブンラボ)', description: '有料', detail: '英語最高品質・感情表現豊か', value: 'elevenlabs' },
    { label: 'OpenAI TTS (オープンエーアイTTS)', description: '有料', detail: 'nova/alloy等6種の声', value: 'openai' },
  ];

  const selected = await vscode.window.showQuickPick(engines, {
    title: '🔧 エンジン変更',
    placeHolder: '音声エンジンを選択',
  });

  if (selected) {
    runNotify(`set-provider ${(selected as any).value}`);
    vscode.window.showInformationMessage(`エンジン変更: ${selected.label}`);
  }
}

export function deactivate() {}
