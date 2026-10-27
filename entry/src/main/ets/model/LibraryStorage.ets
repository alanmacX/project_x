import { artworkKey, validateLibraryValues, validateCanvas } from './LibraryValidation';
import { queueLibraryBackup } from './LibraryBackup';
import { relationalStore } from '@kit.ArkData';
import nativePreferences from '@ohos.data.preferences';
import { fileIo } from '@kit.CoreFileKit';

/** Artwork lives in transactional rows, not a process-local XML preferences snapshot. */
export interface LibraryPreferences {
  get(key:string,fallback:nativePreferences.ValueType):Promise<nativePreferences.ValueType>;
  put(key:string,value:nativePreferences.ValueType):Promise<void>;
  delete(key:string):Promise<void>;
  flush():Promise<void>;
}
class LibrarySession implements LibraryPreferences {
  private db:relationalStore.RdbStore;
  private writes:Map<string,string|null>=new Map();
  private observed:Map<string,string|null>=new Map();
  private backupDir:string;
  private flushing:Promise<void>=Promise.resolve();
  constructor(db:relationalStore.RdbStore,backupDir:string){this.db=db;this.backupDir=backupDir;}
  async get(key:string,fallback:nativePreferences.ValueType):Promise<nativePreferences.ValueType>{
    if(this.writes.has(key)){const value=this.writes.get(key);return value===null||value===undefined?fallback:JSON.parse(value) as nativePreferences.ValueType;}
    const result=await this.db.querySql('SELECT value FROM library_values WHERE key=?',[key]);
    try{const raw=result.goToFirstRow()?result.getString(0):null;if(!this.observed.has(key))this.observed.set(key,raw);return raw===null?fallback:JSON.parse(raw) as nativePreferences.ValueType;}finally{result.close();}
  }
  async put(key:string,value:nativePreferences.ValueType):Promise<void>{if(artworkKey(key)&&!this.observed.has(key))await this.get(key,'');this.writes.set(key,JSON.stringify(value));}
  async delete(key:string):Promise<void>{if(artworkKey(key)&&!this.observed.has(key))await this.get(key,'');this.writes.set(key,null);}
  flush():Promise<void>{
    const pending=this.flushing.catch(()=>{}).then(()=>this.commit());this.flushing=pending;return pending;
  }
  private async commit():Promise<void>{
    const batch=this.writes;this.writes=new Map();
    if(batch.size===0)return;
    let changedArtwork=false;
    try{
      const transaction=await this.db.createTransaction();
      try{
        changedArtwork=Array.from(batch.keys()).some(key=>artworkKey(key));
        for(const key of batch.keys())if(artworkKey(key)){
          const current=await transaction.querySql('SELECT value FROM library_values WHERE key=?',[key]);let raw:string|null=null;
          try{if(current.goToFirstRow())raw=current.getString(0);}finally{current.close();}
          if(raw!==(this.observed.get(key)??null))throw new Error('画布已由其他操作更新，已停止覆盖，请重新打开画布');
        }
        for(const key of batch.keys()){const value=batch.get(key);
        if(key==='fridge_canvases_json'||key.startsWith('fridge_canvas_'))await transaction.execute('INSERT OR REPLACE INTO library_recovery(key,value) SELECT key,value FROM library_values WHERE key=?',[key]);
        if(value===null)await transaction.execute('DELETE FROM library_values WHERE key=?',[key]);
        else await transaction.execute('INSERT OR REPLACE INTO library_values(key,value) VALUES(?,?)',[key,value]);
      }
        if(changedArtwork){
          for(const key of batch.keys())if(key==='fridge_state_json'||key.startsWith('fridge_canvas_')&&key!=='fridge_canvas_specs_json'){
            const raw=batch.get(key);if(raw!==null&&raw!==undefined)validateCanvas(JSON.parse(raw) as string,key==='fridge_state_json'?'':key.slice('fridge_canvas_'.length));
          }
          // Directory changes/deletions must retain every referenced document in the same commit.
          if(batch.has('fridge_canvases_json')||Array.from(batch.keys()).some(key=>artworkKey(key)&&batch.get(key)===null)){
            const records=await transaction.querySql('SELECT key,value FROM library_values');const values:Record<string,string>={};
            try{while(records.goToNextRow()){const key=records.getString(0);if(artworkKey(key))values[key]=JSON.parse(records.getString(1)) as string;}}finally{records.close();}
            validateLibraryValues(values);
          }
          const counter=await transaction.querySql("SELECT value FROM library_values WHERE key='__commit_sequence'");let sequence=0;
          try{if(counter.goToFirstRow())sequence=JSON.parse(counter.getString(0)) as number;}finally{counter.close();}
          await transaction.execute("INSERT OR REPLACE INTO library_values(key,value) VALUES('__commit_sequence',?)",[JSON.stringify(sequence+1)]);
        }
        await transaction.commit();
        for(const key of batch.keys())this.observed.set(key,batch.get(key)??null);}catch(e){await transaction.rollback();throw e as Error;}
    }catch(e){
      for(const key of batch.keys())if(!this.writes.has(key))this.writes.set(key,batch.get(key)??null);
      if((e as Error).message.includes('其他操作更新')){
        try{await preserveDraft(this.db,batch);}catch(_){throw new Error((e as Error).message+'；恢复草稿写入失败，请立即导出当前画布');}
        throw new Error((e as Error).message+'；当前改动已另存冲突草稿');
      }
      throw e as Error;
    }
    if(changedArtwork)queueLibraryBackup(this.db,this.backupDir);
  }
}
/** Conflict is not permission to discard the user's pending edit. Keep detached drafts. */
async function preserveDraft(db:relationalStore.RdbStore,batch:Map<string,string|null>):Promise<void>{
  const keys=Array.from(batch.keys()).filter(key=>artworkKey(key)).sort(),scope=keys.join('|'),values:Record<string,string|null>={};
  keys.forEach(key=>values[key]=batch.get(key)??null);const payload=JSON.stringify(values);
  const transaction=await db.createTransaction();
  try{
    const rows=await transaction.querySql('SELECT payload FROM library_drafts WHERE scope=? ORDER BY id DESC LIMIT 1',[scope]);let previous='';
    try{if(rows.goToFirstRow())previous=rows.getString(0);}finally{rows.close();}
    if(previous!==payload){await transaction.execute('INSERT INTO library_drafts(scope,payload,created_at) VALUES(?,?,?)',[scope,payload,Date.now()]);
      await transaction.execute('DELETE FROM library_drafts WHERE scope=? AND id NOT IN (SELECT id FROM library_drafts WHERE scope=? ORDER BY id DESC LIMIT 3)',[scope,scope]);}
    await transaction.commit();
  }catch(e){await transaction.rollback();throw e as Error;}
}
const connections:Map<string,Promise<relationalStore.RdbStore>>=new Map();
async function libraryDatabase(context:Context):Promise<relationalStore.RdbStore>{
  const key=context.databaseDir;let pending=connections.get(key);
  if(!pending){pending=(async()=>{
    const db=await relationalStore.getRdbStore(context,{name:'canvas_library_v1.db',securityLevel:relationalStore.SecurityLevel.S1});
    await db.executeSql('CREATE TABLE IF NOT EXISTS library_values(key TEXT PRIMARY KEY,value TEXT NOT NULL)');
    await db.executeSql('CREATE TABLE IF NOT EXISTS library_recovery(key TEXT PRIMARY KEY,value TEXT NOT NULL)');
    await db.executeSql('CREATE TABLE IF NOT EXISTS library_drafts(id INTEGER PRIMARY KEY AUTOINCREMENT,scope TEXT NOT NULL,payload TEXT NOT NULL,created_at INTEGER NOT NULL)');
    const result=await db.querySql("SELECT value FROM library_values WHERE key='__migrated_v1'");let migrated=false;try{migrated=result.goToFirstRow();}finally{result.close();}
    if(!migrated){
      // Missing/corrupt legacy XML is not an empty new library. Never initialize over it.
      const broken=context.preferencesDir+'/fridge_store.broken';
      if(fileIo.accessSync(broken))throw new Error('检测到本地存储损坏，已停止写入并保留原文件');
      const legacy=await nativePreferences.getPreferences(context,'fridge_store');
      const values=await legacy.getAll() as Record<string,nativePreferences.ValueType>;
      const artwork:Record<string,string>={};for(const k of Object.keys(values))if(artworkKey(k))artwork[k]=values[k] as string;
      validateLibraryValues(artwork);
      const transaction=await db.createTransaction();
      try{
        // Recheck under the write transaction: a second process must not reimport stale XML.
        const check=await transaction.querySql("SELECT value FROM library_values WHERE key='__migrated_v1'");let done=false;try{done=check.goToFirstRow();}finally{check.close();}
        if(!done){for(const k of Object.keys(values))await transaction.execute('INSERT OR IGNORE INTO library_values(key,value) VALUES(?,?)',[k,JSON.stringify(values[k])]);
          await transaction.execute("INSERT INTO library_values(key,value) VALUES('__migrated_v1','true')");}
        await transaction.commit();
      }catch(e){await transaction.rollback();throw e as Error;}
    }
    const records=await db.querySql('SELECT key,value FROM library_values');const persisted:Record<string,string>={};let commits=0;
    try{while(records.goToNextRow()){
      const k=records.getString(0),raw=records.getString(1);if(k==='__commit_sequence')commits=JSON.parse(raw) as number;
      else if(artworkKey(k))persisted[k]=JSON.parse(raw) as string;
    }}finally{records.close();}
    if(commits>0&&!persisted['fridge_canvases_json']&&!persisted['fridge_state_json'])throw new Error('已有画布目录缺失，已停止初始化');
    validateLibraryValues(persisted);
    return db;
  })();connections.set(key,pending);pending.catch(()=>connections.delete(key));}
  return pending;
}
export async function getLibraryPreferences(context:Context):Promise<LibraryPreferences>{const db=await libraryDatabase(context);return new LibrarySession(db,context.filesDir+'/library-recovery');}
