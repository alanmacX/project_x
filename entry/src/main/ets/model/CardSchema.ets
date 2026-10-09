import { HtmlCardTemplate, normalizeHtmlCard } from './HtmlCardTemplate';
import { COMPOSITION_KEYS, validReadingStyle, defaultReadingStyle } from './ReadingStylePolicy';
import { SceneRule, SavedSceneLayout, normalizeSceneLayouts, normalizeSceneRules } from './SceneScheduleSchema';
import { clockZone } from './TimeCapabilities';
import { validDay, HolidayDate } from './HolidayCalendar';
/** Pure, versioned schema shared by the app and FormKit renderer. */
export const BOARD_W: number = 344;
export const BOARD_H: number = 470;
/** Artwork bounds only; capability readability is enforced separately by layout. */
export const MIN_CARD_EDGE: number = 32;
export const RECT_CORNER_RADIUS: number = 16;
export const ALBUM_INSET: number = 4.9;
export const ALBUM_CORNER_RADIUS: number = 14;
export const ALBUM_CARD_CORNER_RADIUS: number = 20;
export const MIN_SUBJECT_EDGE: number = 16;
export class CapType {
  static readonly CLOCK: string = 'clock';
  static readonly DATE: string = 'date';
  static readonly CALENDAR: string = 'calendar';
  static readonly COUNTDOWN: string = 'countdown';
  static readonly ANNIVERSARY: string = 'anniversary';
  static readonly DAY_PROGRESS: string = 'dayprogress';
  static readonly YEAR_PROGRESS: string = 'yearprogress';
}
export const CAPABILITIES: string[] = ['clock', 'date', 'calendar', 'countdown', 'anniversary', 'dayprogress', 'yearprogress', 'battery', 'agenda', 'timetable', 'worldclock', 'lunar', 'album'];
export interface AlbumCover {
  id:string; cover:string; background:string; title:string; artist:string;
}
export interface CapBlock {
  k: string;
  albumItems?: AlbumCover[];
  albumInset?: number;
  albumPresentation?: string;
  albumRotationMinutes?: number;
  albumRotationStart?: number;
  albumId?: string;
  albumCover?: string;
  albumBackground?: string;
  albumSource?: string;
  readingBlend?: string; // cloud | bare | badge | sticker | space | tag | dock; legacy paper/feather/scrim/halo retained
  readingEdge?: string;
  readingOutside?: boolean;
  readingHook?: number;
  readingMaterial?: string; // paper (default) | matte; host-owned surface, local and portable
  readingMaterialStudy?: number; // read-only preview; intentionally not restored from saved cards
  readingTintKey?: string;
  readingTint?: string; // local photo palette, persisted; never sampled while moving
  readingStyle?: string; // auto | plain | surface; photo subjects receive a readable backing
  parcelPlace?: string; // user's default local pickup location
  title?: string;
  date?: string;
  city?: string;
  zone?: string; // IANA time zone; system rules include daylight-saving time
  calendarOffset?: number;
  updatedAt?: number;
  attemptedAt?: number;
  refreshState?: string;
  temp?: string;
  desc?: string;
  percent?: number;
  charging?: boolean;
  chargeState?: string;
  events?: AgendaItem[];
  agendaSource?: string; // system | imported
  parcels?: ParcelItem[];
  url?: string;
  sourceConfigured?: boolean;
  field?: string; // dotted JSON path; empty = plain text
  value?: string;
  unit?: string;
  interval?: number; // minutes; 30 minimum for unattended refresh
  semester?: string;
  courses?: CourseItem[];
  timetableMode?: string; // next | day
  skipHolidays?: boolean;
  holidayDates?: HolidayDate[];
  teachingDays?: TeachingDay[];
  courseChanges?: CourseChange[];
  // Read only during migration of the old multi-cap schema.
  text?: string;
  fs?: number;
  align?: string;
  bold?: boolean;
  seed?: string;
  label?: string;
  artist?: string;
}
export interface TeachingDay { date: string; sourceDate: string; } // empty source = stop; same date = teach even on a holiday
export interface CourseChange { id: string; courseId: string; date: string; targetDate: string; start: string; end: string; room: string; } // empty target = cancellation
export interface AgendaItem { id: string; title: string; start: number; end: number; location: string; allDay: boolean; courseId?: string; }
export interface ParcelItem { id: string; code: string; place: string; picked: boolean; }
export interface CourseItem { id: string; name: string; room: string; day: number; start: string; end: string; firstWeek: number; lastWeek: number; parity: number; }
export class ElementBox {
  x: number = 0.1;
  y: number = 0.12;
  w: number = 0.8;
  h: number = 0.7;
  rot: number = 0;
  opacity: number = 1;
}
export class CanvasElement extends ElementBox {
  id: string = '';
  kind: string = 'text'; // text | image | shape
  text: string = '';
  src: string = '';
  animated: boolean = false;
  fs: number = 18;
  color: string = '';
  bold: boolean = false;
  align: string = 'left';
  behindCapability: boolean = false;
  primitive: string = 'rect'; // rect | circle | line
}
export interface ShapePoint { x: number; y: number; }
export class FridgeCard {
  reliefSrc:string=''; // Host-derived only; ignored by import and omitted from editable storage.
  html?: HtmlCardTemplate;
  groupId: string = '';
  id: string = '';
  x: number = 24;
  y: number = 32;
  w: number = 180;
  h: number = 180;
  rot: number = 0;
  z: number = 1;
  shape: string = 'rect';
  frame: boolean = false;
  material: string = 'white';
  paper: string = '';
  ink: string = '';
  capability: CapBlock | null = null;
  capBox: ElementBox = new ElementBox();
  capFree: boolean = false; // Manual foreground placement uses the whole card box, not its silhouette.
  elements: CanvasElement[] = [];
  subjectPhoto: boolean = false;
  subjectBorder: boolean = true;
  subjectAspect: number = 1;
  subjectInk: string = '#262824';
  subjectVersion: number = 0;
  cutout: string = ''; // transparent subject PNG, also the alpha mask
  outline: ShapePoint[][] = [];
  renderContourKey: string = '';
  inDoor: boolean = false;
  caps?: CapBlock[]; // legacy input only; never emitted by the v2 editor
}
export class DoorState { reveal: string = '07:30'; open: boolean = false; }
export class BackgroundAnchor { x: number = .5; y: number = .5; color: string = '#E9E5DF'; weight: number = 1; }
export class CanvasBackground {
  mode: string = 'solid'; color: string = '#FFFFFF'; src: string = ''; photo: string = '';
  transparentFrame: string = 'auto'; // Legacy transparent-only setting.
  frameStyle: string = 'none';
  palette: string[] = []; anchors: BackgroundAnchor[] = []; signature: string = '';
}
export function normalizeBackground(raw: CanvasBackground | undefined): CanvasBackground {
  const bg = new CanvasBackground(); if (raw === undefined || raw === null) return bg;
  bg.mode = ['solid', 'smart', 'blend', 'photo', 'preset', 'transparent'].includes(raw.mode) ? raw.mode : 'solid';
  bg.transparentFrame = ['auto','light','dark','none'].includes(raw.transparentFrame) ? raw.transparentFrame : 'auto';
  bg.frameStyle = ['auto','light','dark','none'].includes(raw.frameStyle) ? raw.frameStyle : bg.mode === 'transparent' ? bg.transparentFrame : 'none';
  bg.color = /^#[0-9a-fA-F]{6}$/.test(raw.color ?? '') ? raw.color : '#FFFFFF';
  bg.src = (raw.src ?? '').startsWith('file://') || (raw.src ?? '').startsWith('memory://') ? raw.src : '';
  bg.photo = (raw.photo ?? '').startsWith('file://') ? raw.photo : '';
  bg.palette = (Array.isArray(raw.palette) ? raw.palette : []).filter((c: string) => /^#[0-9a-fA-F]{6}$/.test(c)).slice(0, 6);
  bg.anchors = (Array.isArray(raw.anchors) ? raw.anchors : []).slice(0, 12).filter((a: BackgroundAnchor) => a !== null && /^#[0-9a-fA-F]{6}$/.test(a.color)).map((a: BackgroundAnchor): BackgroundAnchor => ({ x: bounded(a.x,0,1,.5), y: bounded(a.y,0,1,.5), color: a.color, weight: bounded(a.weight,.05,8,1) }));
  bg.signature = typeof raw.signature === 'string' ? raw.signature : ''; return bg;
}
export class FridgeState {
  sceneLayouts:SavedSceneLayout[]=[];
  sceneRules:SceneRule[]=[];
  sceneBaseLayoutId:string=''; // Empty = current homepage; selecting a saved normal layout applies its geometry.
  schemaVersion: number = 2;
  canvasId: string = 'canvas_main';
  background: CanvasBackground = new CanvasBackground();
  canvasAspect: number = 1;
  canvasDimension: string = '4*4';
  fridge: string = 'board';
  door: DoorState = new DoorState();
  maxZ: number = 10;
  cards: FridgeCard[] = [];
}
export function typeLabel(k: string): string {
  const index = CAPABILITIES.indexOf(k);
  const names: string[] = ['时间', '日期', '台历', '倒计时', '纪念日', '今日进度', '年度进度', '本机电量', '日程', '课程表', '世界时钟', '农历', '音乐专辑'];
  return index >= 0 ? names[index] : '自定义';
}
export function materialColors(material: string, paper: string = '', ink: string = ''): string[] {
  let base: string[] = ['#FFFFFF', '#262824'];
  if (material === 'cream') base = ['#F3EEDC', '#454035'];
  if (material === 'kraft') base = ['#DED0B8', '#433B31'];
  if (material === 'mint') base = ['#E1E9DF', '#344237'];
  if (material === 'blue') base = ['#E2E8EE', '#354553'];
  if (material === 'pink') base = ['#EEDFE0', '#543C40'];
  if (material === 'dark') base = ['#292A28', '#F4F3EF'];
  return [/^#[0-9a-fA-F]{6}$/.test(paper) ? paper : base[0], /^#[0-9a-fA-F]{6}$/.test(ink) ? ink : base[1]];
}
export function shapeRadius(shape: string, scale: number = 1): BorderRadiuses | Length {
  if (shape === 'round') return '50%';
  if (shape === 'pill') return 999;
  if (shape === 'blob') return { topLeft: '28%', topRight: '12%', bottomLeft: '18%', bottomRight: '26%' };
  return shape === 'subject' ? 0 : RECT_CORNER_RADIUS * scale;
}
/** Album geometry approved in the interactive demo; shared by app, export and widget. */
export function cardCornerRadius(card:FridgeCard,scale:number=1):BorderRadiuses | Length {
  return card.capability?.k==='album'?ALBUM_CARD_CORNER_RADIUS*scale:shapeRadius(card.shape,scale);
}
export function defaultState(): FridgeState { return new FridgeState(); }
export function bounded(value: number, min: number, max: number, fallback: number): number {
  return Math.max(min, Math.min(max, Number.isFinite(value) ? value : fallback));
}
export function normalizeBox(raw: ElementBox): ElementBox {
  const box = new ElementBox();
  box.w = bounded(raw?.w, 0.1, 1, 0.8); box.h = bounded(raw?.h, 0.08, 1, 0.7);
  box.x = bounded(raw?.x, 0, 1 - box.w, 0.1); box.y = bounded(raw?.y, 0, 1 - box.h, 0.12);
  box.rot = bounded(raw?.rot, -180, 180, 0); box.opacity = bounded(raw?.opacity, 0.1, 1, 1);
  return box;
}
/** Runtime images must never trigger HTTP requests, including migrated artwork. */
export function localImageSource(value: string | undefined): string {
  return typeof value === 'string' && (value.startsWith('file://') || value.startsWith('memory://')) ? value : '';
}
export function normalizeElement(raw: CanvasElement, clippedSubject: boolean = false): CanvasElement {
  const box = normalizeBox(raw);
  const el = new CanvasElement();
  el.id = raw.id; el.kind = ['text', 'image', 'shape'].includes(raw.kind) ? raw.kind : 'text';
  el.x = clippedSubject ? bounded(raw.x, -8, 8, box.x) : box.x;
  el.y = clippedSubject ? bounded(raw.y, -8, 8, box.y) : box.y;
  el.w = clippedSubject ? bounded(raw.w, .01, 16, box.w) : box.w;
  el.h = clippedSubject ? bounded(raw.h, .01, 16, box.h) : box.h; el.rot = box.rot; el.opacity = box.opacity;
  el.text = raw.text ?? ''; el.src = localImageSource(raw.src); el.animated = raw.animated === true;
  el.fs = bounded(raw.fs, 10, 64, 18); el.color = raw.color ?? '';
  el.behindCapability = raw.behindCapability ?? false;
  el.bold = raw.bold ?? false; el.align = raw.align ?? 'left'; el.primitive = raw.primitive ?? 'rect';
  return el;
}
function legacyElement(cap: CapBlock, id: string, index: number, count: number): CanvasElement {
  const el = new CanvasElement(); el.id = id + '_element_' + index;
  el.y = index / count; el.h = 1 / count; el.x = 0.08; el.w = 0.84;
  if (cap.k === 'photo') {
    el.kind = 'image'; el.src = localImageSource(cap.seed);
    el.x = 0; el.w = 1;
  } else {
    el.text = cap.k === 'np' ? [cap.title ?? '', cap.artist ?? ''].filter((v: string) => v.length > 0).join('\n') : (cap.text ?? '');
    el.fs = cap.fs ?? 18; el.align = cap.align ?? 'left'; el.bold = cap.bold ?? false;
  }
  return el;
}
export function normalizeState(raw: FridgeState): FridgeState {
  const state = new FridgeState(); state.canvasId = typeof raw.canvasId === 'string' && /^[a-zA-Z0-9_-]{1,96}$/.test(raw.canvasId) ? raw.canvasId : 'canvas_main'; state.background = normalizeBackground(raw.background); state.door = raw.door ?? new DoorState();
  state.canvasDimension = ['2*4', '4*4', '6*4'].includes(raw.canvasDimension) ? raw.canvasDimension : '4*4';
  state.canvasAspect = bounded(raw.canvasAspect, .3, 3, 1);
  state.sceneLayouts=normalizeSceneLayouts(raw.sceneLayouts);state.sceneRules=normalizeSceneRules(raw.sceneRules);
  state.sceneBaseLayoutId=state.sceneLayouts.some(s=>s.id===raw.sceneBaseLayoutId)?raw.sceneBaseLayoutId:'';
  state.maxZ = bounded(raw.maxZ, 0, Number.MAX_SAFE_INTEGER, 10);
  for (const source of (Array.isArray(raw.cards) ? raw.cards : [])) {
    if (source === null || typeof source.id !== 'string') continue;
    const card = new FridgeCard(); if(source.html!==undefined)card.html=normalizeHtmlCard(source.html); card.id = source.id; card.groupId = typeof source.groupId === 'string' ? source.groupId.slice(0, 96) : '';
    card.w = bounded(source.w, source.shape === 'subject' ? MIN_SUBJECT_EDGE : MIN_CARD_EDGE, 320, 180); card.h = bounded(source.h, source.shape === 'subject' ? MIN_SUBJECT_EDGE : MIN_CARD_EDGE, 420, 180);
    // Validate finite coordinates here. Rotated/host-aware recovery belongs to
    // the whole canvas, where grouping and the actual aspect are available.
    card.x = bounded(source.x, -840, BOARD_W + 840, 24); card.y = bounded(source.y, -840, BOARD_H + 840, 32);
    if(raw.schemaVersion!==2) {
      card.x=bounded(source.x,-card.w+Math.min(32,card.w*.2),BOARD_W-Math.min(32,card.w*.2),24);
      card.y=bounded(source.y,-card.h+Math.min(32,card.h*.2),BOARD_H-Math.min(32,card.h*.2),32);
    }
    card.rot = bounded(source.rot, -180, 180, 0); card.z = bounded(source.z, 0, Number.MAX_SAFE_INTEGER, 1);
    card.shape = source.shape ?? 'rect'; card.frame = source.frame ?? false;
    card.material = source.material ?? 'white'; card.paper = source.paper ?? ''; card.ink = source.ink ?? '';
    card.inDoor = source.inDoor ?? false;
    card.cutout = (source.cutout ?? '').startsWith('file://') || (source.cutout ?? '').startsWith('memory://') ? source.cutout : '';
    card.subjectBorder = true; card.subjectPhoto = source.subjectPhoto ?? false; card.subjectVersion = source.subjectVersion ?? 0; card.subjectInk = source.subjectInk ?? '#262824'; card.subjectAspect = source.subjectAspect ?? 1;
    card.outline = Array.isArray(source.outline) ? source.outline : [];
    card.capBox = normalizeBox(source.capBox); card.capBox.rot = 0; card.capFree = source.capFree === true;
    card.elements = Array.isArray(source.elements) ? source.elements.filter((el: CanvasElement) => el !== null && typeof el.id === 'string').map((el: CanvasElement) => normalizeElement(el, card.shape === 'subject')) : [];
    const caps: CapBlock[] = raw.schemaVersion === 2 ? (source.capability !== null && source.capability !== undefined ? [source.capability] : []) : (source.caps ?? []);
    state.cards.push(card);
    state.maxZ = Math.max(state.maxZ, card.z);
    for (let i = 0; i < caps.length; i++) {
      const cap = caps[i]; if (cap === null || typeof cap.k !== 'string') continue;
      // Retired capabilities leave the user's card artwork intact.
      if (cap.k === 'weather' || cap.k === 'parcel') continue;
      if (cap.k === 'fetch') {
        // Keep the last visible result as artwork, without retaining a network source.
        if (typeof cap.value === 'string' && cap.value.length > 0) {
          const cached = legacyElement({k:'text',text:[cap.title ?? '',cap.value + (cap.unit ?? '')].filter((v:string)=>v.length>0).join('\n')},card.id,i,caps.length);
          if (raw.schemaVersion === 2) { const box=normalizeBox(source.capBox); cached.x=box.x;cached.y=box.y;cached.w=box.w;cached.h=box.h; }
          cached.id=card.id+'_cached_value_'+i;
          while(card.elements.some((el:CanvasElement)=>el.id===cached.id))cached.id+='_';
          card.elements.push(cached);
        }
        continue;
      }
      if (CAPABILITIES.includes(cap.k)) {
        if (card.capability === null) {
          card.capability = normalizeCapability(cap);
          if(card.capFree&&['cloud','bare','badge','sticker','space','tag','dock'].includes(card.capability.readingBlend??'')) {
            if(card.capability.readingBlend==='sticker')card.capBox.w=bounded(source.capBox?.w,.01,3,.8);
            card.capBox.x=bounded(source.capBox?.x,-2,2,.1);
            card.capBox.y=bounded(source.capBox?.y,-2,2,.12);
            card.capBox.rot=bounded(source.capBox?.rot,-180,180,0);
          }
          if (cap.k === 'calendar') card.capability.calendarOffset = Math.round(bounded(cap.calendarOffset ?? 0, -120, 120, 0));
          if (raw.schemaVersion !== 2) {
            card.capBox.y = i / caps.length; card.capBox.h = 1 / caps.length;
          }
        } else {
          const extra = new FridgeCard(); extra.id = card.id + '_cap_' + i; extra.capability = normalizeCapability(cap);
          extra.w = card.w; extra.h = card.h; extra.x = Math.min(BOARD_W - extra.w, card.x + 16 * i);
          extra.y = Math.min(BOARD_H - extra.h, card.y + 16 * i); extra.material = card.material;
          extra.paper = card.paper; extra.ink = card.ink; extra.rot = card.rot; extra.inDoor = card.inDoor;
          extra.z = ++state.maxZ; state.cards.push(extra);
        }
      } else {
        card.elements.push(legacyElement(cap, card.id, i, caps.length));
        if (cap.k === 'photo' && (cap.label ?? '').length > 0) {
          const caption = legacyElement({ k: 'text', text: cap.label, fs: 12 }, card.id, i, caps.length);
          caption.id += '_caption'; caption.h = Math.min(0.15, 1 / caps.length);
          caption.y = (i + 1) / caps.length - caption.h; card.elements.push(caption);
        }
      }
    }
    if (card.capability?.k === 'album') { card.shape='rect'; card.frame=false; }
    if (card.shape === 'subject' && card.cutout.length === 0) card.shape = 'rect';
  }
  return state;
}
export function serializeFaceCards(state: FridgeState): string { return JSON.stringify(state.cards.filter((c: FridgeCard) => !c.inDoor)); }
export function serializeDoorCards(state: FridgeState): string { return JSON.stringify(state.cards.filter((c: FridgeCard) => c.inDoor)); }

export function contrastingInk(color: string): string {
  if (!/^#[0-9a-fA-F]{6}$/.test(color)) return '#FFFFFF';
  const light = .2126 * parseInt(color.slice(1, 3), 16) + .7152 * parseInt(color.slice(3, 5), 16) + .0722 * parseInt(color.slice(5, 7), 16);
  return light >= 145 ? '#262824' : '#FFFFFF';
}

export function normalizeCapability(raw: CapBlock): CapBlock {
  const cap = JSON.parse(JSON.stringify(raw)) as CapBlock;
  cap.url=undefined; cap.field=undefined; cap.sourceConfigured=undefined;
  if(raw.k==='album') {
    const local=(v:string|undefined):string=>typeof v==='string'&&(v.startsWith('file://')||v.startsWith('memory://'))?v:'';
    cap.albumCover=local(raw.albumCover);cap.albumBackground=local(raw.albumBackground);
    cap.albumId=typeof raw.albumId==='string'?raw.albumId.slice(0,96):'';cap.albumSource=['local','musicbrainz'].includes(raw.albumSource??'')?raw.albumSource:'';
    cap.artist=typeof raw.artist==='string'?raw.artist.slice(0,160):'';
    cap.albumInset=ALBUM_INSET;
    cap.albumPresentation=['classic','row'].includes(raw.albumPresentation??'')?raw.albumPresentation:'cover';
    cap.albumRotationMinutes=[60,180,360,1440].includes(raw.albumRotationMinutes??0)?raw.albumRotationMinutes:0;
    cap.albumRotationStart=bounded(raw.albumRotationStart??0,0,8640000000000000,0);
    const ids:string[]=[];
    cap.albumItems=(Array.isArray(raw.albumItems)?raw.albumItems:[]).filter((a:AlbumCover)=>a!==null&&a!==undefined&&typeof a.id==='string'&&a.id.length>0&&!!local(a.cover)&&!!local(a.background)&&!ids.includes(a.id.slice(0,96))&&(ids.push(a.id.slice(0,96))>0)).slice(0,12).map((a:AlbumCover):AlbumCover=>({id:a.id.slice(0,96),cover:local(a.cover),background:local(a.background),title:typeof a.title==='string'?a.title.slice(0,160):'',artist:typeof a.artist==='string'?a.artist.slice(0,160):''}));
  }
  if (raw.k === 'worldclock') cap.zone = clockZone(typeof raw.zone === 'string' ? raw.zone : '');
  cap.readingMaterialStudy=undefined;
  cap.readingMaterial=raw.readingMaterial==='matte'?'matte':'paper';
  cap.readingStyle = ['plain','surface'].includes(raw.readingStyle ?? '') ? raw.readingStyle : 'auto';
  cap.readingOutside=raw.readingOutside===true;
  cap.readingEdge=['left','right','top','bottom'].includes(raw.readingEdge??'')?raw.readingEdge:'';
  cap.readingHook=bounded(raw.readingHook??.2,0,1,.2);
  cap.readingTintKey=typeof raw.readingTintKey==='string'?raw.readingTintKey.slice(0,64):'';
  cap.readingTint=/^#[0-9a-fA-F]{6}$/.test(raw.readingTint??'')?raw.readingTint:'';
  cap.readingBlend=['cloud','bare','badge','sticker','space','tag','dock','paper','feather','scrim','halo'].includes(raw.readingBlend??'')?raw.readingBlend:'feather';
  if(raw.k!=='album')cap.readingBlend=['cloud','bare','badge','sticker','space','tag','dock'].includes(cap.readingBlend??'')?validReadingStyle(raw.k,cap.readingBlend!):defaultReadingStyle(raw.k);
  cap.parcelPlace = typeof raw.parcelPlace === 'string' ? raw.parcelPlace.slice(0,80) : '';
  cap.title = typeof raw.title === 'string' ? raw.title.slice(0,160) : '';
  cap.interval = Math.round(bounded(raw.interval ?? 60,30,1440,60));
  if (raw.k === 'battery') cap.percent = bounded(raw.percent ?? -1,-1,100,-1);
  cap.events = (Array.isArray(raw.events) ? raw.events : []).filter((e:AgendaItem)=> e && typeof e.title==='string' && Number.isFinite(e.start) && Number.isFinite(e.end) && e.end>=e.start).slice(0,256).map((e:AgendaItem):AgendaItem=>({id:String(e.id).slice(0,96),title:e.title.slice(0,160),start:e.start,end:e.end,location:typeof e.location==='string'?e.location.slice(0,160):'',allDay:e.allDay===true}));
  cap.parcels = (Array.isArray(raw.parcels) ? raw.parcels : []).filter((e:ParcelItem)=> e && typeof e.code==='string' && e.code.length>0).slice(0,64).map((e:ParcelItem):ParcelItem=>({id:String(e.id).slice(0,96),code:e.code.slice(0,24),place:typeof e.place==='string'?e.place.slice(0,80):'',picked:e.picked===true}));
  cap.courses = (Array.isArray(raw.courses) ? raw.courses : []).filter((c:CourseItem)=> c && typeof c.name==='string' && c.name.trim().length>0 && /^([01]\d|2[0-3]):[0-5]\d$/.test(c.start) && /^([01]\d|2[0-3]):[0-5]\d$/.test(c.end) && c.end>c.start).slice(0,128).map((c:CourseItem):CourseItem=>({id:String(c.id).slice(0,96),name:c.name.slice(0,80),room:typeof c.room==='string'?c.room.slice(0,80):'',day:Math.round(bounded(c.day,1,7,1)),start:c.start,end:c.end,firstWeek:Math.round(bounded(c.firstWeek,1,60,1)),lastWeek:Math.round(bounded(c.lastWeek,c.firstWeek||1,60,16)),parity:[0,1,2].includes(c.parity)?c.parity:0}));
  if(raw.k==='timetable') {
    cap.timetableMode=raw.timetableMode==='day'?'day':'next';
    cap.skipHolidays=raw.skipHolidays!==false;
    cap.holidayDates=(Array.isArray(raw.holidayDates)?raw.holidayDates:[]).filter((d:HolidayDate)=>d&&validDay(d.date)).slice(0,512).map((d:HolidayDate):HolidayDate=>({date:d.date,name:typeof d.name==='string'?d.name.slice(0,60):'校历假期'}));
    cap.teachingDays=(Array.isArray(raw.teachingDays)?raw.teachingDays:[]).filter((d:TeachingDay)=>d&&validDay(d.date)&&(d.sourceDate===''||validDay(d.sourceDate))).slice(-512);
    cap.courseChanges=(Array.isArray(raw.courseChanges)?raw.courseChanges:[]).filter((d:CourseChange)=>d&&typeof d.id==='string'&&cap.courses!.some((c:CourseItem)=>c.id===d.courseId)&&validDay(d.date)&&(d.targetDate===''||(validDay(d.targetDate)&&/^([01]\d|2[0-3]):[0-5]\d$/.test(d.start)&&/^([01]\d|2[0-3]):[0-5]\d$/.test(d.end)&&d.end>d.start))).slice(-256).map((d:CourseChange):CourseChange=>({id:d.id.slice(0,96),courseId:d.courseId,date:d.date,targetDate:d.targetDate,start:d.start??'',end:d.end??'',room:typeof d.room==='string'?d.room.slice(0,80):''}));
  }
  return cap;
}
