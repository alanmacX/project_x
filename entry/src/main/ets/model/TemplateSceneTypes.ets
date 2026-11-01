export class TemplateMark {
    kind: string = 'rect';
    x: number = 0;
    y: number = 0;
    w: number = 0;
    h: number = 0;
    r: number = 0;
    color: string = '#222823';
    end: string = '';
    angle: number = 0;
    opacity: number = 1;
    text: string = '';
    lines: number = 1;
    size: number = 16;
    weight: number = 400;
    align: string = 'left';
    font: string = 'sans-serif';
    start: number = 0;
    sweep: number = 360;
    stroke: number = 0;
    layer: number = 0;
    src: string = '';
    fit: string = 'cover';
}
export class TemplateScene {
    width: number = 300;
    height: number = 300;
    surface: boolean = true;
    marks: TemplateMark[] = [];
    background: string = '#F1EDE3';
    ink: string = '#30362D';
    accent: string = '#B6593D';
}

export function copyTemplateMark(source:TemplateMark):TemplateMark{
 const mark=new TemplateMark();
 mark.kind=source.kind;mark.x=source.x;mark.y=source.y;mark.w=source.w;mark.h=source.h;mark.r=source.r;mark.color=source.color;mark.end=source.end;mark.angle=source.angle;mark.opacity=source.opacity;mark.text=source.text;mark.lines=source.lines;mark.size=source.size;mark.weight=source.weight;mark.align=source.align;mark.font=source.font;mark.start=source.start;mark.sweep=source.sweep;mark.stroke=source.stroke;mark.layer=source.layer;mark.src=source.src;mark.fit=source.fit;
 return mark;
}
