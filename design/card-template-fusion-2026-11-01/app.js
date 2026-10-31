let state=FusionStudy.initial();
const $=id=>document.getElementById(id),card=$('clock-card'),cat=$('cat');
function dispatch(action,value){state=FusionStudy.update(state,action,value);render();}
function pressed(selector,value,key){document.querySelectorAll(selector).forEach(b=>b.setAttribute('aria-pressed',String(b.dataset[key]===value)));}
function render(){const c=state.cards[0],d=c.design,p=d.params;
 $('board').className='board '+state.mode;card.className='clock-card '+d.presentation+' '+(p.depth?'depth ':'')+p.palette;
 card.style.setProperty('--scale',p.scale/100);card.style.setProperty('--offset',p.offset+'%');
 const src='../template-capabilities-2026-11-01/assets/cat-'+p.subject+'.webp';if(cat.getAttribute('src')!==src)cat.src=src;
 cat.alt=p.subject==='pipi'?'Painjet 拍摄的皮皮':'Matt Buck 拍摄的棕猫';
 $('depth').checked=p.depth;$('scale').value=p.scale;$('offset').value=p.offset;
 pressed('[data-surface]',d.presentation,'surface');pressed('[data-palette]',p.palette,'palette');pressed('[data-subject]',p.subject,'subject');
 $('solo').setAttribute('aria-pressed',String(state.mode==='solo'));$('ensemble').setAttribute('aria-pressed',String(state.mode==='ensemble'));
 for(const k of ['agenda','note'])$(k+'-card').hidden=state.mode!=='ensemble'||!state.cards.some(c=>c.id==='study_'+k);
 $('stage-caption').textContent=(state.mode==='solo'?'1':String(state.cards.length))+' 张卡片 · '+(state.mode==='solo'?'2×2':'4×4')+' 画布';
}
$('solo').onclick=()=>dispatch('mode','solo');$('ensemble').onclick=()=>dispatch('mode','ensemble');
$('depth').onchange=e=>dispatch('depth',e.target.checked);
for(const k of ['scale','offset'])$(k).oninput=e=>dispatch(k,e.target.value);
for(const k of ['surface','palette','subject'])document.querySelectorAll('[data-'+k+']').forEach(b=>b.onclick=()=>dispatch(k,b.dataset[k]));
$('reset').onclick=()=>dispatch('reset');$('add').onclick=()=>{const open=$('add-menu').hidden;$('add-menu').hidden=!open;$('add').setAttribute('aria-expanded',String(open));};
document.querySelectorAll('[data-add]').forEach(b=>b.onclick=()=>{dispatch('add',b.dataset.add);$('add-menu').hidden=true;$('add').setAttribute('aria-expanded','false');});
document.querySelectorAll('[data-remove]').forEach(b=>b.onclick=()=>dispatch('remove',b.dataset.remove));
window.FusionDemo={snapshot:()=>structuredClone(state)};
render();
