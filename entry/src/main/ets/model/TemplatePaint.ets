import { TemplateScene, TemplateMark } from './TemplateScene';
function rounded(ctx: CanvasRenderingContext2D, m: TemplateMark): void {
    const r = Math.min(m.r, m.w / 2, m.h / 2);
    ctx.beginPath();
    ctx.moveTo(m.x + r, m.y);
    ctx.lineTo(m.x + m.w - r, m.y);
    ctx.quadraticCurveTo(m.x + m.w, m.y, m.x + m.w, m.y + r);
    ctx.lineTo(m.x + m.w, m.y + m.h - r);
    ctx.quadraticCurveTo(m.x + m.w, m.y + m.h, m.x + m.w - r, m.y + m.h);
    ctx.lineTo(m.x + r, m.y + m.h);
    ctx.quadraticCurveTo(m.x, m.y + m.h, m.x, m.y + m.h - r);
    ctx.lineTo(m.x, m.y + r);
    ctx.quadraticCurveTo(m.x, m.y, m.x + r, m.y);
    ctx.closePath();
}
export function paintTemplate(ctx: CanvasRenderingContext2D, scene: TemplateScene, width: number, height: number, layer: number, fill: boolean): void {
    ctx.clearRect(0, 0, width, height);
    ctx.save();
    if (layer === 0 && !fill) {
        ctx.fillStyle = scene.background;
        ctx.fillRect(0, 0, width, height);
    }
    const scale = Math.min(width, height) / 300;
    ctx.translate((width - 300 * scale) / 2, (height - 300 * scale) / 2);
    ctx.scale(scale, scale);
    for (const m of scene.marks) {
        if (m.layer !== layer || m.kind === 'image')
            continue;
        ctx.save();
        ctx.globalAlpha = m.opacity;
        if (m.angle) {
            ctx.translate(m.x + m.w / 2, m.y + m.h / 2);
            ctx.rotate(m.angle * Math.PI / 180);
            ctx.translate(-m.x - m.w / 2, -m.y - m.h / 2);
        }
        ctx.fillStyle = m.color;
        ctx.strokeStyle = m.color;
        ctx.lineWidth = m.stroke;
        ctx.lineCap = 'round';
        if (m.end) {
            const gradient = ctx.createLinearGradient(m.x, m.y, m.x + m.w, m.y + m.h);
            gradient.addColorStop(0, m.color);
            gradient.addColorStop(1, m.end);
            ctx.fillStyle = gradient;
        }
        if (m.kind === 'rect') {
            rounded(ctx, m);
            if (m.stroke > 0)
                ctx.stroke();
            else
                ctx.fill();
        }
        else if (m.kind === 'circle') {
            ctx.beginPath();
            ctx.ellipse(m.x + m.w / 2, m.y + m.h / 2, m.w / 2, m.h / 2, 0, 0, Math.PI * 2);
            ctx.fill();
        }
        else if (m.kind === 'arc') {
            ctx.beginPath();
            ctx.arc(m.x, m.y, m.r, m.start * Math.PI / 180, (m.start + m.sweep) * Math.PI / 180);
            ctx.stroke();
        }
        else if (m.kind === 'line') {
            ctx.beginPath();
            ctx.moveTo(m.x, m.y);
            ctx.lineTo(m.w, m.h);
            ctx.stroke();
        }
        else if (m.kind === 'text') {
            const family = m.font === 'digits' ? 'TemplateDigits' : m.font;
            ctx.font = (m.weight >= 600 ? 'bold ' : '') + m.size + 'vp ' + family;
            ctx.textBaseline = 'top';
            ctx.textAlign = m.align === 'center' ? 'center' : m.align === 'right' ? 'right' : 'left';
            ctx.beginPath();
            ctx.rect(m.x, m.y, m.w, m.h);
            ctx.clip();
            let value = m.text;
            if (m.font === 'digits') {
                const measured = ctx.measureText(value).width;
                if (measured > m.w)
                    ctx.font = (m.weight >= 600 ? 'bold ' : '') + (m.size * m.w / measured) + 'vp ' + family;
            }
            else {
                while (value.length > 1 && ctx.measureText(value).width > m.w) {
                    value = value.slice(0, -2) + '…';
                }
            }
            ctx.fillText(value, m.x + (m.align === 'center' ? m.w / 2 : m.align === 'right' ? m.w : 0), m.y, m.w);
        }
        ctx.restore();
    }
    ctx.restore();
}
