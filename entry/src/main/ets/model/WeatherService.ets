import http from '@ohos.net.http';
import { hilog } from '@kit.PerformanceAnalysisKit';

/**
 * WeatherService —— 天气卡的真实数据源（open-meteo，免 API key）
 *
 * 链路：城市名 -> open-meteo geocoding 拿经纬度 -> forecast 拿当前温度/天气码
 * -> WMO 天气码映射为中文描述。
 * App 与 FormExtensionAbility 均可请求真实数据，结果写回卡片。
 */

const TAG: string = 'WeatherService';
const cityPositions = new Map<string, number[]>();
const activeRequests = new Map<string, Promise<WeatherData | null>>();

export class WeatherData {
  temp: string = '';
  desc: string = '';
  city: string = '';
}

/** WMO weather code -> 中文描述 */
function wmoDesc(code: number): string {
  if (code === 0) return '晴';
  if (code === 1 || code === 2) return '多云';
  if (code === 3) return '阴';
  if (code === 45 || code === 48) return '雾';
  if (code >= 51 && code <= 57) return '毛毛雨';
  if (code >= 61 && code <= 67) return '雨';
  if (code >= 71 && code <= 77) return '雪';
  if (code >= 80 && code <= 82) return '阵雨';
  if (code === 85 || code === 86) return '阵雪';
  if (code >= 95) return '雷雨';
  return '未知';
}

async function getJson(url: string): Promise<Record<string, Object> | null> {
  const client = http.createHttp();
  try {
    const resp = await client.request(url, {
      method: http.RequestMethod.GET,
      connectTimeout: 8000,
      readTimeout: 8000,
      expectDataType: http.HttpDataType.OBJECT
    });
    if (resp.responseCode >= 200 && resp.responseCode < 300) {
      return resp.result as Record<string, Object>;
    }
    hilog.error(0x0000, TAG, 'http %{public}d %{public}s', resp.responseCode, url);
    return null;
  } catch (e) {
    hilog.error(0x0000, TAG, 'http error %{public}s', (e as Error).message);
    return null;
  } finally {
    client.destroy();
  }
}

/** 城市名 -> 经纬度（open-meteo geocoding，中文可用） */
async function geocode(city: string): Promise<number[] | null> {
  const cached = cityPositions.get(city); if (cached !== undefined) return cached;
  const url = 'https://geocoding-api.open-meteo.com/v1/search?name=' + encodeURIComponent(city) +
    '&count=1&language=zh&format=json';
  const data = await getJson(url);
  if (data === null) return null;
  const results = data['results'] as Array<Record<string, Object>>;
  if (results === undefined || results.length === 0) return null;
  const first = results[0];
  const lat = first['latitude'] as number;
  const lon = first['longitude'] as number;
  if (typeof lat !== 'number' || typeof lon !== 'number') return null;
  if (cityPositions.size > 64) cityPositions.clear();
  const pos = [lat, lon]; cityPositions.set(city, pos); return pos;
}

/** 拉取某城市当前天气；失败返回 null（调用方保留旧值） */
export async function fetchWeather(city: string): Promise<WeatherData | null> {
  const key = city.trim(); if (key.length === 0) return null;
  const running = activeRequests.get(key); if (running !== undefined) return running;
  const request = requestWeather(key); activeRequests.set(key, request);
  try { return await request; } finally { if (activeRequests.get(key) === request) activeRequests.delete(key); }
}
async function requestWeather(city: string): Promise<WeatherData | null> {
  if (!city || city.trim().length === 0) return null;
  try {
    const pos = await geocode(city.trim());
    if (pos === null) {
      hilog.warn(0x0000, TAG, 'geocode no result: %{public}s', city);
      return null;
    }
    const url = 'https://api.open-meteo.com/v1/forecast?latitude=' + pos[0] + '&longitude=' + pos[1] +
      '&current=temperature_2m,weather_code&timezone=auto';
    const data = await getJson(url);
    if (data === null) return null;
    const current = data['current'] as Record<string, Object>;
    if (current === undefined) return null;
    const t = current['temperature_2m'] as number;
    const code = current['weather_code'] as number;
    if (typeof t !== 'number' || typeof code !== 'number') return null;
    const wmo = wmoDesc(code);
    const out: WeatherData = new WeatherData();
    out.temp = Math.round(t) + '°';
    out.desc = wmo;
    out.city = city.trim();
    return out;
  } catch (e) {
    hilog.error(0x0000, TAG, 'fetchWeather %{public}s', (e as Error).message);
    return null;
  }
}
