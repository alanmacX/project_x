import { readURL } from './URLService';
import { selectValue } from './CapabilityData';
@Concurrent
export async function readURLValue(url:string,path:string):Promise<string> {return selectValue(await readURL(url),path);}
