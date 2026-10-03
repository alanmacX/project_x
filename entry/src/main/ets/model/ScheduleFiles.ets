import { i18n } from '@kit.LocalizationKit';
import { fileIo } from '@kit.CoreFileKit';
import { importAgenda, importCourses } from './ScheduleImport';
import { util } from '@kit.ArkTS';
@Concurrent
export async function importScheduleFile(uri:string,kind:string):Promise<string> {
  const file=await fileIo.open(uri,fileIo.OpenMode.READ_ONLY);
  try {const stat=await fileIo.stat(file.fd);if(stat.size>1048576)throw new Error('文件超过 1 MB');
    const buffer=new ArrayBuffer(stat.size),length=await fileIo.read(file.fd,buffer);
    const text=new util.TextDecoder('utf-8').decodeWithStream(new Uint8Array(buffer,0,length));
    return JSON.stringify(kind==='agenda'?importAgenda(text,Date.now(),(zone:string,time:number):number=>i18n.getTimeZone(zone).getOffset(time)):importCourses(text));
  } finally {fileIo.closeSync(file.fd);}
}
