// usage: node scripts/stills.mjs out_dir frame1 frame2 ...
import {bundle} from '@remotion/bundler';
import {renderStill, selectComposition} from '@remotion/renderer';
import path from 'node:path';

const [outDir, ...frames] = process.argv.slice(2);
const browserExecutable = '/opt/pw-browsers/chromium_headless_shell-1194/chrome-linux/headless_shell';
const serveUrl = await bundle({entryPoint: path.resolve('src/index.ts')});
const composition = await selectComposition({serveUrl, id: 'FineryShowreel', browserExecutable});
for (const f of frames.map(Number)) {
  await renderStill({
    serveUrl, composition, frame: f, browserExecutable,
    output: path.join(outDir, `f${String(f).padStart(4, '0')}.png`),
    scale: 0.5, chromiumOptions: {gl: 'swangle'},
  });
  process.stdout.write(f + ' ');
}
