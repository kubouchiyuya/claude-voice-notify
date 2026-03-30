#!/usr/bin/env node

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';
import { createProvider, listAvailableProviders } from './providers/index.js';
import { playAudio } from './provider-base.js';
import type { TTSProvider, NotificationType } from './types.js';

let provider: TTSProvider;

try {
  provider = createProvider();
} catch (e) {
  console.error(`[claude-voice-notify] プロバイダー初期化エラー: ${e}`);
  process.exit(1);
}

console.error(`[claude-voice-notify] プロバイダー: ${provider.name}`);

const DEFAULT_MESSAGES: Record<NotificationType, string> = {
  complete: 'タスクが完了しました',
  confirm: '確認をお願いします',
  error: 'エラーが発生しました',
  info: 'お知らせがあります',
  custom: '',
};

const server = new Server(
  { name: 'claude-voice-notify', version: '1.0.0' },
  { capabilities: { tools: {} } }
);

server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: [
    {
      name: 'notify_complete',
      description: 'タスク完了を音声で通知する。メッセージ省略時は「タスクが完了しました」と読み上げる。',
      inputSchema: {
        type: 'object' as const,
        properties: {
          message: { type: 'string', description: '読み上げるメッセージ（省略可）' },
        },
      },
    },
    {
      name: 'notify_confirm',
      description: '確認が必要なことを音声で通知する。メッセージ省略時は「確認をお願いします」と読み上げる。',
      inputSchema: {
        type: 'object' as const,
        properties: {
          message: { type: 'string', description: '読み上げるメッセージ（省略可）' },
        },
      },
    },
    {
      name: 'notify_speak',
      description: '任意のテキストを音声で読み上げる。通知タイプ・速度・話者を指定可能。',
      inputSchema: {
        type: 'object' as const,
        properties: {
          text: { type: 'string', description: '読み上げるテキスト' },
          type: {
            type: 'string',
            enum: ['complete', 'confirm', 'error', 'info', 'custom'],
            description: '通知タイプ（省略時: custom）',
          },
          speed: { type: 'number', description: '読み上げ速度（0.5〜2.0、省略時: 1.0）' },
          speaker: {
            type: ['number', 'string'],
            description: 'スピーカーID（VOICEVOX: 数値、その他: 文字列）',
          },
        },
        required: ['text'],
      },
    },
    {
      name: 'notify_test',
      description: '音声通知の接続テストを実行する。「テスト成功」と読み上げる。',
      inputSchema: {
        type: 'object' as const,
        properties: {},
      },
    },
    {
      name: 'notify_list_providers',
      description: '利用可能な音声プロバイダーの一覧を表示する。',
      inputSchema: {
        type: 'object' as const,
        properties: {},
      },
    },
  ],
}));

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    switch (name) {
      case 'notify_complete': {
        const message = (args?.message as string) || DEFAULT_MESSAGES.complete;
        const audio = await provider.synthesize({ text: message, type: 'complete' });
        await playAudio(audio);
        return { content: [{ type: 'text', text: `✅ 完了通知: "${message}"` }] };
      }

      case 'notify_confirm': {
        const message = (args?.message as string) || DEFAULT_MESSAGES.confirm;
        const audio = await provider.synthesize({ text: message, type: 'confirm' });
        await playAudio(audio);
        return { content: [{ type: 'text', text: `❓ 確認通知: "${message}"` }] };
      }

      case 'notify_speak': {
        const text = args?.text as string;
        if (!text) {
          return { content: [{ type: 'text', text: 'エラー: text パラメータが必要です' }], isError: true };
        }
        const audio = await provider.synthesize({
          text,
          type: (args?.type as NotificationType) || 'custom',
          speed: args?.speed as number | undefined,
          speaker: args?.speaker as number | string | undefined,
        });
        await playAudio(audio, args?.volume as number | undefined);
        return { content: [{ type: 'text', text: `🔊 読み上げ: "${text}"` }] };
      }

      case 'notify_test': {
        const audio = await provider.synthesize({
          text: 'テスト成功。音声通知が正常に動作しています。',
          type: 'info',
        });
        await playAudio(audio);
        return {
          content: [{
            type: 'text',
            text: `✅ テスト成功\nプロバイダー: ${provider.name}\n${provider.description}`,
          }],
        };
      }

      case 'notify_list_providers': {
        const providers = listAvailableProviders();
        const list = providers
          .map((p) => `${p.isFree ? '🆓' : '💰'} ${p.name}: ${p.description}`)
          .join('\n');
        return {
          content: [{
            type: 'text',
            text: `利用可能なプロバイダー:\n${list}\n\n現在: ${provider.name}\n切り替え: NOTIFY_PROVIDER 環境変数を設定`,
          }],
        };
      }

      default:
        return { content: [{ type: 'text', text: `Unknown tool: ${name}` }], isError: true };
    }
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    return {
      content: [{ type: 'text', text: `音声通知エラー: ${errorMessage}` }],
      isError: true,
    };
  }
});

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error('[claude-voice-notify] MCPサーバー起動完了');
}

main().catch((error) => {
  console.error('[claude-voice-notify] 致命的エラー:', error);
  process.exit(1);
});
