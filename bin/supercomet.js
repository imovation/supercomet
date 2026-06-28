#!/usr/bin/env node

const { readFileSync, existsSync, copyFileSync, mkdirSync, readdirSync, chmodSync } = require('fs');
const { resolve } = require('path');
const { execSync } = require('child_process');

const VERSION = '0.1.0';

function loadVersionYaml() {
  try {
    const vfy = resolve(__dirname, '..', 'dist', 'version.yaml');
    if (!existsSync(vfy)) return null;
    const raw = readFileSync(vfy, 'utf-8');
    const m = {};
    for (const line of raw.split('\n')) {
      const kv = line.match(/^(\S+):\s*(.+)/);
      if (kv) m[kv[1]] = kv[2].trim();
    }
    return m;
  } catch { return null; }
}

function parseSemver(v) {
  const m = (v || '').match(/(\d+)\.(\d+)\.(\d+)/);
  return m ? { major: +m[1], minor: +m[2], patch: +m[3] } : null;
}

function semverSatisfies(version, range) {
  const v = parseSemver(version);
  if (!v) return null;
  // Handle ">=x.y.z"
  const lo = range.match(/>=\s*(\d+\.\d+\.\d+)/);
  if (lo) {
    const min = parseSemver(lo[1]);
    if (!min) return null;
    if (v.major > min.major) return true;
    if (v.major === min.major && v.minor > min.minor) return true;
    if (v.major === min.major && v.minor === min.minor && v.patch >= min.patch) return true;
    return false;
  }
  return null;
}

function checkCometPrerequisites() {
  const issued = [];

  // Comet deploys scripts to .opencode/skills/comet/scripts/ on OpenCode
  const candidates = [
    resolve(process.cwd(), '.opencode', 'skills', 'comet', 'scripts', 'comet-env.sh'),
    resolve(process.cwd(), 'comet', 'scripts', 'comet-env.sh'),
  ];
  const cometEnv = candidates.find(p => existsSync(p)) || candidates[0];
  const hasCometScript = existsSync(cometEnv);

  // Detect if @rpamis/comet package is installed (globally or locally)
  let cometPkgVer = null;
  try {
    const out = execSync('npm list -g @rpamis/comet --depth=0 --json 2>/dev/null', {
      cwd: process.cwd(),
      stdio: ['ignore', 'pipe', 'ignore'],
      timeout: 5000
    }).toString();
    const data = JSON.parse(out);
    const findVer = (deps) => {
      if (!deps) return null;
      if (deps['@rpamis/comet']) return deps['@rpamis/comet'].version;
      for (const k of Object.keys(deps)) {
        if (deps[k].dependencies) {
          const v = findVer(deps[k].dependencies);
          if (v) return v;
        }
      }
      return null;
    };
    cometPkgVer = findVer(data.dependencies);
  } catch {}

  if (!hasCometScript) {
    if (cometPkgVer) {
      issued.push('WARN: Comet v' + cometPkgVer + ' is installed but not initialized in this project.');
      issued.push('      Run "comet init" first, then "supercomet init".');
    } else {
      issued.push('WARN: Comet not found. Install and initialize it first:');
      issued.push('      npm install -g @rpamis/comet && comet init');
    }
    return issued;
  }

  // comet-env.sh exists — check version compatibility
  if (cometPkgVer) {
    const compat = loadVersionYaml();
    if (compat && compat.comet) {
      const ok = semverSatisfies(cometPkgVer, compat.comet);
      if (ok === false) {
        issued.push(`WARN: Comet ${cometPkgVer} is older than compatible range (${compat.comet}).`);
        issued.push('      Consider upgrading: npm install -g @rpamis/comet@latest');
      }
    }
  }

  return issued;
}

function cmdInit() {
  const srcDir = resolve(__dirname, '..', 'src');
  const cwd = process.cwd();

  const scriptsDir = resolve(cwd, 'comet', 'scripts');
  const refDir = resolve(cwd, 'comet', 'reference');

  mkdirSync(scriptsDir, { recursive: true });
  mkdirSync(refDir, { recursive: true });

  const scriptSrcDir = resolve(srcDir, 'scripts');
  let copiedCount = 0;
  if (existsSync(scriptSrcDir)) {
    const files = readdirSync(scriptSrcDir);
    for (const f of files) {
      if (f.endsWith('.sh')) {
        const src = resolve(scriptSrcDir, f);
        const dest = resolve(scriptsDir, f);
        copyFileSync(src, dest);
        try { chmodSync(dest, 0o755); } catch (e) { /* ignore */ }
        copiedCount++;
        console.log(`  ${f} → comet/scripts/`);
      }
    }
  }

  const skillsDir = resolve(srcDir, 'skills');
  if (existsSync(skillsDir)) {
    const skillNames = readdirSync(skillsDir);
    for (const name of skillNames) {
      const skillMd = resolve(skillsDir, name, 'SKILL.md');
      if (existsSync(skillMd)) {
        const refDest = resolve(refDir, `${name}.md`);
        copyFileSync(skillMd, refDest);
        copiedCount++;
        console.log(`  ${name}/SKILL.md → comet/reference/${name}.md`);
      }
    }
  }

  console.log(`supercomet: deployed ${copiedCount} files to comet/`);
}

function main() {
  // Quick peer dependency check (non-blocking)
  try {
    const r = execSync('npm list -g @rpamis/comet --depth=0 2>/dev/null', { timeout: 3000 });
    if (!r.toString().includes('@rpamis/comet@')) {
      console.log('NOTE: @rpamis/comet is a peer dependency. Install: npm install -g @rpamis/comet');
    }
  } catch {
    console.log('NOTE: @rpamis/comet is a peer dependency. Install: npm install -g @rpamis/comet');
    console.log('      Then run "comet init" in your project before "supercomet init".');
  }

  const args = process.argv.slice(2);
  const cmd = args[0];

  if (cmd === 'version' || cmd === '--version' || cmd === '-v') {
    console.log(`supercomet v${VERSION}`);
    return;
  }

  if (cmd === 'init') {
    const force = args.includes('--force');

    if (!force) {
      const warnings = checkCometPrerequisites();
      if (warnings.length > 0) {
        for (const w of warnings) console.log(w);
        const hasWarn = warnings.some(w => w.startsWith('WARN:'));
        if (hasWarn) {
          console.log('');
          console.log('Run "supercomet init --force" to skip this check and deploy anyway.');
          return;
        }
      }
    }

    cmdInit();
    return;
  }

  console.log('supercomet — Comet skill bundle');
  console.log('');
  console.log('Usage:');
  console.log('  supercomet init         Deploy supercomet enhancements (with Comet preflight check)');
  console.log('  supercomet init --force  Skip preflight check and deploy');
  console.log('  supercomet version       Show version');
}

main();
