#!/usr/bin/env node

const { readFileSync, existsSync, copyFileSync, mkdirSync, readdirSync, chmodSync } = require('fs');
const { resolve } = require('path');

const VERSION = '0.1.0';

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
  const args = process.argv.slice(2);
  const cmd = args[0];

  if (cmd === 'version' || cmd === '--version' || cmd === '-v') {
    console.log(`supercomet v${VERSION}`);
    return;
  }

  if (cmd === 'init') {
    cmdInit();
    return;
  }

  console.log('supercomet — Comet skill bundle');
  console.log('');
  console.log('Usage:');
  console.log('  supercomet init       Deploy supercomet enhancements to current project');
  console.log('  supercomet version    Show version');
}

main();
