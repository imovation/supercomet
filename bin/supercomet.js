#!/usr/bin/env node

const { readFileSync, existsSync } = require('fs');
const { resolve } = require('path');

const VERSION = '0.1.0';

function main() {
  const args = process.argv.slice(2);
  const cmd = args[0];

  if (cmd === 'version' || cmd === '--version' || cmd === '-v') {
    console.log(`supercomet v${VERSION}`);
    return;
  }

  if (cmd === 'init') {
    console.log('supercomet: init not yet implemented');
    return;
  }

  console.log('supercomet — Comet skill bundle');
  console.log('');
  console.log('Usage:');
  console.log('  supercomet init       Deploy supercomet enhancements to current project');
  console.log('  supercomet version    Show version');
}

main();
