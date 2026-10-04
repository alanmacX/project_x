import sys,re,statistics,json
path=sys.argv[1]; stacks={};slices=[];offsets=[]
for l in open(path,errors='replace'):
 m=re.search(r'-(\d+)\s+\(.*?\).*? (\d+\.\d+): tracing_mark_write: ([BE])(?:\|(\d+)\|(.*))?',l)
 if not m:continue
 tid,t,k,p,n=m.groups();t=float(t)
 if k=='B':
  stacks.setdefault(tid,[]).append((t,n,p))
  now=re.search(r'UIVsyncTask\[timestamp:(\d+)\]',n or '')
  if now:offsets.append(t-int(now[1])/1e9)
 elif stacks.get(tid):
  start,n,p=stacks[tid].pop();slices.append((start,t,n,p,tid))
anim=[v for v in slices if v[2] and re.match(r'H:duration:(380|340),',v[2])]
print('ANIMATIONS',[(round(v[0],3),v[2].split(',')[0],round((v[1]-v[0])*1000,2)) for v in anim]);out=[]
for a in anim:
 start,end=a[0],a[1]+int(re.search(r'duration:(\d+)',a[2])[1])/1000
 ui=[(v[1]-v[0])*1000 for v in slices if v[3]==a[3] and v[2].startswith('H:UIVsyncTask') and start-.12<=v[0]<=end+.10]
 rs=[(v[1]-v[0])*1000 for v in slices if v[2].startswith('H:RSMainThread::MainLoop') and start<=v[0]<=end]
 out.append({'start':round(start,3),'duration':a[2].split(',')[0],'UI_ms':{'count':len(ui),'max':round(max(ui,default=0),2),'over8.33':sum(x>8.34 for x in ui)},'RS_ms':rs})
print(json.dumps(out,indent=2));pid=anim[0][3] if anim else ''
slow=sorted([((v[1]-v[0])*1000,v[2][:145]) for v in slices if v[3]==pid],reverse=True)[:12]
print('SLOW',slow)
if offsets:print('CLOCK_OFFSET',statistics.median(offsets))
