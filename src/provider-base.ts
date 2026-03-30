import { execFile } from 'child_process';
import { writeFile, unlink } from 'fs/promises';
import { tmpdir } from 'os';
import { join } from 'path';
import { platform } from 'process';

export async function playAudio(audioBuffer: Buffer, volume: number = 1.0): Promise<void> {
  const tmpPath = join(tmpdir(), `claude-voice-${Date.now()}.wav`);
  await writeFile(tmpPath, audioBuffer);

  try {
    await new Promise<void>((resolve, reject) => {
      const os = platform;
      let cmd: string;
      let args: string[];

      if (os === 'darwin') {
        cmd = 'afplay';
        args = ['-v', String(volume), tmpPath];
      } else if (os === 'win32') {
        cmd = 'powershell';
        args = [
          '-Command',
          `(New-Object Media.SoundPlayer '${tmpPath}').PlaySync()`,
        ];
      } else {
        // Linux: try aplay, then paplay
        cmd = 'aplay';
        args = [tmpPath];
      }

      execFile(cmd, args, (error) => {
        if (error) reject(error);
        else resolve();
      });
    });
  } finally {
    await unlink(tmpPath).catch(() => {});
  }
}
