const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const root=path.resolve(__dirname,'../entry/src/main/ets/model'),cache=new Map(),files=new Map(),fds=new Map();
let fd=0,failRead=false,failWrite=false,oversize=false;
const io={OpenMode:{READ_ONLY:0,CREATE:1,READ_WRITE:2,TRUNC:4},
 async open(p,mode){p=p.replace(/^file:\/\//,'');if(mode)files.set(p,Buffer.alloc(0));if(!files.has(p))throw Error('missing');fds.set(++fd,p);return{fd};},
 async stat(f){return{size:oversize?90*1024*1024+1:files.get(fds.get(f)).length};},
 async read(f,b,o){if(failRead)return 0;const source=files.get(fds.get(f)),n=Math.min(65537,b.byteLength,source.length-o.offset);new Uint8Array(b).set(source.subarray(o.offset,o.offset+n));return n;},
 async write(f,b,o){if(failWrite)return 0;const p=fds.get(f),n=Math.min(1021,b.byteLength),old=files.get(p),out=Buffer.alloc(Math.max(old.length,o.offset+n));old.copy(out);Buffer.from(b).copy(out,o.offset,0,n);files.set(p,out);return n;},
 closeSync(f){fds.delete(f);},unlinkSync(p){files.delete(p);}};
const kits={'@kit.CoreFileKit':{fileIo:io}};
function load(name){if(cache.has(name))return cache.get(name);const mod={exports:{}};const js=ts.transpileModule(fs.readFileSync(path.join(root,name+'.ets'),'utf8').replace(/^@Concurrent\s*$/gm,''),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText;vm.runInThisContext('(function(require,module,exports){'+js+'})')(s=>kits[s]||load(s.replace('./','')),mod,mod.exports);cache.set(name,mod.exports);return mod.exports;}
(async()=>{
 const {stageIncomingTemplate,incomingTemplateUri,removeStagedTemplate}=load('IncomingTemplate');
 const input=Buffer.alloc(700003);for(let i=0;i<input.length;i++)input[i]=i%251;files.set('/sender/works.fridge',input);
 const local=await stageIncomingTemplate('file:///sender/works.fridge','/cache');assert.deepEqual(files.get(local.slice(7)),input,'all bytes survive partial reads AND partial writes');assert.equal(fds.size,0);
 removeStagedTemplate('file:///sender/works.fridge','/cache');assert.ok(files.has('/sender/works.fridge'),'sender original survives cleanup');
 for(const uri of ['file:///cache/works.fridge','file:///cache/../sender/works.fridge','file:///cache/received_1_2.fridge/other','https://example.org/received_1_2.fridge'])removeStagedTemplate(uri,'/cache');
 assert.ok(files.has(local.slice(7)),'only an owned exact receiving copy can be removed');
 removeStagedTemplate(local,'/cache');assert.ok(!files.has(local.slice(7)),'cancelled receiving copy is deleted');removeStagedTemplate(local,'/cache');
 const saved=files.size;failRead=true;await assert.rejects(stageIncomingTemplate('file:///sender/works.fridge','/cache'),/未读取完整/);failRead=false;assert.equal(files.size,saved);assert.equal(fds.size,0);
 failWrite=true;await assert.rejects(stageIncomingTemplate('file:///sender/works.fridge','/cache'),/保存失败/);failWrite=false;assert.equal(files.size,saved);assert.equal(fds.size,0);
 oversize=true;await assert.rejects(stageIncomingTemplate('file:///sender/works.fridge','/cache'),/90MB/);oversize=false;assert.equal(files.size,saved);assert.equal(fds.size,0);
 for(const uri of ['https://example.org/works.fridge','http://example.org/a.png','data:image/png;base64,AA','']){assert.equal(incomingTemplateUri(uri),'');await assert.rejects(stageIncomingTemplate(uri,'/cache'),/本地/);}
 const {FridgeCard,CanvasElement,defaultState,normalizeState,normalizeElement,normalizeCapability,typeLabel}=load('CardSchema');
 const state=defaultState(),card=new FridgeCard(),element=new CanvasElement();card.id='old';card.groupId='group';element.id='image';element.kind='image';element.src='https://example.org/image.png';card.elements=[element];card.capability={k:'fetch',title:'配额',value:'42',unit:'次',url:'https://example.org/private',sourceConfigured:true};state.cards=[card];state.background.src=state.background.photo='https://example.org/bg.png';
 const migrated=normalizeState(state);assert.equal(migrated.cards[0].capability,null);assert.equal(migrated.cards[0].elements[0].src,'');assert.equal(migrated.cards[0].elements[1].text,'配额\n42次');assert.equal(migrated.cards[0].groupId,'group');assert.ok(!JSON.stringify(migrated).includes('https://'));assert.deepEqual(normalizeState(migrated),migrated,'migration is idempotent');
 for(const uri of ['https://example.org/a.png','data:image/png;base64,AA','javascript:x']){element.src=uri;assert.equal(normalizeElement(element).src,'');assert.equal(normalizeCapability({k:'album',albumCover:uri}).albumCover,'');}
 assert.equal(typeLabel('dayprogress'),'今日进度');assert.equal(typeLabel('battery'),'本机电量');assert.equal(typeLabel('album'),'音乐专辑');
 console.log('PASS: local-only migration, retired URL results retained as static artwork, correct capability labels; bounded URI staging, short reads/writes, truncation failure rollback, oversized/remote rejection and descriptor cleanup.');
})().catch(e=>{console.error(e);process.exitCode=1;});
