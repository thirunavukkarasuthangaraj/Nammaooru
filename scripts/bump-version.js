#!/usr/bin/env node
/**
 * Auto-increment the frontend patch version (e.g. 1.0.261 -> 1.0.262).
 * Run automatically by the git pre-commit hook (.githooks/pre-commit) so the
 * version increases on EVERY commit without any manual editing.
 *
 * Only the version line is rewritten, so the rest of package.json formatting is untouched.
 */
const fs = require('fs');
const path = require('path');

const pkgPath = path.join(__dirname, '..', 'frontend', 'package.json');

if (!fs.existsSync(pkgPath)) {
  // Nothing to bump - don't block the commit
  process.exit(0);
}

const content = fs.readFileSync(pkgPath, 'utf8');
const match = content.match(/"version":\s*"(\d+)\.(\d+)\.(\d+)"/);

if (!match) {
  console.warn('bump-version: could not find a semver "version" in frontend/package.json - skipping');
  process.exit(0);
}

const [, major, minor, patch] = match;
const next = `${major}.${minor}.${Number(patch) + 1}`;

const updated = content.replace(
  /("version":\s*")\d+\.\d+\.\d+(")/,
  `$1${next}$2`
);

fs.writeFileSync(pkgPath, updated);
console.log(`bump-version: frontend ${major}.${minor}.${patch} -> ${next}`);
