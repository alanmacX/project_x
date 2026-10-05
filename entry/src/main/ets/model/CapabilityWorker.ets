import { readURL } from './URLService';
import { valueFields } from './CapabilityData';
@Concurrent
export async function fetchValueFields(url:string):Promise<string> { return JSON.stringify(valueFields(await readURL(url))); }
