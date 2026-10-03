"""Bundle a pinned MIT adapter snapshot. No scripts are fetched at app runtime."""
import json, re, shutil, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
SOURCE = Path(sys.argv[1])
DEST = ROOT / 'entry/src/main/resources/rawfile/schools'
def records(path, key):
    text = path.read_text(encoding='utf-8-sig')
    result=[]
    for line in text.splitlines():
        m=re.match(r'\s*(-\s*)?(\w+):\s*(.*)',line)
        if not m:continue
        if m[1]:result.append({})
        if not result:continue
        value=m[3].strip()
        if value.startswith('"'):
            try:value=json.JSONDecoder().raw_decode(value)[0]
            except ValueError:raise ValueError(f'Malformed metadata: {path}')
        else:value=value.split(' #')[0].strip().strip("'")
        result[-1][m[2]]=value
    return result
DEST.mkdir(parents=True,exist_ok=True)
schools=[];omitted=[]
for s in records(SOURCE/'index/root_index.yaml','schools'):
    folder=s['resource_folder']
    if folder=='GLOBAL_TOOLS':continue # share resolvers/test tools are not school importers
    meta=SOURCE/'resources'/folder/'adapters.yaml'
    if not meta.is_file():continue
    adapters=[]
    for a in records(meta,'adapters'):
        filename=a.get('asset_js_path','')
        src=meta.parent/filename
        if not filename or '..' in filename or not src.is_file():
            omitted.append(a.get('adapter_id'));continue
        code=src.read_text(encoding='utf-8-sig')
        # These two adapters evaluate server-provided expressions; require separate adaptation.
        if re.search(r'\beval\s*\(|new\s+Function\s*\(',code):
            omitted.append(a.get('adapter_id'));continue
        relative=folder+'/'+filename
        (DEST/folder).mkdir(exist_ok=True)
        shutil.copyfile(src,DEST/relative)
        adapters.append({'id':a['adapter_id'],'name':a['adapter_name'],'url':a.get('import_url',''),
                         'script':'schools/'+relative,'category':a.get('category',''),'description':a.get('description','')})
    if adapters:schools.append({'id':s['id'],'name':s['name'],'initial':s['initial'],'adapters':adapters})
schools.append({'id':'qiangzhi_general','name':'强智教务 · 通用网页','initial':'Q','adapters':[{'id':'fridge_qz','name':'强智个人课表','url':'','script':'school-qiangzhi.js','category':'GENERAL_TOOL','description':'输入学校教务网址，登录后打开完整学期的个人课表，再读取。缺失的节次作息需在预览中补全。'}]})
schools.sort(key=lambda s:(s['initial'],s['name']))
(DEST/'catalog.json').write_text(json.dumps(schools,ensure_ascii=False,separators=(',',':')))
shutil.copyfile(SOURCE/'LICENSE',DEST/'LICENSE.txt')
(DEST/'SOURCE.txt').write_text('qingyu_warehouse / shiguang_warehouse\nhttps://github.com/Mutx163/qingyu_warehouse\nSnapshot: 42474728fd1d6537c6ece020aa16d117c18d2d2d\nMIT; copyright (c) 2025 星河欲转. See LICENSE.txt.\nThe adapter code is bundled unchanged. FridgeMemo provides its own ArkWeb host and preview validation.\nMissing placeholder assets, test/share tools, and server-expression evaluators excluded: '+', '.join(omitted)+'\n')
print(len(schools),'directory entries;',sum(len(s['adapters']) for s in schools),'bundled adapters;',len(omitted),'omitted')
