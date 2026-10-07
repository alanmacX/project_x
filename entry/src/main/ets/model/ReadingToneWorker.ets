import { imageColor } from './BackgroundInputs';
@Concurrent
export async function readingToneJob(source:string):Promise<string> {return imageColor(source);}
