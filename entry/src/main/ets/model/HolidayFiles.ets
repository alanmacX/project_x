import { i18n } from '@kit.LocalizationKit';
import { fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { holidayFileDates } from './HolidayCalendar';
/** Native HolidayManager parses names; explicit all-day ranges preserve exclusive DTEND. */
@Concurrent
export async function importHolidayFile(uri:string,cacheDir:string):Promise<string> {
  const input=await fileIo.open(uri,fileIo.OpenMode.READ_ONLY),path=cacheDir+'/holiday_'+Date.now()+'_'+Math.floor(Math.random()*1000000)+'.ics';
  try {
    const size=(await fileIo.stat(input.fd)).size;if(size<=0||size>1048576)throw new Error('日历文件须小于 1 MB');
    const buffer=new ArrayBuffer(size),length=await fileIo.read(input.fd,buffer);
    const text=new util.TextDecoder('utf-8').decodeWithStream(new Uint8Array(buffer,0,length));
    const days=holidayFileDates(text),file=await fileIo.open(path,fileIo.OpenMode.CREATE|fileIo.OpenMode.READ_WRITE|fileIo.OpenMode.TRUNC);
    try{await fileIo.write(file.fd,text);}finally{fileIo.closeSync(file.fd);}
    const manager=new i18n.HolidayManager(path);
    const years=Array.from(new Set(days.map((d)=>Number(d.date.slice(0,4)))));
    for(const year of years)for(const info of manager.getHolidayInfoItemArray(year)) {
      const key=info.year+'-'+('0'+info.month).slice(-2)+'-'+('0'+info.day).slice(-2),day=days.find((d)=>d.date===key);
      if(day&&info.baseName)day.name=info.baseName.slice(0,60);
    }
    return JSON.stringify(days);
  } finally {fileIo.closeSync(input.fd);try{await fileIo.unlink(path);}catch(_){} }
}
