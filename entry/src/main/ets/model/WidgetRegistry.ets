import { getLibraryPreferences } from './LibraryStorage';
import { relationalStore } from '@kit.ArkData';
import { formProvider } from '@kit.FormKit';
import { canvasKey, readCatalog } from './CanvasLibrary';
import { FridgeState } from './CardSchema';

export class WidgetInstance {
  id:string=''; dimension:string=''; canvasId:string=''; ownerId:string=''; kind:string='desktop';
  revision:number=1; removed:boolean=false;
}
export class WidgetGuard { context:Context; instance:WidgetInstance; constructor(context:Context,instance:WidgetInstance){this.context=context;this.instance=instance;} }
const connections:Map<string,Promise<relationalStore.RdbStore>>=new Map();
export function widgetDimension(value:Object|undefined):string {
  if(value===2||value==='2'||value==='2*2')return '2*2';
  if(value===3||value==='3'||value==='2*4')return '2*4';
  if(value===4||value==='4'||value==='4*4')return '4*4';
  if(value===7||value==='7'||value==='6*4')return '6*4';
  return '';
}
function validId(id:string):void{if(!id||id.length>128)throw new Error('缺少有效的小组件实例');}
async function database(context:Context):Promise<relationalStore.RdbStore>{
  const key=context.databaseDir??'default';let pending=connections.get(key);
  if(!pending){pending=(async()=>{
    const db=await relationalStore.getRdbStore(context,{name:'widget_instances_v2.db',securityLevel:relationalStore.SecurityLevel.S1});
    await db.executeSql("CREATE TABLE IF NOT EXISTS widget_instances (form_id TEXT PRIMARY KEY, dimension TEXT NOT NULL, canvas_id TEXT NOT NULL DEFAULT '', owner_id TEXT NOT NULL DEFAULT '', kind TEXT NOT NULL DEFAULT 'desktop', revision INTEGER NOT NULL DEFAULT 1, removed INTEGER NOT NULL DEFAULT 0, lease_token TEXT NOT NULL DEFAULT '', lease_until INTEGER NOT NULL DEFAULT 0)");
    return db;
  })();connections.set(key,pending);pending.catch(()=>connections.delete(key));}
  return pending;
}
function record(result:relationalStore.ResultSet):WidgetInstance{
  const item=new WidgetInstance();item.id=result.getString(0);item.dimension=result.getString(1);item.canvasId=result.getString(2);item.ownerId=result.getString(3);item.kind=result.getString(4);item.revision=result.getLong(5);item.removed=result.getLong(6)!==0;return item;
}
const columns='form_id,dimension,canvas_id,owner_id,kind,revision,removed';
export async function widgetInstance(context:Context,id:string):Promise<WidgetInstance|null>{
  if(!id)return null;const result=await (await database(context)).querySql('SELECT '+columns+' FROM widget_instances WHERE form_id=?',[id]);
  try{return result.goToFirstRow()?record(result):null;}finally{result.close();}
}
export async function widgetInstances(context:Context,includePreviews:boolean=false):Promise<WidgetInstance[]>{
  await importLegacyWidgets(context);const result=await (await database(context)).querySql('SELECT '+columns+" FROM widget_instances WHERE removed=0"+(includePreviews?'':" AND kind='desktop'"));
  const items:WidgetInstance[]=[];try{while(result.goToNextRow())items.push(record(result));}finally{result.close();}return items;
}
/** INSERT OR IGNORE is idempotent across processes; never rewrite an existing choice. */
export async function importLegacyWidgets(context:Context):Promise<void>{
  const db=await database(context);
  const prefs=await getLibraryPreferences(context);
  const dims=JSON.parse(await prefs.get('fridge_form_dims_json','{}') as string) as Record<string,string>;
  const bindings=JSON.parse(await prefs.get('fridge_form_bindings_json','{}') as string) as Record<string,string>;
  const raw=await prefs.get('fridge_canvases_json','') as string,catalog=readCatalog(raw);
  const followed=raw&&(JSON.parse(raw) as Record<string,Object>)['desktopFollowsSelection']===true;
  for(const id of Object.keys(dims)){
    const existing=await widgetInstance(context,id);
    if(existing){
      if(!existing.removed&&existing.kind==='legacy'){const native=await nativeWidgetDimension(id);if(native)await db.executeSql("UPDATE widget_instances SET dimension=?,kind='desktop',revision=revision+1 WHERE form_id=? AND kind='legacy' AND removed=0",[native,id]);}
      continue;
    }
    const reported=await nativeWidgetDimension(id),dimension=reported||widgetDimension(dims[id]);if(!dimension)continue;
    const canvasId=followed?catalog.activeId:(bindings[id]??catalog.activeId);
    // A bad legacy binding is retained for diagnosis, but publishers reject its size.
    await db.executeSql('INSERT OR IGNORE INTO widget_instances(form_id,dimension,canvas_id,kind) VALUES(?,?,?,?)',[id,dimension,canvasId,reported?'desktop':'legacy']);
  }
}
export async function nativeWidgetDimension(id:string):Promise<string>{
  try{return widgetDimension((await formProvider.getPublishedRunningFormInfoById(id)).dimension);}catch(_){return '';}
}
export async function registerWidget(context:Context,id:string,suppliedDimension:string,ownerId:string='',temporary:boolean=false):Promise<WidgetInstance>{
  validId(id);await importLegacyWidgets(context);const db=await database(context),existing=await widgetInstance(context,id);
  if(ownerId&&existing?.kind==='desktop'&&await nativeWidgetDimension(id))throw new Error('系统预览不能覆盖已发布的小组件');
  const owner=ownerId?await widgetInstance(context,ownerId):null;
  if(ownerId&&(!owner||owner.removed))throw new Error('被编辑的小组件已失效');
  const native=owner?'':await nativeWidgetDimension(id),dimension=owner?.dimension||native||existing?.dimension||widgetDimension(suppliedDimension);
  if(!dimension)throw new Error('系统未提供小组件尺寸，请重新打开卡片');
  if(existing?.removed)throw new Error('小组件已移除');
  const kind=ownerId||temporary?'preview':'desktop';
  await db.executeSql('INSERT OR IGNORE INTO widget_instances(form_id,dimension,canvas_id,owner_id,kind) VALUES(?,?,?,?,?)',[id,dimension,owner?.canvasId??'',ownerId,kind]);
  // Only actual native instance metadata may correct an old dimension. Missing Want data cannot.
  if(native&&existing?.dimension!==native)await db.executeSql('UPDATE widget_instances SET dimension=?, revision=revision+1 WHERE form_id=? AND removed=0 AND dimension<>?',[native,id,native]);
  if(!ownerId&&existing?.kind==='legacy'&&(native||widgetDimension(suppliedDimension)))await db.executeSql("UPDATE widget_instances SET kind='desktop',revision=revision+1 WHERE form_id=? AND kind='legacy' AND removed=0",[id]);
  if(ownerId)await db.executeSql("UPDATE widget_instances SET dimension=?,owner_id=?,kind='preview',revision=revision+1 WHERE form_id=? AND removed=0 AND (owner_id='' OR owner_id=?) AND (dimension<>? OR owner_id<>? OR kind<>'preview')",[dimension,ownerId,id,ownerId,dimension,ownerId]);
  return (await widgetInstance(context,id))!;
}
export async function promoteWidget(context:Context,id:string):Promise<void>{
  await (await database(context)).executeSql("UPDATE widget_instances SET kind='desktop',owner_id='',revision=revision+1 WHERE form_id=? AND removed=0",[id]);
}
export async function removeWidget(context:Context,id:string):Promise<void>{
  validId(id);const db=await database(context);
  // Tombstones prevent a delayed onAdd/import from resurrecting a removed preview.
  await db.executeSql("INSERT OR IGNORE INTO widget_instances(form_id,dimension,removed) VALUES(?,'',1)",[id]);
  await db.executeSql('UPDATE widget_instances SET removed=1,revision=revision+1 WHERE form_id=? AND removed=0',[id]);
}
export async function selectWidgetCanvas(context:Context,id:string,canvasId:string,dimension:string):Promise<WidgetInstance>{
  validId(id);const item=await widgetInstance(context,id);if(!item||item.removed)throw new Error('小组件已移除或尚未就绪');
  if(item.dimension!==dimension)throw new Error('小组件尺寸已变化，请重新打开设置');
  const prefs=await getLibraryPreferences(context);
  const catalog=readCatalog(await prefs.get('fridge_canvases_json','') as string);
  if(!catalog.canvases.some(c=>c.id===canvasId))throw new Error('画布已不存在');
  const json=await prefs.get(canvasKey(canvasId),'') as string;
  if(!json)throw new Error('画布读取失败，已保留原绑定');
  const state=JSON.parse(json) as FridgeState;
  if(state.canvasDimension!==item.dimension||!Array.isArray(state.cards))throw new Error('请选择相同尺寸的完整画布');
  await (await database(context)).executeSql('UPDATE widget_instances SET canvas_id=?,revision=revision+1 WHERE form_id=? AND dimension=? AND removed=0',[canvasId,id,dimension]);
  const selected=await widgetInstance(context,id);if(!selected||selected.removed||selected.canvasId!==canvasId||selected.dimension!==dimension)throw new Error('小组件配置已变化，请重试');return selected;
}
export async function detachDeletedCanvas(context:Context,canvasId:string):Promise<void>{
  // Keep the missing reference so periodic refresh retains the last good artwork, rather than silently rebinding.
  await (await database(context)).executeSql('UPDATE widget_instances SET revision=revision+1 WHERE canvas_id=? AND removed=0',[canvasId]);
}
export async function widgetGuardCurrent(guard:WidgetGuard):Promise<boolean>{
  const now=await widgetInstance(guard.context,guard.instance.id),expected=guard.instance;
  return !!now&&!now.removed&&now.revision===expected.revision&&now.dimension===expected.dimension&&now.canvasId===expected.canvasId;
}
/** A per-instance SQL lease serializes native IPC across app/form/edit processes. */
export async function acquireWidgetDelivery(guard:WidgetGuard):Promise<string>{
  const db=await database(guard.context),token=Date.now()+'_'+Math.random(),deadline=Date.now()+125000;
  while(Date.now()<deadline){
    if(!await widgetGuardCurrent(guard))return '';
    const now=Date.now();await db.executeSql('UPDATE widget_instances SET lease_token=?,lease_until=? WHERE form_id=? AND removed=0 AND revision=? AND lease_until<?',[token,now+120000,guard.instance.id,guard.instance.revision,now]);
    const result=await db.querySql('SELECT lease_token FROM widget_instances WHERE form_id=?',[guard.instance.id]);
    try{if(result.goToFirstRow()&&result.getString(0)===token)return token;}finally{result.close();}
    await new Promise<void>(resolve=>setTimeout(resolve,80));
  }
  throw new Error('小组件正在刷新，请稍后重试');
}
export async function releaseWidgetDelivery(guard:WidgetGuard,token:string):Promise<void>{
  await (await database(guard.context)).executeSql("UPDATE widget_instances SET lease_token='',lease_until=0 WHERE form_id=? AND lease_token=?",[guard.instance.id,token]);
}
