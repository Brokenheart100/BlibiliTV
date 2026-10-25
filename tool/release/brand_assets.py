"""Reproduce original geometric brand artwork; needs Pillow for the banner PNG."""
from pathlib import Path
from PIL import Image, ImageDraw
ROOT = Path(__file__).resolve().parents[2]
RES = ROOT / 'android/app/src/main/res'
for d in ['drawable-xhdpi','mipmap-anydpi','mipmap-anydpi-v26']: (RES/d).mkdir(exist_ok=True)
scale=4
im=Image.new('RGB',(320*scale,180*scale)); draw=ImageDraw.Draw(im)
for y in range(180*scale):
    t=y/(180*scale-1); draw.line((0,y,320*scale,y),fill=tuple(round(a+(b-a)*t) for a,b in zip((26,42,64),(14,16,27))))
def rect(box,fill,r=0): draw.rounded_rectangle(tuple(round(v*scale) for v in box),radius=r*scale,fill=fill)
def poly(points,fill): draw.polygon([(x*scale,y*scale) for x,y in points],fill=fill)
rect((24,51,104,125),'#78E0D7',20); rect((29,56,99,120),'#152536',15)
poly([(56,70),(82,88),(56,106)],'#78E0D7')
# Original geometric letter strokes, no font files or third-party artwork.
letters={
'M':[[(0,28),(0,0),(10,14),(20,0),(20,28)]],
'A':[[(0,28),(10,0),(20,28)],[(4,18),(16,18)]],
'B':[[(0,28),(0,0),(13,0),(20,5),(20,10),(13,14),(0,14)],[(13,14),(20,18),(20,23),(13,28),(0,28)]],
'T':[[(0,0),(20,0)],[(10,0),(10,28)]],
'V':[[(0,0),(10,28),(20,0)]]}
paths=[]
for word,x,y,k,color in [('MAMBA',130,62,1,'#F5F8FF'),('TV',130,109,.6,'#78E0D7')]:
    for i,c in enumerate(word):
        for line in letters[c]:
            points=[((x+i*29*k+a*k)*scale,(y+b*k)*scale) for a,b in line]
            draw.line(points,fill=color,width=round(3*k*scale),joint='curve')
            paths.append((color,3*k,[(x+i*29*k+a*k,y+b*k) for a,b in line]))
im.resize((320,180),Image.Resampling.LANCZOS).save(RES/'drawable-xhdpi/mamba_tv_banner.png')
svg=['<svg xmlns="http://www.w3.org/2000/svg" width="320" height="180" viewBox="0 0 320 180">','<rect width="320" height="180" fill="#152536"/><rect x="24" y="51" width="80" height="74" rx="20" fill="#78E0D7"/><rect x="29" y="56" width="70" height="64" rx="15" fill="#152536"/><path d="M56 70L82 88L56 106Z" fill="#78E0D7"/>']
for color,w,points in paths:
    d='M'+'L'.join(f'{x:g} {y:g}' for x,y in points)
    svg.append(f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{w:g}" stroke-linejoin="round"/>')
svg.append('</svg>'); (ROOT/'assets/brand/mamba-tv-banner.svg').write_text('\n'.join(svg)+'\n')
foreground='<path android:fillColor="#78E0D7" android:pathData="M36,30H72Q84,30 84,42V66Q84,78 72,78H36Q24,78 24,66V42Q24,30 36,30Z"/><path android:fillColor="#152536" android:pathData="M37,35H71Q79,35 79,43V65Q79,73 71,73H37Q29,73 29,65V43Q29,35 37,35Z"/><path android:fillColor="#78E0D7" android:pathData="M47,42L65,54L47,66Z"/>'
head='<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108">'
(RES/'drawable/mamba_icon_foreground.xml').write_text(head+foreground+'</vector>\n')
(RES/'mipmap-anydpi/mamba_launcher.xml').write_text(head+'<path android:fillColor="#152536" android:pathData="M0,0H108V108H0Z"/>'+foreground+'</vector>\n')
(RES/'mipmap-anydpi-v26/mamba_launcher.xml').write_text('<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android"><background android:drawable="@color/mamba_icon_background"/><foreground android:drawable="@drawable/mamba_icon_foreground"/></adaptive-icon>\n')
(RES/'values/brand_colors.xml').write_text('<resources><color name="mamba_icon_background">#152536</color></resources>\n')
print('Generated original vector launcher and 320x180 xhdpi banner')
