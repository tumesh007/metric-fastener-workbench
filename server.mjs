import http from 'node:http';
import { spawn } from 'node:child_process';
import { createReadStream, existsSync } from 'node:fs';
import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const projectDir = path.dirname(fileURLToPath(import.meta.url));
const openscad = findOpenSCAD();
let rendering = false;

function findOpenSCAD() {
  const candidates = process.platform === 'darwin'
    ? ['/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD', 'openscad']
    : process.platform === 'win32'
      ? ['C:\\Program Files\\OpenSCAD\\openscad.exe', 'openscad']
      : ['openscad'];
  return candidates.find(candidate => candidate === 'openscad' || existsSync(candidate)) ?? 'openscad';
}

function send(res, status, message, type = 'text/plain; charset=utf-8') {
  res.writeHead(status, { 'Content-Type': type, 'Cache-Control': 'no-store' });
  res.end(message);
}

async function readBody(req, limit = 1024 * 1024) {
  const chunks = [];
  let size = 0;
  for await (const chunk of req) {
    size += chunk.length;
    if (size > limit) throw new Error('SCAD source exceeds the 1 MB limit.');
    chunks.push(chunk);
  }
  return Buffer.concat(chunks).toString('utf8');
}

function renderScad(inputFile, outputFile) {
  return new Promise((resolve, reject) => {
    const child = spawn(openscad, ['-o', outputFile, inputFile], { stdio: ['ignore', 'pipe', 'pipe'] });
    let log = '';
    child.stdout.on('data', chunk => { log += chunk.toString(); });
    child.stderr.on('data', chunk => { log += chunk.toString(); });
    child.once('error', reject);
    child.once('close', code => {
      if (code === 0) resolve(log);
      else reject(new Error(log.trim() || `OpenSCAD exited with status ${code}.`));
    });
  });
}

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, 'http://127.0.0.1');
  if (req.method === 'GET' && (url.pathname === '/' || url.pathname === '/index.html')) {
    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8', 'Cache-Control': 'no-store' });
    createReadStream(path.join(projectDir, 'index.html')).pipe(res);
    return;
  }

  if (req.method !== 'POST' || url.pathname !== '/api/render') {
    send(res, 404, 'Not found.');
    return;
  }
  if (rendering) {
    send(res, 429, 'Another STL render is already running. Wait for it to finish.');
    return;
  }

  let workDir;
  rendering = true;
  try {
    const source = await readBody(req);
    const validParts = ['bolt', 'nut', 'washer', 'threaded_rod', 'set_screw', 'tslot_nut', 'self_tapping', 'heat_set_insert', 'wall_plug', 'batch'];
    const partMatch = source.match(/part\s*=\s*"([^"]+)"/);
    const requestedPart = partMatch && validParts.includes(partMatch[1]) ? partMatch[1] : 'batch';

    workDir = await mkdtemp(path.join(os.tmpdir(), 'metric-fastener-'));
    const inputFile = path.join(workDir, `${requestedPart}.scad`);
    const outputFile = path.join(workDir, `${requestedPart}.stl`);
    await writeFile(inputFile, source, 'utf8');
    const log = await renderScad(inputFile, outputFile);
    const stat = await readFile(outputFile);
    if (!stat.length) throw new Error('OpenSCAD created an empty STL file.');
    res.writeHead(200, {
      'Content-Type': 'model/stl',
      'Content-Length': stat.length,
      'Content-Disposition': `attachment; filename="metric_fastener_${requestedPart}.stl"`,
      'X-OpenSCAD-Log': encodeURIComponent(log.slice(-1200)),
      'Cache-Control': 'no-store'
    });
    res.end(stat);
  } catch (error) {
    const status = error.message.includes('1 MB') ? 413 : 500;
    if (!res.headersSent) send(res, status, error.message);
  } finally {
    rendering = false;
    if (workDir) await rm(workDir, { recursive: true, force: true });
  }
});

const port = process.env.PORT || 4173;
const host = process.env.HOST || '0.0.0.0';

server.listen(port, host, () => {
  console.log(`Metric Fastener Workbench running at:`);
  console.log(`  Local:   http://127.0.0.1:${port}`);
  console.log(`  Network: http://${host === '0.0.0.0' ? '<your-local-ip>' : host}:${port}`);
  console.log(`OpenSCAD renderer: ${openscad}`);
});
