import { formProvider } from '@kit.FormKit';
import preferences from '@ohos.data.preferences';
import { FridgeState } from './CardSchema';
import { nextSceneBoundary } from './SceneSchedule';
import { nextDataBoundary } from './CapabilityData';

/** A boundary changes visible content; static artwork never spends timer quota. */
export function widgetBoundary(state:FridgeState,now:number):number {
  let next=nextSceneBoundary(state,now);
  for(const card of state.cards) {
    const cap=card.capability;if(!cap)continue;
    if(['album','worldclock','lunar','timetable','agenda'].includes(cap.k)) {
      let candidate=nextDataBoundary(cap,now);
      if(cap.k==='agenda'&&candidate===now+30*60000)candidate=Math.floor(now/(30*60000))*30*60000+30*60000;
      next=Math.min(next,candidate);
    }
    else if(['battery','dayprogress','yearprogress'].includes(cap.k))next=Math.min(next,Math.floor(now/(30*60000))*30*60000+30*60000);
    else if(['date','calendar','countdown','anniversary'].includes(cap.k)) {const midnight=new Date(now);midnight.setHours(24,0,0,0);next=Math.min(next,midnight.getTime());}
  }
  return next;
}
const requests:Map<string,Promise<void>>=new Map();
/** Share acknowledgement across App/FormExtension. Edits must not postpone an already
 * requested boundary; the persisted timestamp also deduplicates process restarts. */
export async function scheduleWidget(prefs:preferences.Preferences,formId:string,deadline:number,now:number=Date.now()):Promise<void> {
  const pending=(requests.get(formId)??Promise.resolve()).catch(()=>{}).then(async()=>{
    if(!Number.isFinite(deadline)||deadline<=now||deadline-now>=60*60000)return;
    const key='fridge_next_refresh_'+formId;
    const previous=await prefs.get(key,0) as number;
    const minutes=Math.max(5,Math.ceil((deadline-now)/60000));
    const requestedAt=now+minutes*60000;
    // Persist the actual requested wake-up, including the system's minimum delay.
    // Later edits reuse an earlier pending request rather than spending quota and
    // resetting the timer before that wake-up has happened.
    if(previous>now&&previous<=requestedAt)return;
    try {await formProvider.setFormNextRefreshTime(formId,minutes);await prefs.put(key,requestedAt);await prefs.flush();}catch(_){ /* The hourly fallback survives rejected/quota-limited requests. */ }
  });
  requests.set(formId,pending);
  try{await pending;}finally{if(requests.get(formId)===pending)requests.delete(formId);}
}
