from PIL import Image
from pathlib import Path
import sys,json
root=Path(r'E:/neverlookback/art/protagonist_rebuild_v3/phase_f')
prefix=sys.argv[1]
sheet=Image.open(root/'evidence'/f'{prefix}_spritesheet.png').convert('RGBA')
for scale in (1,2,6):
 for bg,name in (('#0D0F17','game'),('#D9D6CF','light')):
  out=Image.new('RGBA',sheet.size,bg);out.alpha_composite(sheet)
  out.resize((out.width*scale,out.height*scale),Image.Resampling.NEAREST).save(root/'evidence'/f'{prefix}_{name}_{scale}x.png')
