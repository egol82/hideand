extends RefCounted
## Project-authored periodic height/detail tiles. Bounded static cache; no random-state changes.
const SIZE:=128
static var cache: Dictionary={}
static var builds:=0
static func texture_for(kind: String) -> ImageTexture:
	var key:=kind if kind in ["foam","fabric","wood","plaster"] else "smooth"
	if cache.has(key):return cache[key]
	var image:=Image.create(SIZE,SIZE,false,Image.FORMAT_RGB8)
	for y in range(SIZE):
		for x in range(SIZE):
			var u:=TAU*float(x)/SIZE;var v:=TAU*float(y)/SIZE
			var h:=0.5;var detail:=0.5
			if key=="foam":
				var wave:=sin(u*13+cos(v*3))*sin(v*11+cos(u*2))
				var pore:=pow(maxf(0,wave),3.0)
				h=0.60-0.34*pore+sin(u*19+v*7)*sin(v*17-u*5)*0.045
				detail=0.56-0.35*pore
			elif key=="fabric":
				var warp:=sin(u*16);var weft:=sin(v*16)
				h=0.5+warp*weft*0.20+cos(u*32)*0.055+cos(v*32)*0.055
				detail=0.5+warp*weft*0.32
			elif key=="wood":
				var grain:=sin(v*10+sin(u*2)*0.7)
				h=0.5+grain*0.12+sin(v*29+sin(u)*0.6)*0.04;detail=0.5+grain*0.22
			elif key=="plaster":
				h=0.5+sin(u*7+v*3)*sin(v*9-u*2)*0.14+sin(u*21-v*11)*0.03;detail=h
			image.set_pixel(x,y,Color(h,detail,clampf(0.5+(h-0.5)*0.7,0,1)))
	image.generate_mipmaps()
	var result:=ImageTexture.create_from_image(image);result.resource_name="Material14/"+key
	cache[key]=result;builds+=1
	return result
