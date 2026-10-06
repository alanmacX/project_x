import re,statistics,json,sys
name=sys.argv[1] if len(sys.argv)>1 else 'v64-launch'
log=open('/tmp/'+name+'.log',errors='replace').read();pids=re.findall(r'\s(\d+)\s+\d+ I .*FridgeStartup: ability',log);pid=pids[-1] if pids else re.findall(r'ridgewidget.app-(\d+)',open('/tmp/'+name+'.trace',errors='replace').read())[0]
st={};frames=[];slow=[];offset=[];anim=[]
for l in open('/tmp/'+name+'.trace',errors='replace'):
 m=re.search(r'-(\d+)\s+\(.*?\).*? (\d+\.\d+): tracing_mark_write: ([BE])(?:\|(\d+)\|(.*))?',l)
 if not m:continue
 tid,t,k,p,n=m.groups();t=float(t)
 if k=='B':
  st.setdefault(tid,[]).append((t,n,p))
  if p==pid:
   now=re.search(r'UIVsyncTask\[timestamp:(\d+)\]\[vsyncID:.*?\[instanceID:',n)
   if now:offset.append(t-int(now[1])/1e9)
   if n.startswith('H:duration:520,'):anim.append(t)
 elif st.get(tid):
  a,n,p=st[tid].pop()
  if p==pid:
   if n.startswith('H:UIVsyncTask[') and '[instanceID:' in n:frames.append({'start':a,'ms':round((t-a)*1000,2)})
   if t-a>.015:slow.append({'start':a,'ms':round((t-a)*1000,2),'task':n[:140]})
out={'pid':pid,'UI_frames':frames,'slow_tasks':sorted(slow,key=lambda x:-x['ms'])[:20],'startup_marks':[x for x in log.splitlines() if 'FridgeStartup' in x and ' '+pid+' ' in x]}
if anim and offset:
 off=statistics.median(offset);vs=sorted(set(int(x)/1e9+off for x in re.findall(r'^\d{12,20}$',open('/tmp/'+name+'.fps').read(),re.M)))
 vals=[x for x in vs if anim[0]<=x<=anim[0]+.520];ds=[(b-a)*1000 for a,b in zip(vals,vals[1:])]
 out['arrival']={'frames':len(vals),'fps':round(1000/statistics.mean(ds),1) if ds else 0,'max_ms':round(max(ds,default=0),2),'UI_max_ms':max((f['ms'] for f in frames if anim[0]<=f['start']<=anim[0]+.52),default=0)}
print(json.dumps(out,indent=2))
