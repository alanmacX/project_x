export const COMPOSITION_KEYS:string[]=['cloud','bare','badge','sticker','tag'];
export function readingStyles(kind:string):string[] {
 if(kind==='album')return [];
 return kind==='battery'?['badge','cloud','bare','tag','sticker']:['cloud','bare','tag','sticker'];
}
export function defaultReadingStyle(kind:string):string {
 if(kind==='battery')return 'badge';if(kind==='agenda'||kind==='timetable'||kind==='countdown'||kind==='anniversary'||kind.endsWith('progress'))return 'tag';
 return kind==='clock'?'bare':'sticker';
}
export function validReadingStyle(kind:string,style:string):string {
 const migrated=style==='dock'?'tag':style==='space'?'sticker':style;
 return readingStyles(kind).includes(migrated)?migrated:defaultReadingStyle(kind);
}

/** Newly chosen capabilities use cloud; legacy defaults stay stable during migration. */
export function preferredReadingStyle(kind:string):string {return kind==='battery'?'badge':kind==='album'?'':'cloud';}
