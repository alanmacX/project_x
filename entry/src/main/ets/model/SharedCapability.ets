import { CapBlock } from './CardSchema';
/** Share appearance and provider intent, never sender records or runtime snapshots.
 * Deliberate artwork (layer text, photos, HTML source/cache and album metadata) travels separately.
 * Keep this allowlist explicit so future provider fields are private by default.
 */
export function sharedCapability(cap:CapBlock):CapBlock {
  const next:CapBlock={k:cap.k,readingBlend:cap.readingBlend,readingEdge:cap.readingEdge,
    readingOutside:cap.readingOutside,readingHook:cap.readingHook,readingTint:cap.readingTint,
    readingMaterial:cap.readingMaterial,readingOpacity:cap.readingOpacity,readingStyle:cap.readingStyle};
  if(cap.k==='worldclock'){next.zone=cap.zone;next.city=cap.city;}
  if(cap.k==='calendar')next.calendarOffset=cap.calendarOffset;
  if(cap.k==='battery'){next.percent=-1;next.charging=false;}
  if(cap.k==='agenda'){next.agendaSource='system';next.events=[];}
  if(cap.k==='timetable'){next.timetableMode=cap.timetableMode;next.skipHolidays=cap.skipHolidays;next.courses=[];}
  if(cap.k==='album'){
    next.title=cap.title;next.artist=cap.artist;next.albumPresentation=cap.albumPresentation;
    next.albumInset=cap.albumInset;next.albumCover=cap.albumCover;next.albumBackground=cap.albumBackground;
    next.albumItems=cap.albumItems;next.albumRotationMinutes=cap.albumRotationMinutes;
    next.albumId=cap.albumId;next.albumRotationStart=0;next.albumSource='local';
  }
  return JSON.parse(JSON.stringify(next)) as CapBlock;
}
