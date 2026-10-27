const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path');
const app=JSON.parse(fs.readFileSync('AppScope/app.json5','utf8')).app;assert.equal(app.cloudFileSyncEnabled,false);assert.equal(app.cloudStructuredDataSyncEnabled,false);
const root=path.resolve('entry/src/main/ets'),seen=new Set(),pending=['entryability/EntryAbility','form/FridgeFormAbility','form/WidgetConfigAbility','pages/Index','pages/WidgetBinding','pages/ReceiveTemplate'];
while(pending.length){const name=pending.pop(),file=path.join(root,name+'.ets');if(seen.has(file)||!fs.existsSync(file))continue;seen.add(file);const source=fs.readFileSync(file,'utf8');for(const match of source.matchAll(/(?:from\s*|import\s*\()\s*['"]([^'"]+)['"]/g)){if(match[1].startsWith('.'))pending.push(path.relative(root,path.resolve(path.dirname(file),match[1])));}}
for(const model of ['SystemCloudSync','CloudSyncFiles','CloudSyncProtocol','PrivateSyncCodec'])assert(!seen.has(path.join(root,'model',model+'.ets')),'unverified cloud module cannot be reachable: '+model);
assert(!fs.existsSync(path.join(root,'views/CloudSyncDialog.ets')));
console.log('PASS local release isolation: cloud capabilities disabled and no reachable experimental sync/merge/delete coordinator.');
