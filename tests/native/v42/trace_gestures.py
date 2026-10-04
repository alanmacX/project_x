import re,sys,statistics,json
for name,pid in zip(sys.argv[1::2],sys.argv[2::2]):
 st={};ui=[];offset=[];windows=[];begin=None
 for l in open('/tmp/'+name+'.trace',errors='replace'):
  m=re.search(r'-(\d+)\s+\(.*?\).*? (\d+\.\d+): tracing_mark_write: ([BE])(?:\|(\d+)\|(.*))?',l)
  if not m:continue
  tid,t,k,p,n=m.groups();t=float(t)
  if k=='B':
   st.setdefault(tid,[]).append((t,n,p))
   if p==pid:
    now=re.search(r'UIVsyncTask\[timestamp:(\d+)\]',n)
    if now:offset.append(t-int(now[1])/1e9)
    if n.startswith('H:PanRecognizer onActionStart'):begin=t
    if n.startswith('H:PanRecognizer onActionEnd') and begin is not None:windows.append((begin,t));begin=None
  elif st.get(tid):
   start,n,p=st[tid].pop()
   if p==pid and n.startswith('H:UIVsyncTask'):ui.append((start,(t-start)*1000))
 off=statistics.median(offset);result=[]
 for i,(a,b) in enumerate(windows):
  vals=sorted(int(x)/1e9+off for x in re.findall(r'^\d{12,20}$',open('/tmp/'+name+'-'+str(i)+'.fps').read(),re.M));vals=[x for x in vals if a<=x<=b];ds=[(y-x)*1000 for x,y in zip(vals,vals[1:])];cost=[v for t,v in ui if a<=t<=b]
  result.append({'sample':i,'duration_ms':round((b-a)*1000),'screenFps':round(1000/statistics.mean(ds),1) if ds else 0,'UI_p95_ms':round(sorted(cost)[int(len(cost)*.95)],2) if cost else 0,'UI_max_ms':round(max(cost,default=0),2)})
 print(name,json.dumps(result))
