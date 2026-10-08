#!/usr/bin/env node
// Authoring aid only: trusted repo models are transpiled, external files are JSON only.
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const ts = require(process.env.FRIDGE_TYPESCRIPT || '/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const modelRoot = path.resolve(__dirname, '../entry/src/main/ets/model');
const cache = new Map();
function load(name) {
  if (!/^[A-Za-z][A-Za-z0-9]*$/.test(name)) throw Error('Unsupported model dependency');
  if (cache.has(name)) return cache.get(name);
  const module = {exports: {}};
  const code = ts.transpileModule(fs.readFileSync(path.join(modelRoot, name + '.ets'), 'utf8'), {
    compilerOptions: {module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2020}
  }).outputText;
  vm.runInThisContext('(function(require,module,exports){' + code + '\n})', {filename: name})(
    spec => { if (!spec.startsWith('./')) throw Error('Unsupported SDK dependency: ' + spec); return load(spec.slice(2)); },
    module, module.exports
  );
  cache.set(name, module.exports);
  return module.exports;
}
function fields(source, block) {
  const body = source.split(block)[1]?.split('\n}')[0];
  if (!body) throw Error('Model declaration changed; update the authoring checker');
  return new Set(Array.from(body.matchAll(/^\s*([a-zA-Z][\w]*)\??\s*:/gm), m => m[1]));
}
function known(object, allowed, label) {
  if (!object || typeof object !== 'object' || Array.isArray(object)) throw Error(label + ' must be an object');
  for (const key of Object.keys(object)) if (!allowed.has(key)) throw Error(label + ': unsupported field ' + key);
}
function validate(json) {
  const raw = JSON.parse(json);
  known(raw, new Set(['format','version','kind','state','assets']), 'package');
  const source = fs.readFileSync(path.join(modelRoot, 'CardSchema.ets'), 'utf8');
  known(raw.state, fields(source, 'export class FridgeState {'), 'state');
  const schema = load('CardSchema');
  const ids = new Set();
  const groups = new Map();
  const addID = id => { if (typeof id !== 'string' || !id.length || ids.has(id)) throw Error('Missing or duplicate ID: ' + id); ids.add(id); };
  if (!Array.isArray(raw.state.cards)) throw Error('cards must be an array');
  for (const c of raw.state.cards) {
    known(c, fields(source, 'export class FridgeCard {'), 'card');
    if (c.caps !== undefined) throw Error('Legacy caps are not authored in schema 2');
    addID(c.id);
    if (c.groupId) groups.set(c.groupId, (groups.get(c.groupId) || 0) + 1);
    for (const key of ['x','y','w','h','rot','z']) if (!Number.isFinite(c[key])) throw Error(c.id + ': invalid geometry ' + key);
    if (!['rect','round','pill','blob','subject'].includes(c.shape)) throw Error(c.id + ': unsupported shape');
    if (c.capability) {
      known(c.capability, fields(source, 'export interface CapBlock {'), 'capability');
      if (!schema.CAPABILITIES.includes(c.capability.k)) throw Error('Unsupported capability: ' + c.capability.k);
      for (const key of ['url','field','sourceConfigured','parcels','parcelPlace','temp','desc'])
        if (c.capability[key] !== undefined) throw Error('Retired or network capability field: ' + key);
    }
    for (const el of c.elements || []) {
      const allowed = fields(source, 'export class CanvasElement extends ElementBox {');
      for (const key of fields(source, 'export class ElementBox {')) allowed.add(key);
      known(el, allowed, 'element'); addID(el.id);
      if (!['text','image','shape'].includes(el.kind)) throw Error('Unsupported element kind: ' + el.kind);
    }
  }
  if (raw.kind === 'card' && groups.size) throw Error('Single-card package must clear groupId');
  for (const [id, count] of groups) if (count < 2) throw Error('Group has only one member: ' + id);
  // App decoder checks container, capacity, asset references and schema normalization.
  const normalized = load('TemplatePackage').readPackage(json);
  for (let i=0; i<raw.state.cards.length; i++) {
    const a=raw.state.cards[i], b=normalized.state.cards[i];
    for (const key of ['x','y','w','h','rot','z','shape','material','paper','ink','groupId']) {
      if (a[key] !== undefined) assert.deepEqual(b[key], a[key], a.id + ': reader changed ' + key);
    }
    if (a.capability?.readingBlend !== undefined)
      assert.equal(b.capability?.readingBlend, a.capability.readingBlend, a.id + ': reading surface is not supported for this capability');
    if (a.capBox) for (const key of Object.keys(a.capBox))
      assert.deepEqual(b.capBox[key], a.capBox[key], a.id + ': reader changed capBox.' + key);
    for (let j=0; j<(a.elements || []).length; j++) for (const key of Object.keys(a.elements[j]))
      assert.deepEqual(b.elements[j][key], a.elements[j][key], a.id + ': reader changed element.' + key);
  }
  return {kind: normalized.kind, cards: normalized.state.cards.length, assets: normalized.assets.length};
}
module.exports = {validate};
if (require.main === module) {
  try {
    if (process.argv.length !== 3) throw Error('Usage: node scripts/fridge-package-check.cjs /absolute/path/work.fridge');
    const result = validate(fs.readFileSync(process.argv[2], 'utf8'));
    console.log('PASS current v1 reader + authoring checks: ' + JSON.stringify(result));
    console.log('Visual rendering, media decoding, permissions and Form behavior still require app verification.');
  } catch (error) { console.error(error.message); process.exitCode=1; }
}
