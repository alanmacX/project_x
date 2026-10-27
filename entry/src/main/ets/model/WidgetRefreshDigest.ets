import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { util } from '@kit.ArkTS';

/** A compact delivery receipt, shared across short-lived FormExtension processes. */
export function widgetRefreshDigest(value:string):string {
  const hash=cryptoFramework.createMd('SHA256');
  hash.updateSync({data:new util.TextEncoder().encodeInto(value)});
  return Array.from(hash.digestSync().data).map(byte=>byte.toString(16).padStart(2,'0')).join('');
}
