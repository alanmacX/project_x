// Execute production SQL against SQLite, instead of emulating its semantics.
const {DatabaseSync}=require('node:sqlite');
function createWidgetRdb(){
 const db=new DatabaseSync(':memory:');
 const store={executeSql:async(sql,args=[])=>{db.prepare(sql).run(...args);},querySql:async(sql,args=[])=>{
  const rows=db.prepare(sql).all(...args);let index=-1;
  return {goToFirstRow(){index=0;return rows.length>0;},goToNextRow(){return ++index<rows.length;},getString(column){return String(Object.values(rows[index])[column]??'');},getLong(column){return Number(Object.values(rows[index])[column]);},close(){}};
 }};
 return {relationalStore:{SecurityLevel:{S1:1},getRdbStore:async()=>store},store,db,reset(){db.exec('DELETE FROM widget_instances');}};
}
module.exports={createWidgetRdb};
