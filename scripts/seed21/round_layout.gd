extends Node
## Changes ONLY two bounded cover props at DRAW, after the existing round reset/spawns.
## Original landmarks, hide ports, surface mechanisms and permanent routes are never relocated.
const Plans=preload("res://scripts/seed21/layouts.gd")
const Art=preload("res://scripts/phase4/art.gd")
const Wet=preload("res://scripts/wetland21/services.gd")
const Canyon=preload("res://scripts/canyon21/services.gd")
var game
var arena_ref: WeakRef
var root: Node3D
var screens: Array[Node3D]=[]
var bodies: Array[StaticBody3D]=[]
var added: Array[Rect2]=[]
var descriptor: Dictionary={}
var diagnostic: Label
var applied:=false
var applications:=0
var last_rejection:=""

func setup(g) -> void:
	game=g;name="RoundLayout21"
	diagnostic=Label.new();diagnostic.name="LayoutReproduction21";diagnostic.mouse_filter=Control.MOUSE_FILTER_IGNORE
	diagnostic.add_theme_font_size_override("font_size",12)
	diagnostic.add_theme_color_override("font_color",Color("ecddba"))
	diagnostic.add_theme_color_override("font_outline_color",Color("20352c"));diagnostic.add_theme_constant_override("outline_size",3)
	game.ui.root.add_child(diagnostic);diagnostic.visible=false

func _process(_delta: float) -> void:
	if not is_instance_valid(diagnostic):return
	diagnostic.visible=applied and game.world_view_active() and not game.ui.modal.visible
	diagnostic.position=Vector2(16,game.ui.root.size.y-24)

func park() -> void:
	# Remove only our registered rectangles; never replace somebody else's map list.
	var arena=arena_ref.get_ref() if arena_ref!=null else null
	if is_instance_valid(root):
		root.visible=false
		for b in bodies:b.collision_layer=0
	if is_instance_valid(arena) and not added.is_empty():
		for r in added:arena.obstacles.erase(r)
		arena.navigation.clear();arena._build_navigation()
	added.clear();applied=false;descriptor={}
	if is_instance_valid(diagnostic):diagnostic.visible=false

func make_pool(arena) -> void:
	if is_instance_valid(root) and arena_ref.get_ref()==arena:return
	arena_ref=weakref(arena);screens.clear();bodies.clear()
	root=Node3D.new();root.name="RoundCover21";arena.add_child(root);root.visible=false
	var tint: Color={"pine_hollow":Color("98734f"),"reedwater_bend":Color("8b9870"),"amber_canyon":Color("ba8664")}[arena.map_id]
	for i in range(2):
		var holder:=Node3D.new();holder.name="RouteProp%d"%i;root.add_child(holder);screens.append(holder)
		var size3:=Vector3(1.6,1.65,0.85)
		Art.box(holder,Vector3.UP*size3.y*0.5,size3,tint,"wood",0.12)
		# Visible bundled slats/straps stay inside the same conservative blocker footprint.
		for side in [-1,1]:
			Art.box(holder,Vector3(side*0.51,0.825,0.426),Vector3(0.09,1.5,0.024),tint.lightened(0.25),"wood",0.01)
		for j in range(3):
			Art.box(holder,Vector3(-0.45+j*0.45,1.70,0),Vector3(0.32,0.12,0.50),tint.lightened(0.10),"foam",0.035)
		var b:=StaticBody3D.new();b.name="RoutePhysics";b.collision_layer=0;holder.add_child(b);bodies.append(b)
		var c:=CollisionShape3D.new();var s:=BoxShape3D.new();s.size=size3;c.shape=s;c.position.y=size3.y*0.5;b.add_child(c)
		b.set_meta("round_cover21",true)
	# Every new occluding surface stays visible at all graphics distances.
	var studio=game.get_node_or_null("ToyStudio")
	if studio!=null:studio.apply_materials(root)

static func rect_for(at: Vector2,size3: Vector3,padding: float=0.46) -> Rect2:
	return Rect2(at-Vector2(size3.x,size3.z)*0.5,Vector2(size3.x,size3.z)).grow(padding)

static func grid_for(arena,extra: Array[Rect2]) -> AStarGrid2D:
	var grid:=AStarGrid2D.new();grid.region=arena.navigation.region;grid.offset=arena.origin
	grid.cell_size=Vector2.ONE;grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_NEVER;grid.update()
	for x in range(arena.grid_size.x):
		for y in range(arena.grid_size.y):
			var id:=Vector2i(x,y);var solid: bool=arena.navigation.is_point_solid(id)
			if not solid:
				for r in extra:
					if r.has_point(arena.origin+Vector2(id)):solid=true;break
			grid.set_point_solid(id,solid)
	return grid

static func fully_connected(grid: AStarGrid2D) -> bool:
	var start:=Vector2i(-1,-1);var total:=0;var seen: Dictionary={}
	for x in range(grid.region.size.x):
		for y in range(grid.region.size.y):
			var at:=Vector2i(x,y)
			if not grid.is_point_solid(at):total+=1;start=at
	if total==0:return false
	var queue: Array[Vector2i]=[start];seen[start]=true;var cursor:=0
	while cursor<queue.size():
		var at:=queue[cursor];cursor+=1
		for d in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next: Vector2i=at+d
			if grid.region.has_point(next) and not grid.is_point_solid(next) and not seen.has(next):seen[next]=true;queue.append(next)
	return seen.size()==total

func validate_plan(p: Dictionary,physical: bool=true) -> String:
	var arena=game.arena
	if p.is_empty() or p.map!=arena.map_id:return "unsupported map"
	var proposed: Array[Rect2]=[]
	var reserved: Array[Vector3]=[];reserved.assign(arena.spawn_points)
	for h in game.hiding.homes:
		reserved.append(h.entry)
		for e in h.exits:reserved.append(e)
	for center in p.positions:
		var r:=rect_for(center,p.size)
		if not arena.active_rect.grow(-1.0).encloses(r):return "boundary"
		for old in arena.obstacles:
			if r.intersects(old):return "existing cover clearance"
		for old in proposed:
			if r.grow(1).intersects(old):return "narrow gap"
		for at in reserved:
			if r.grow(1.3).has_point(Vector2(at.x,at.z)):return "spawn or hide port"
		# Preserve the common central duel pad and every authored noisy/quiet surface strip.
		if r.intersects(Rect2(-3.5,0.3,7.0,4.0)):return "duel pad"
		for z in arena.surface_zones:
			if r.intersects(z.rect):return "sound route"
		if arena.map_id=="amber_canyon":
			if r.intersects(Rect2(-2.5,-2,5,11)):return "exposed lane"
			for at in Canyon.WIND_CENTERS:
				if r.intersects(Rect2(Vector2(at.x,at.z)-Vector2.ONE*1.6,Vector2.ONE*3.2)):return "wind pad"
		if physical:
			var q:=PhysicsShapeQueryParameters3D.new();var shape:=BoxShape3D.new()
			shape.size=p.size+Vector3(0.08,0,0.08);q.shape=shape;q.transform.origin=Vector3(center.x,p.size.y*0.5+0.02,center.y);q.collision_mask=3
			if not game.get_world_3d().direct_space_state.intersect_shape(q,1).is_empty():return "occupied socket"
		proposed.append(r)
	if not fully_connected(grid_for(arena,proposed)):return "disconnected"
	return ""

func apply_round(match_seed: int,round_index: int) -> bool:
	# No mid-chase moving walls. Existing _prepare_round parks old props and resets players first.
	if game.rules.phase!=game.Rules.Phase.DRAW or game.practice_mode:return false
	if game.arena.map_id not in Plans.IDS:return false
	park();make_pool(game.arena)
	var p:=Plans.plan(game.arena.map_id,match_seed,round_index)
	last_rejection=validate_plan(p)
	if not last_rejection.is_empty():
		# Unexpected future geometry must fail safe, never silently select a different RNG outcome.
		print("ROUND_LAYOUT21_REJECT: ",last_rejection," ",JSON.stringify(Plans.serial(p)))
		return false
	for i in range(2):
		var at: Vector2=p.positions[i];screens[i].position=Vector3(at.x,0,at.y);bodies[i].collision_layer=1
		var r:=rect_for(at,p.size);added.append(r);game.arena.obstacles.append(r)
	game.arena.navigation.clear();game.arena._build_navigation();root.visible=true;applied=true;applications+=1
	descriptor=Plans.serial(p);descriptor["round_seed"]=game.hiding.seed_value
	descriptor["fingerprint"]=JSON.stringify(descriptor).sha256_text()
	diagnostic.text="Seed %d  /  Round %d  /  Layout %s"%[match_seed,round_index+1,p.id]
	print("ROUND_LAYOUT21: ",JSON.stringify(descriptor))
	return true
