import re,statistics,sys,json
for name in sys.argv[1:]:
 offset=[];anims=[];taps=[]
 for l in open('/tmp/'+name+'.trace',errors='replace'):
  m=re.search(r'(\d+\.\d+): tracing_mark_write: B\|(\d+)\|H:(.*)',l)
  if not m:continue
  t=float(m[1]);n=m[3]
  now=re.search(r'UIVsyncTask\[timestamp:(\d+)\]',n)
  if now:offset.append(t-int(now[1])/1e9)
  if n.startswith('duration:380,') or n.startswith('duration:340,'):anims.append((t,int(re.search(r'duration:(\d+)',n)[1])))
  if 'pointX=2260.000000' in n and 'type=1' in n:taps.append(t)
 off=statistics.median(offset);ix={'entry':0,'exit':0};result=[]
 for start,dur in anims:
  kind='entry' if dur==380 else 'exit';i=ix[kind];ix[kind]+=1
  fps='/tmp/'+name+'-'+kind+'-'+str(i)+'.fps'
  vals=sorted(int(x)/1e9+off for x in re.findall(r'^\d{12,20}$',open(fps).read(),re.M));vals=[x for x in vals if start<=x<=start+dur/1000];ds=[(b-a)*1000 for a,b in zip(vals,vals[1:])]
  result.append({'kind':kind,'sample':i,'frames':len(vals),'fps':round(1000/statistics.mean(ds),1) if ds else 0,'maxInterval_ms':round(max(ds,default=0),2),'intervalsOver12_5ms':sum(x>12.5 for x in ds),'touchToAnimation_ms':round((start-max([x for x in taps if x<start]))*1000,1) if kind=='entry' else None})
 print(name,json.dumps(result))
