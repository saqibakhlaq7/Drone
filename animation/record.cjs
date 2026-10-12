// Render the animation frame-by-frame in headless Chromium and write frames + an RPM log.
//   NODE_PATH=$(npm root -g) node animation/record.cjs [--three <node_modules/three>] [--fps 30] [--out dir]
// Then: python3 tools/make_video.py   (audio synthesis + ffmpeg encode)
const { chromium } = require('playwright');
const http = require('http');
const fs = require('fs');
const path = require('path');

const arg = (k, d) => { const i = process.argv.indexOf(k); return i > 0 ? process.argv[i + 1] : d; };
const ROOT = __dirname;
const THREE_DIR = arg('--three', null);
const FPS = Number(arg('--fps', 30));
const OUT = path.resolve(arg('--out', path.join(ROOT, '..', 'build', 'frames')));
const W = Number(arg('--width', 1280)), H = Number(arg('--height', 720));

const types = { '.html': 'text/html', '.js': 'text/javascript', '.glb': 'model/gltf-binary' };
const server = http.createServer((req, res) => {
  const f = path.join(ROOT, decodeURIComponent(req.url.split('?')[0]));
  if (!f.startsWith(ROOT) || !fs.existsSync(f)) { res.writeHead(404); return res.end(); }
  res.writeHead(200, { 'Content-Type': types[path.extname(f)] || 'application/octet-stream' });
  fs.createReadStream(f).pipe(res);
});

(async () => {
  await new Promise((r) => server.listen(0, r));
  const port = server.address().port;
  fs.mkdirSync(OUT, { recursive: true });
  const browser = await chromium.launch({
    executablePath: process.env.CHROMIUM_PATH || undefined,
    args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'],
  });
  const page = await browser.newPage({ viewport: { width: W, height: H }, deviceScaleFactor: 1 });
  page.on('console', (m) => console.log('[page]', m.text()));
  page.on('pageerror', (e) => console.log('[page error]', e.message));
  if (THREE_DIR) {
    await page.route('https://cdn.jsdelivr.net/npm/three@0.160.0/**', (route) => {
      const rel = route.request().url().split('three@0.160.0/')[1];
      route.fulfill({ path: path.join(THREE_DIR, rel), contentType: 'text/javascript' });
    });
  }
  await page.goto(`http://localhost:${port}/index.html?record`);
  await page.waitForFunction(() => window.__ready === true, null, { timeout: 120000 });
  const duration = await page.evaluate(() => window.__duration);
  const n = Math.round(duration * FPS);
  const t0 = Date.now();
  for (let i = 0; i < n; i++) {
    await page.evaluate((t) => window.__frame(t), i / FPS);
    await page.screenshot({ path: path.join(OUT, `f${String(i).padStart(5, '0')}.jpg`), type: 'jpeg', quality: 93 });
    if (i % 60 === 0) console.log(`frame ${i}/${n}  ${((Date.now() - t0) / 1000).toFixed(0)} s`);
  }
  fs.writeFileSync(path.join(OUT, 'rpm_log.json'), JSON.stringify(await page.evaluate(() => window.__audioLog())));
  await browser.close(); server.close();
  console.log('done', n, 'frames ->', OUT);
})();
