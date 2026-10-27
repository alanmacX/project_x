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
  constructor(db:relationalStore.RdbStore){this.db=db;}
  async get(key:string,fallback:nativePreferences.ValueType):Promise<nativePreferences.ValueType>{
    if(this.writes.has(key)){const value=this.writes.get(key);return value===null||value===undefined?fallback:JSON.parse(value) as nativePreferences.ValueType;}
    const result=await this.db.querySql('SELECT value FROM library_values WHERE key=?',[key]);
    try{return result.goToFirstRow()?JSON.parse(result.getString(0)) as nativePreferences.ValueType:fallback;}finally{result.close();}
  }
  async put(key:string,value:nativePreferences.ValueType):Promise<void>{this.writes.set(key,JSON.stringify(value));}
  async delete(key:string):Promise<void>{this.writes.set(key,null);}
  async flush():Promise<void>{
    const batch=this.writes;this.writes=new Map();
    try{
      const transaction=await this.db.createTransaction();
      try{for(const key of batch.keys()){const value=batch.get(key);
        if(key==='fridge_canvases_json'||key.startsWith('fridge_canvas_'))await transaction.execute('INSERT OR REPLACE INTO library_recovery(key,value) SELECT key,value FROM library_values WHERE key=?',[key]);
        if(value===null)await transaction.execute('DELETE FROM library_values WHERE key=?',[key]);
        else await transaction.execute('INSERT OR REPLACE INTO library_values(key,value) VALUES(?,?)',[key,value]);
      }await transaction.commit();}catch(e){await transaction.rollback();throw e as Error;}
    }catch(e){for(const key of batch.keys())if(!this.writes.has(key))this.writes.set(key,batch.get(key)??null);throw e as Error;}
  }
}
const connections:Map<string,Promise<relationalStore.RdbStore>>=new Map();
async function libraryDatabase(context:Context):Promise<relationalStore.RdbStore>{
  const key=context.databaseDir;let pending=connections.get(key);
  if(!pending){pending=(async()=>{
    const db=await relationalStore.getRdbStore(context,{name:'canvas_library_v1.db',securityLevel:relationalStore.SecurityLevel.S1});
    await db.executeSql('CREATE TABLE IF NOT EXISTS library_values(key TEXT PRIMARY KEY,value TEXT NOT NULL)');
    await db.executeSql('CREATE TABLE IF NOT EXISTS library_recovery(key TEXT PRIMARY KEY,value TEXT NOT NULL)');
    const result=await db.querySql("SELECT value FROM library_values WHERE key='__migrated_v1'");let migrated=false;try{migrated=result.goToFirstRow();}finally{result.close();}
    if(!migrated){
      // Missing/corrupt legacy XML is not an empty new library. Never initialize over it.
      const broken=context.preferencesDir+'/fridge_store.broken';
      if(fileIo.accessSync(broken))throw new Error('检测到本地存储损坏，已停止写入并保留原文件');
      const legacy=await nativePreferences.getPreferences(context,'fridge_store');
      const values=await legacy.getAll() as Record<string,nativePreferences.ValueType>;
      const catalog=values['fridge_canvases_json'];
      if(catalog){const parsed=JSON.parse(catalog as string) as Record<string,Object>;
        if(!Array.isArray(parsed['canvases']))throw new Error('画布目录损坏，已停止迁移');
        const entries=parsed['canvases'] as Record<string,Object>[];
        for(const entry of entries){const source=values['fridge_canvas_'+entry['id']];if(!source||!Array.isArray((JSON.parse(source as string) as Record<string,Object>)['cards']))throw new Error('画布记录缺失，已停止迁移');}
      }
      const transaction=await db.createTransaction();
      try{
        // Recheck under the write transaction: a second process must not reimport stale XML.
        const check=await transaction.querySql("SELECT value FROM library_values WHERE key='__migrated_v1'");let done=false;try{done=check.goToFirstRow();}finally{check.close();}
        if(!done){for(const k of Object.keys(values))await transaction.execute('INSERT OR IGNORE INTO library_values(key,value) VALUES(?,?)',[k,JSON.stringify(values[k])]);
          await transaction.execute("INSERT INTO library_values(key,value) VALUES('__migrated_v1','true')");}
        await transaction.commit();
      }catch(e){await transaction.rollback();throw e as Error;}
    }
    return db;
  })();connections.set(key,pending);pending.catch(()=>connections.delete(key));}
  return pending;
}
export async function getLibraryPreferences(context:Context):Promise<LibraryPreferences>{return new LibrarySession(await libraryDatabase(context));}
