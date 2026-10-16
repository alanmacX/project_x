// Extract current product copy without modifying application source.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const root=path.resolve(__dirname,'..'),out=path.resolve(process.argv[2]||path.join(root,'output/copy-review-2026-10-10'));
const walk=dir=>fs.readdirSync(dir,{withFileTypes:true}).flatMap(e=>e.isDirectory()?walk(path.join(dir,e.name)):[path.join(dir,e.name)]);
const files=[...walk(path.join(root,'entry/src/main')), ...walk(path.join(root,'AppScope'))].filter(f=>/\.(ets|ts)$/.test(f)||/\/element\/string\.json$/.test(f)||/\/(app|module|form_config)\.json5?$/.test(f));
const records=new Map();let literals=0;
function area(file){const n=path.basename(file);if(/Study|Demo|Acceptance|SketchLab|FridgePreviewer|Fixtures/.test(n))return '开发演示';if(/Scene|SchedulePanel/.test(n))return '定时场景';if(/Timetable|Course|Lesson|WakeUp|ScheduleImport/.test(n))return '课程表';if(/Album/.test(n))return '专辑';if(/Template|Share|Receive|Incoming/.test(n))return '导入与分享';if(/PhotoCrop|Background/.test(n))return '画布背景与照片';if(/Sketch|Subject|SuperResolution/.test(n))return '抠图与手绘';if(/Capability|CapBlock|TimeCapabilities|Battery|Calendar|Lunar|Reading|Hook/.test(n))return '能力与衬底';if(/Index/.test(n))return '首页与卡片编辑';if(/widget|form\//.test(file))return '桌面组件';if(/Editor|Settings|Color/.test(n))return '编辑控件';return '通用与资源';}
function add(file,text,start,end,raw,context){
 if(!text.trim())return;
 const chinese=/[\u3400-\u9fff]/.test(text), english=/^[A-Za-z][A-Za-z\s.!?&+…-]{2,100}$/.test(text)&&/\b(Text|Button|placeholder|accessibilityText|message|title|label|value)\s*\(/.test(context);
 if(!chinese&&!english)return;
 const group=area(file);let kind='界面文案';
 if(/console\.|hilog\.|logger\.|\.info\(|\.warn\(|\.error\(/.test(context))kind='日志';
 else if(/Error\(|throw |message:|message\s*=|error\s*=|templateError\(|getPromptAction|showToast|\.reject\(/.test(context))kind='提示与异常';
 else if(/accessibility/.test(context))kind='无障碍';
 else if(/placeholder/.test(context))kind='占位提示';
 if(/Holiday|Lunar|School|Adapters/.test(path.basename(file))&&!/Error\(|Text\(/.test(context))kind='数据与解析词';
 if(group==='开发演示')kind='演示与示例';
 const key=group+'\0'+kind+'\0'+text;const id='C-'+crypto.createHash('sha256').update(key).digest('hex').slice(0,10);
 const rel=path.relative(root,file),source=fs.readFileSync(file,'utf8'),line=source.slice(0,start).split('\n').length;
 const ref={file:rel,line,start,end,raw,context:context.trim().slice(0,600)};
 if(!records.has(key))records.set(key,{id,group,kind,text,dynamic:raw.startsWith('`'),refs:[]});
 const r=records.get(key);if(!r.refs.some(x=>x.file===rel&&x.start===start))r.refs.push(ref);literals++;
}
for(const file of files){const source=fs.readFileSync(file,'utf8');
 if(/\.(ets|ts)$/.test(file)){
  const ast=ts.createSourceFile(file,source,ts.ScriptTarget.Latest,true,ts.ScriptKind.TS),regexSpans=new Map();
  function context(pos){const a=source.lastIndexOf('\n',pos)+1,b=source.indexOf('\n',pos);return source.slice(a,b<0?source.length:b);}
  function visit(n){if(n.kind===ts.SyntaxKind.RegularExpressionLiteral)regexSpans.set(n.getStart(ast),n.end);ts.forEachChild(n,visit);}visit(ast);
  const scanner=ts.createScanner(ts.ScriptTarget.Latest,true,ts.LanguageVariant.Standard,source);let token;
  function templateEnd(){let depth=0,t;while((t=scanner.scan())!==ts.SyntaxKind.EndOfFileToken){const pos=scanner.getTokenPos();if(regexSpans.has(pos)){scanner.setTextPos(regexSpans.get(pos));continue}if(t===ts.SyntaxKind.TemplateHead){templateEnd();continue}if(t===ts.SyntaxKind.OpenBraceToken)depth++;if(t===ts.SyntaxKind.CloseBraceToken){if(depth>0){depth--;continue}t=scanner.reScanTemplateToken(false);if(t===ts.SyntaxKind.TemplateTail)return scanner.getTextPos();}}throw Error('Unclosed template: '+file+':'+scanner.getTokenPos());}
  while((token=scanner.scan())!==ts.SyntaxKind.EndOfFileToken){const a=scanner.getTokenPos();if(regexSpans.has(a)){scanner.setTextPos(regexSpans.get(a));continue}if(token===ts.SyntaxKind.TemplateHead){const b=templateEnd(),raw=source.slice(a,b);add(file,raw.slice(1,-1),a,b,raw,context(a));continue}if(token!==ts.SyntaxKind.StringLiteral&&token!==ts.SyntaxKind.NoSubstitutionTemplateLiteral)continue;const b=scanner.getTextPos();add(file,scanner.getTokenValue(),a,b,source.slice(a,b),context(a));}
 }else{
  const scanner=ts.createScanner(ts.ScriptTarget.Latest,true,ts.LanguageVariant.Standard,source);let token;while((token=scanner.scan())!==ts.SyntaxKind.EndOfFileToken){if(token!==ts.SyntaxKind.StringLiteral)continue;const a=scanner.getTokenPos(),b=scanner.getTextPos();add(file,scanner.getTokenValue(),a,b,source.slice(a,b),source.slice(source.lastIndexOf('\n',a)+1,source.indexOf('\n',b)<0?source.length:source.indexOf('\n',b)));}
 }
}
const rows=[...records.values()].sort((a,b)=>a.group.localeCompare(b.group,'zh-CN')||a.kind.localeCompare(b.kind,'zh-CN')||a.refs[0].file.localeCompare(b.refs[0].file)||a.refs[0].start-b.refs[0].start);
const manifest={version:1,generatedAt:new Date().toISOString(),commit:require('child_process').execFileSync('git',['rev-parse','--short','HEAD'],{cwd:root,encoding:'utf8'}).trim(),sourceRoot:root,files:files.length,rows};
fs.mkdirSync(out,{recursive:true});fs.writeFileSync(path.join(out,'copy-inventory.json'),JSON.stringify(manifest,null,2));
const quote=x=>'"'+String(x).replaceAll('"','""')+'"';
const csv=[['ID','区域','类型','原文','处理（保留/修改/删除）','修改后文案','备注','代码位置','动态模板'],...rows.map(r=>[r.id,r.group,r.kind,r.text,'保留','','',r.refs.map(x=>x.file+':'+x.line).join('\n'),r.dynamic?'是':'否'])].map(r=>r.map(quote).join(',')).join('\r\n');
fs.writeFileSync(path.join(out,'文案清单.csv'),'\ufeff'+csv);
const template=fs.readFileSync(path.join(__dirname,'copy-review.html'),'utf8');fs.writeFileSync(path.join(out,'index.html'),template.replace('/*__INVENTORY__*/',JSON.stringify(manifest).replaceAll('<','\\u003c')));
console.log(JSON.stringify({out,files:files.length,uniqueCopy:rows.length,occurrences:rows.reduce((s,r)=>s+r.refs.length,0),groups:Object.fromEntries([...new Set(rows.map(r=>r.group))].map(g=>[g,rows.filter(r=>r.group===g).length]))},null,2));
