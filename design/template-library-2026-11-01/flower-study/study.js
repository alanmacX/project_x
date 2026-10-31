(function(){
function at(value){const [h,m]=value.split(':').map(Number),d=new Date(LibraryFixtures.tick);d.setHours(h,m,0,0);return d.getTime();}
function show(index,value){document.getElementById('aligned-'+index).innerHTML=TemplateRender.render('dial',{tick:at(value)});}
for(const [i,value] of ['10:09','09:41','03:15'].entries())show(i,value);
document.getElementById('time').oninput=e=>{if(!/^\d{2}:\d{2}$/.test(e.target.value))return;show(0,e.target.value);document.getElementById('caption-0').textContent=e.target.value+' · 可调整';};
})();
