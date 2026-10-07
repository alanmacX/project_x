export const COMPOSITION_KEYS:string[]=['bare','badge','sticker','space','tag','dock'];
export function readingStyles(kind:string):string[] {
 if(kind==='album')return [];
 if(kind==='battery')return ['badge','tag','dock'];
 if(kind==='calendar')return ['sticker','space'];
 if(kind==='worldclock'||kind==='lunar')return ['sticker','space','tag','dock'];
 return ['bare','sticker','space','tag','dock'];
}
export function defaultReadingStyle(kind:string):string {
 if(kind==='battery')return 'badge';if(kind==='worldclock'||kind==='lunar')return 'space';
 if(kind==='agenda'||kind==='timetable')return 'dock';if(kind==='calendar'||kind==='date')return 'sticker';
 if(kind==='countdown'||kind==='anniversary'||kind.endsWith('progress'))return 'tag';return 'bare';
}
export function validReadingStyle(kind:string,style:string):string {return readingStyles(kind).includes(style)?style:defaultReadingStyle(kind);}
