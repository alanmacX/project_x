export const COMPOSITION_KEYS:string[]=['bare','badge','sticker','tag'];
export function readingStyles(kind:string):string[] {
 if(kind==='album')return [];
 return kind==='battery'?['badge','bare','tag','sticker']:['bare','tag','sticker'];
}
export function defaultReadingStyle(kind:string):string {
 if(kind==='battery')return 'badge';if(kind==='agenda'||kind==='timetable'||kind==='countdown'||kind==='anniversary'||kind.endsWith('progress'))return 'tag';
 return kind==='clock'?'bare':'sticker';
}
export function validReadingStyle(kind:string,style:string):string {
 const migrated=style==='dock'?'tag':style==='space'?'sticker':style;
 return readingStyles(kind).includes(migrated)?migrated:defaultReadingStyle(kind);
}
