extends SceneTree
const Rules = preload("res://scripts/phase2/match_rules.gd")
const Data = preload("res://scripts/phase2/drawing_data.gd")
const Form = preload("res://scripts/phase2/weapon_form.gd")
const Arena = preload("res://scripts/phase2/arena.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, description: String) -> void:
	checks += 1
	if ok:
		print("PASS: "+description)
	else:
		failures += 1
		printerr("FAIL: "+description)

func run() -> void:
	_test_rules()
	_test_geometry()
	await _test_navigation()
	print("PHASE2_UNIT_RESULT: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)

func _seek_game():
	var rules = Rules.new()
	rules.start(true)
	rules.ready()
	rules.tick(Rules.HIDE_SECONDS)
	return rules

func _test_rules() -> void:
	var rules = Rules.new()
	check(rules.phase == Rules.Phase.MENU,"initial menu")
	check(not rules.ready(),"cannot ready in menu")
	check(not rules.discover(1),"cannot discover in menu")
	rules.start(true)
	check(rules.seeker == 0 and rules.remaining() == 3,"one seeker and three hiders")
	check(rules.phase == Rules.Phase.DRAW,"match begins with drawing")
	var time: float = rules.time_left
	rules.tick(NAN)
	rules.tick(-1.0)
	check(rules.time_left == time,"invalid delta rejected")
	check(not rules.discover(1),"drawing phase blocks discovery")
	check(rules.ready(),"ready advances to hide")
	rules.tick(Rules.HIDE_SECONDS-0.1)
	check(rules.phase == Rules.Phase.HIDE,"hide timer not prematurely ended")
	rules.tick(0.11)
	check(rules.phase == Rules.Phase.SEEK,"hide timer opens search")
	check(not rules.discover(-1) and not rules.discover(4),"out-of-range player rejected")
	check(not rules.discover(0),"seeker cannot discover self")
	check(rules.discover(1),"valid discovery enters reveal")
	check(not rules.discover(2),"no overlapping duels")
	rules.register_hits([0])
	check(rules.hp[1] == 3,"reveal is non-damaging")
	rules.tick(Rules.REVEAL_SECONDS)
	check(rules.phase == Rules.Phase.DUEL,"reveal opens combat")
	rules.register_hits([2])
	check(rules.hp[0] == 3 and rules.hp[1] == 3,"nonparticipant cannot damage duelists")
	rules.register_hits([0,0])
	check(rules.hp[1] == 2,"duplicate attacker per batch counts once")
	var search_time: float = rules.search_left
	rules.tick(1.0)
	check(rules.search_left == search_time,"search clock frozen during duel")
	rules.register_hits([0])
	rules.register_hits([0])
	check(not rules.alive[1] and rules.scores[0] == 3,"three hits capture and award points")
	check(rules.phase == Rules.Phase.SEEK,"capture resumes search")
	check(not rules.discover(1),"captured player cannot be rediscovered")
	rules.discover(2)
	rules.tick(Rules.REVEAL_SECONDS)
	rules.tick(Rules.DUEL_SECONDS)
	check(rules.alive[2] and rules.scores[2] == 2,"duel timeout awards escape")
	check(not rules.discover(2),"escape grants rediscovery grace")
	rules.tick(Rules.GRACE_SECONDS+0.01)
	check(rules.discover(2),"grace expires after search time")
	rules.tick(Rules.REVEAL_SECONDS)
	rules.hp[0] = 1
	rules.hp[2] = 1
	rules.register_hits([0,2])
	check(rules.alive[2],"simultaneous KO awards hider escape")
	check(rules.phase == Rules.Phase.SEEK,"trade resolves only once")
	var sweep = _seek_game()
	for id in [1,2,3]:
		sweep.discover(id)
		sweep.tick(Rules.REVEAL_SECONDS)
		for hit in range(3):
			sweep.register_hits([0])
	check(sweep.phase == Rules.Phase.RESULT,"all captures end round")
	check(sweep.scores[0] == 11,"capture and sweep bonus scored once")
	sweep.tick(1000.0)
	check(sweep.scores[0] == 11,"result tick cannot duplicate points")
	var seekers: Array[int] = [sweep.seeker]
	for i in range(3):
		check(sweep.next_round(),"advance next round %d" % i)
		seekers.append(sweep.seeker)
		sweep.ready()
		sweep.tick(Rules.HIDE_SECONDS)
		sweep.tick(Rules.SEEK_SECONDS)
		check(sweep.phase == Rules.Phase.RESULT,"search timeout ends round %d" % i)
	check(seekers == [0,1,2,3],"each participant is seeker exactly once")
	sweep.next_round()
	check(sweep.phase == Rules.Phase.COMPLETE,"four rounds complete the match")
	check(not sweep.next_round(),"cannot advance beyond match end")
	var hider_first = Rules.new()
	hider_first.start(false)
	check(hider_first.seeker == 1,"hide-first mode changes initial seeker")
	hider_first.tick(Rules.DRAW_SECONDS)
	check(hider_first.phase == Rules.Phase.HIDE,"drawing timeout advances safely")

func _test_geometry() -> void:
	for kind in ["hammer","fish","pan"]:
		var data = Data.new()
		data.set_preset(kind)
		check(Form.contours(data).size() == 1,kind+" finds own closed loop")
		var mesh: MeshInstance3D = Form.build(data)
		check(mesh.has_node("ClosedContourFill"),kind+" generates real filled geometry")
		mesh.free()
		var samples: PackedVector3Array = Form.samples(data)
		check(samples.size() <= Form.MAX_SAMPLES,kind+" collision budget")
		var finite := true
		for point in samples:
			finite = finite and point.is_finite() and point.length() <= data.MAX_REACH
		check(finite,kind+" collision positions bounded and finite")
		var copy = data.clone()
		copy.fill_closed = false
		check(data.fill_closed,"clone fill flag is independent")
		check(Form.contours(copy).is_empty(),kind+" tube-only mode")
		var roundtrip = Data.new()
		check(roundtrip.load_dictionary(data.to_dictionary()) and roundtrip.fill_closed,kind+" fill flag round-trip")
		var legacy: Dictionary = data.to_dictionary()
		legacy.erase("fill_closed")
		check(roundtrip.load_dictionary(legacy) and not roundtrip.fill_closed,kind+" old saves preserve hollow shape")
	var invalid = Data.new()
	check(not invalid.load_dictionary({"version":1,"fill_closed":"yes","strokes":[]}),"malformed fill flag rejected")
	var open = Data.new()
	open.strokes.append(PackedVector2Array([Vector2(0.2,0.8),Vector2(0.4,0.4),Vector2(0.8,0.3)]))
	check(Form.contours(open).is_empty(),"open line is never silently filled")
	check(not Form._simple(PackedVector2Array([Vector2.ZERO,Vector2.ONE,Vector2(0,1),Vector2(1,0)])),"crossed contour falls back to tubes")
	check(not Form._simple(PackedVector2Array([Vector2.ZERO,Vector2(0.1,0),Vector2(0.2,0)])),"degenerate contour rejected")
	check(Form._simple(PackedVector2Array([Vector2(0,0),Vector2(0.8,0),Vector2(0.4,0.3),Vector2(0.8,0.8),Vector2(0,0.8)])),"simple concave contour supported")
	var pan = Data.new()
	pan.set_preset("pan")
	var center: Vector3 = pan.point_to_world(Vector2(0.5,0.37))
	var distance := INF
	for point in Form.samples(pan):
		distance = minf(distance,point.distance_to(center))
	check(distance < 0.14,"filled surface is not a hollow collision ring")
	var random := RandomNumberGenerator.new()
	random.seed = 8027
	for i in range(16):
		var data = Data.new()
		var poly := PackedVector2Array()
		for j in range(16):
			var angle := TAU*j/16.0
			var radius := random.randf_range(0.18,0.3)
			poly.append(Vector2(0.5,0.45)+Vector2(cos(angle),sin(angle))*radius)
		poly.append(poly[0])
		data.strokes.append(poly)
		check(Form.contours(data).size() == 1,"seeded arbitrary shape %d" % i)
		var mesh: MeshInstance3D = Form.build(data)
		check(mesh.mesh != null and mesh.has_node("ClosedContourFill"),"seeded runtime mesh %d" % i)
		mesh.free()

func _test_navigation() -> void:
	var arena = Arena.new()
	root.add_child(arena)
	await physics_frame
	for i in range(arena.spots.size()):
		var path: PackedVector2Array = arena.path_to(Vector3.ZERO,arena.spots[i])
		check(not path.is_empty(),"hiding spot %d is reachable" % i)
		var clear := true
		for point in path:
			var id: Vector2i = arena.nearest_id(Vector3(point.x,0,point.y))
			clear = clear and not arena.navigation.is_point_solid(id)
		check(clear,"hiding route %d avoids inflated obstacles" % i)
	arena.queue_free()
	await process_frame
