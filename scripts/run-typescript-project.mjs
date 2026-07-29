import { existsSync, mkdirSync, readdirSync, writeFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import path from 'node:path';

const task = process.argv[2];
const projectRoot = process.cwd();
const sourceRoot = path.join(projectRoot, 'src');

function containsTypeScript(directory) {
  if (!existsSync(directory)) {
    return false;
  }

  return readdirSync(directory, { withFileTypes: true }).some((entry) => {
    const target = path.join(directory, entry.name);
    return entry.isDirectory() ? containsTypeScript(target) : entry.name.endsWith('.ts');
  });
}

function run(command, args) {
  const result = spawnSync(command, args, {
    cwd: projectRoot,
    shell: process.platform === 'win32',
    stdio: 'inherit',
  });

  process.exit(result.status ?? 1);
}

const hasSource = containsTypeScript(sourceRoot);
const hasEntrypoint = existsSync(path.join(sourceRoot, 'main.ts'));

if (task === 'build') {
  if (!hasSource) {
    const outputDirectory = path.join(projectRoot, 'dist');
    mkdirSync(outputDirectory, { recursive: true });
    writeFileSync(
      path.join(outputDirectory, '.configuration-build'),
      'configuration-only\n',
      'utf8',
    );
    console.log('No TypeScript source exists yet; emitted a configuration-only build marker.');
    process.exit(0);
  }
  run('tsc', ['-p', 'tsconfig.build.json']);
}

if (task === 'typecheck') {
  if (!hasSource) {
    console.log('No TypeScript source exists yet; typecheck configuration is valid.');
    process.exit(0);
  }
  run('tsc', ['--noEmit', '-p', 'tsconfig.json']);
}

if (task === 'dev' || task === 'start') {
  if (!hasEntrypoint) {
    console.log('No src/main.ts exists yet; this configuration-only service has nothing to start.');
    process.exit(0);
  }
  const args =
    task === 'dev'
      ? ['--watch', '-r', 'ts-node/register', 'src/main.ts']
      : ['-r', 'ts-node/register', 'src/main.ts'];
  run('node', args);
}

if (task === 'start:prod') {
  if (!existsSync(path.join(projectRoot, 'dist', 'main.js'))) {
    console.log(
      'No dist/main.js exists yet; build the implemented service before production start.',
    );
    process.exit(0);
  }
  run('node', ['dist/main.js']);
}

console.error(`Unsupported TypeScript project task: ${task ?? '<missing>'}`);
process.exit(1);
