import { imageSwatches } from './BackgroundInputs';
import { micaStudyTint } from './MicaMaterialStudy';
@Concurrent
export async function sampleMicaStudyTint(src:string):Promise<string> {return micaStudyTint(await imageSwatches(src));}
