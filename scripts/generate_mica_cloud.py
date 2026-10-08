"""Deterministic cloud pigment; generated once, never as a drag/refresh workload."""
from pathlib import Path
import random
from PIL import Image, ImageFilter
random.seed(2841)
n=256
field=[0.0]*(n*n)
for size, weight, blur in [(5,.50,24),(13,.27,10),(37,.18,3),(128,.05,.4)]:
    small=Image.new('L',(size,size))
    small.putdata([random.randrange(256) for _ in range(size*size)])
    plane=small.resize((n,n),Image.Resampling.BICUBIC).filter(ImageFilter.GaussianBlur(blur))
    for i,v in enumerate(plane.getdata()): field[i]+=weight*v
lo,hi=min(field),max(field)
alpha=Image.new('L',(n,n))
alpha.putdata([round(12+115*((v-lo)/(hi-lo))**1.4) for v in field])
cloud=Image.new('RGBA',(n,n),(255,254,244,0))
cloud.putalpha(alpha)
cloud.save(Path(__file__).resolve().parents[1]/'entry/src/main/resources/base/media/reading_mica_cloud.png',optimize=True)
