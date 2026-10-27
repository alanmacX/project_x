#!/usr/bin/env node
const {spawnSync}=require('node:child_process');
const tests=['library-storage.test.cjs','library-process-crash.test.cjs','library-backup.test.cjs','cloud-release-isolation.test.cjs'];
for(const name of tests){
 const child=spawnSync(process.execPath,['tests/'+name],{cwd:require('node:path').resolve(__dirname,'..'),stdio:'inherit',timeout:90000});
 if(child.error||child.status!==0){if(child.error)console.error(child.error.message);process.exit(child.status||1);}
}
console.log('PASS storage integrity gate: all '+tests.length+' suites passed');
