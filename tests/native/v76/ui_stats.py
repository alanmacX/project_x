import re,json,sys
name,pid=sys.argv[1:];st={};ui=[];slow=[]
for l in open('/tmp/'+name+'.trace',errors='replace'):
 m=re.search(r'-(\d+)\s+\(.*?\).*? (\d+\.\d+): tracing_mark_write: ([BE])(?:\|(\d+)\|(.*))?',l)
 if not m:continue
 tid,t,k,p,n=m.groups();t=float(t)
 if k=='B':st.setdefault(tid,[]).append((t,n,p))
 elif st.get(tid):
  start,n,p=st[tid].pop();ms=(t-start)*1000
  if p==pid and n.startswith('H:UIVsyncTask'):ui.append(round(ms,2))
  if p==pid and tid==pid and ms>15:slow.append({'name':n,'ms':round(ms,2)})
print(json.dumps({'name':name,'UI_frames_ms':ui,'UI_max_ms':max(ui,default=0),'main_longest':sorted(slow,key=lambda x:-x['ms'])[:12]},ensure_ascii=False))
