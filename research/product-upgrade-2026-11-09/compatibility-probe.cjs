// Read-only synthetic diagnostic for the report. Run from any working directory.
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const root = path.resolve(__dirname, '../..');
const context = vm.createContext({});
vm.runInContext(fs.readFileSync(path.join(root, 'previewer/shared-models.js'), 'utf8'), context);
const schema = context.FridgeCore.load('CardSchema');
const factory = context.FridgeCore.load('TemplateFactory');
const cases = [];
for (const kind of ['known', 'unknown-id', 'future-version']) {
  const state = schema.defaultState();
  state.cards = factory.makeTemplateCards('portrait', 1, () => 'audit_card');
  if (kind === 'unknown-id') state.cards[0].template.id = 'future-design';
  if (kind === 'future-version') state.cards[0].template.version = 2;
  const normalized = schema.normalizeState(JSON.parse(JSON.stringify(state)));
  cases.push({
    case: kind,
    cards: normalized.cards.length,
    templateRetained: Boolean(normalized.cards[0].template),
    templateInSerializedState: JSON.stringify(normalized).includes('"template"')
  });
}
const index = fs.readFileSync(path.join(root, 'entry/src/main/ets/pages/Index.ets'), 'utf8');
const growth = [[700, 0.35], [450, 0.60], [350, 0.75]].map(([monthlyFirstOpens, monthlyReturn]) => {
  let active = 0;
  const months = [];
  for (let month = 0; month < 6; month++) {
    active = monthlyFirstOpens + monthlyReturn * active;
    months.push(Math.round(active));
  }
  return { monthlyFirstOpens, monthlyReturn, months };
});
console.log(JSON.stringify({
  cases,
  index: { lines: index.split('\n').length - 1, stateDeclarations: (index.match(/@State\b/g) || []).length },
  growth
}, null, 2));
