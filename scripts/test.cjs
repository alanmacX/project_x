#!/usr/bin/env node
const fs=require('node:fs'),path=require('node:path'),{spawn}=require('node:child_process');
const root=path.resolve(__dirname,'..'),files=fs.readdirSync(path.join(root,'tests')).filter(name=>name.endsWith('.test.cjs')).sort();
let next=0,passed=0;const failures=[];
function run(name){return new Promise(resolve=>{
  const child=spawn(process.execPath,[path.join('tests',name)],{cwd:root,stdio:['ignore','pipe','pipe']}),chunks=[];
  child.stdout.on('data',chunk=>chunks.push(chunk));child.stderr.on('data',chunk=>chunks.push(chunk));
  child.on('error',error=>chunks.push(Buffer.from(error.message)));
  child.on('close',code=>{if(code===0){passed++;process.stdout.write('.');}else failures.push({name,output:Buffer.concat(chunks).toString()});resolve();});
});}
async function worker(){while(next<files.length)await run(files[next++]);}
Promise.all(Array.from({length:3},worker)).then(()=>{
 process.stdout.write('\n');for(const failure of failures)console.error('\nFAIL '+failure.name+'\n'+failure.output);
 console.log(passed+'/'+files.length+' suites passed');if(failures.length)process.exitCode=1;
}).catch(error=>{console.error(error);process.exitCode=1;});
