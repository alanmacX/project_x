// Read rendered Strongwise/强智 personal timetable only; no credentials or hidden requests.
(async function(){
  const b=window.AndroidBridgePromise,n=window.AndroidBridge;
  const ok=await b.showAlert('读取个人课表','请先选择学期并打开完整的个人课表。','读取');
  if(!ok)return;
  const table=document.querySelector('#kbtable');
  if(!table)throw Error('请进入个人课表页');
  const courses=[];let rejected=0;
  const dayText=s=>{const m=String(s).match(/(?:星期|周)([一二三四五六日天])/);return m?'一二三四五六日天'.indexOf(m[1])+1:0;};
  const rows=Array.from(table.rows);if(rows.length>80)throw Error('课表过大');
  const grid=[];const origins=[];
  for(let r=0;r<rows.length;r++){
    grid[r]=grid[r]||[];let c=0;
    for(const td of Array.from(rows[r].cells)){
      while(grid[r][c])c++;const rs=Math.min(80-r,td.rowSpan||1),cs=td.colSpan||1;
      if(c+cs>20)throw Error('表格列数异常');
      origins.push({td,col:c});
      for(let rr=r;rr<r+rs;rr++){grid[rr]=grid[rr]||[];for(let cc=c;cc<c+cs;cc++)grid[rr][cc]=td;}
      c+=cs;
    }
  }
  const headers=grid.find(row=>row.filter(c=>c&&dayText(c.textContent)).length>=5);
  const days=headers?headers.map(c=>Math.min(7,dayText(c.textContent))):[];
  if(!days.length)throw Error('星期表头无法识别');
  for(const {td,col} of origins){
    const blocks=td.querySelectorAll('.kbcontent');if(!blocks.length)continue;
    const day=days[col];if(!day)continue;
    for(const block of blocks){
      const html=block.innerHTML.split(/<hr\b[^>]*>|={4,}/i);
      for(const part of html){
        const el=document.createElement('div');el.innerHTML=part;
        for(const br of el.querySelectorAll('br'))br.replaceWith('\n');
        const lines=el.textContent.split(/\n/).map(x=>x.trim()).filter(Boolean);if(!lines.length)continue;
        const time=el.querySelector('[title*="周次"]');const schedule=time?time.textContent:lines.find(x=>/周/.test(x));
        const node=String(schedule||'').match(/(?:\[|\(|（)\s*(\d+)\s*(?:[-~至]\s*(\d+))?\s*节/);
        if(!node){rejected++;continue;}
        const weekText=String(schedule).slice(0,node.index).replace(/周|第/g,'');
        const weeks=[];for(const seg of weekText.split(/[,，;；]/)){
          const range=seg.match(/(\d+)\s*(?:[-~至]\s*(\d+))?/);if(!range)continue;
          const a=+range[1],z=+(range[2]||range[1]);if(a<1||z>60||z<a)throw Error('周次超出范围');
          for(let w=a;w<=z;w++)if((!seg.includes('单')||w%2===1)&&(!seg.includes('双')||w%2===0))weeks.push(w);
        }
        const name=lines[0];if(!weeks.length||!name){rejected++;continue;}
        courses.push({name,teacher:'',position:el.querySelector('[title*="教室"]')?.textContent.trim()||'',day,startSection:+node[1],endSection:+(node[2]||node[1]),weeks:[...new Set(weeks)]});
        if(courses.length>128)throw Error('课程过多');
      }
    }
  }
  if(rejected)throw Error('部分课程格式不匹配，请使用学校专用适配，避免遗漏课程');
  if(!courses.length)throw Error('没有读取到完整课程');
  await b.saveImportedCourses(JSON.stringify(courses));n.notifyTaskCompletion();
})();
