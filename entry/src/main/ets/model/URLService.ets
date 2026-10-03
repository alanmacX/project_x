import { http } from '@kit.NetworkKit';
import { validSourceURL,selectValue } from './CapabilityData';
export async function readURL(url: string): Promise<string> {
  if(!validSourceURL(url))throw new Error('请输入 HTTP 或 HTTPS 地址');
  const client=http.createHttp();
  try { const response=await client.request(url,{method:http.RequestMethod.GET,expectDataType:http.HttpDataType.STRING,connectTimeout:6000,readTimeout:8000,maxLimit:262144,usingCache:false});
    if(response.responseCode<200||response.responseCode>=300)throw new Error('接口返回 '+response.responseCode);
    return response.result as string;
  } finally {client.destroy();}
}
