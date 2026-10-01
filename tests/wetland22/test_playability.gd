extends SceneTree
## Actual 60 Hz Fighter.step / move_and_slide regressions; no production geometry edits.
const Scene = preload("res://scenes/phase21.tscn")
const Fighter = preload("res://scripts/phase4/fighter.gd")
const ResetReady = preload("res://tests/seed21/round_ready.gd")
const DT := 1.0 / 60.0
const STALL_DISTANCE := 0.002
const MAX_STALL := 8
const MAX_ROUTE_DEVIATION := 0.20
const CORNER_TICKS := 90
const WAYPOINT_TICKS := 40
const RETREAT_TICKS := 40
const APPROACH_TICKS := 60
const SLIDE_TICKS := 90
const MIN_SLIDE_PROGRESS := 5.0
# Fixed legal positions from independent runtime QA. Never search for a pair by
# asking the visibility predicate under test, which could silently drop failures.
const BLOCKED_PAIRS := [
	[Vector3(-0.760852, 0, -3.665330), Vector3(-3.242732, 0, -8.888939)],
	[Vector3(-1.492465, 0, -3.858809), Vector3(-2.757716, 0, -9.404163)],
	[Vector3(-2.166724, 0, -4.173003), Vector3(-2.166724, 0, -9.826997)],
	[Vector3(-2.757716, 0, -4.595837), Vector3(-1.492465, 0, -10.141191)],
	[Vector3(-3.242732, 0, -5.111061), Vector3(-0.760852, 0, -10.334670)],
	[Vector3(-3.242732, 0, -8.888939), Vector3(-0.760852, 0, -3.665330)],
	[Vector3(-2.757716, 0, -9.404163), Vector3(-1.492465, 0, -3.858809)],
	[Vector3(-2.166724, 0, -9.826997), Vector3(-2.166724, 0, -4.173003)],
]
var game
var actor
var checks := 0
var failures := 0
var last_step_tick := -1
var stepped_once_per_tick := true
var records: Array = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String, detail: Dictionary = {}) -> void:
	checks += 1
	if not ok: failures += 1
	records.append({"pass": ok, "label": label, "detail": detail})
	print(("PASS: " if ok else "FAIL: ") + label + (" " + JSON.stringify(detail) if not ok else ""))

func horizontal(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)

func step(wish: Vector3, dash: bool = false) -> bool:
	await physics_frame
	var tick := Engine.get_physics_frames()
	stepped_once_per_tick = stepped_once_per_tick and tick > last_step_tick
	last_step_tick = tick
	if dash: actor.begin_dash(wish)
	var dashing: bool = actor.dash_time > 0
	actor.step(DT, wish, wish)
	return dashing

func park(at: Vector3) -> void:
	actor.reset_fight(at)
	# The negative controls have a separate body and world, not a game fighter.
	if actor == game.fighters[0]:
		await ResetReady.positions(game)
	else:
		actor.force_update_transform()
		for tick in range(8):
			var physical: Transform3D = PhysicsServer3D.body_get_state(actor.get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM)
			if physical.is_equal_approx(actor.global_transform): break
			await physics_frame
			await process_frame
	for tick in range(4): await step(Vector3.ZERO)

func move_segment(target: Vector3, limit: int, dash: bool = false) -> Dictionary:
	var origin := horizontal(actor.position)
	var line := horizontal(target) - origin
	var stall := 0
	var result := {"reached": false, "ticks": 0, "stall": 0, "deviation": 0.0, "height": 0.0, "dash_ticks": 0}
	for tick in range(limit):
		var offset: Vector3 = target - actor.position
		offset.y = 0
		if offset.length() < 0.11: break
		var before := horizontal(actor.position)
		if await step(offset.normalized(), dash and tick == 0): result.dash_ticks += 1
		var after := horizontal(actor.position)
		stall = stall + 1 if before.distance_to(after) < STALL_DISTANCE else 0
		result.ticks += 1
		result.stall = maxi(result.stall, stall)
		result.deviation = maxf(result.deviation, absf(line.cross(after - origin)) / line.length())
		result.height = maxf(result.height, absf(actor.position.y))
	result.reached = horizontal(actor.position).distance_to(horizontal(target)) < 0.11
	return result

func segment_ok(result: Dictionary, dash: bool = false) -> bool:
	return result.reached and result.stall <= MAX_STALL and result.deviation <= MAX_ROUTE_DEVIATION and result.height < 0.12 and (not dash or result.dash_ticks > 0)

func route(label: String, points: Array, limit: int, dash: bool = false) -> void:
	await park(points[0])
	var passed := true
	var segments: Array = []
	for index in range(1, points.size()):
		# Reset cooldown/momentum so BOTH dash directions exercise an actual dash.
		# Walking circuits retain momentum across their waypoints and reversals.
		if dash: await park(points[index - 1])
		var result := await move_segment(points[index], limit, dash)
		segments.append(result)
		passed = passed and segment_ok(result, dash)
	check(passed, label, {"segments": segments})

func contact_start(angle: float) -> Vector3:
	var outward := Vector3(cos(angle), 0, sin(angle))
	return Vector3(3.5 * outward.x, 0, -7 + 3.0 * outward.z) + outward * 0.9

func approach(outward: Vector3) -> bool:
	var hit_north := false
	for tick in range(APPROACH_TICKS):
		await step(-outward)
		for index in range(actor.get_slide_collision_count()):
			var hit = actor.get_slide_collision(index).get_collider()
			if game.arena.get_node("Cover_reed_north").is_ancestor_of(hit): hit_north = true
	return hit_north

func slide(tangent: Vector3, wish: Vector3) -> Dictionary:
	var contact: Vector3 = actor.position
	var stall := 0
	var result := {"progress": 0.0, "stall": 0, "height": 0.0}
	for tick in range(SLIDE_TICKS):
		var before := horizontal(actor.position)
		await step(wish)
		stall = stall + 1 if before.distance_to(horizontal(actor.position)) < STALL_DISTANCE else 0
		result.stall = maxi(result.stall, stall)
		result.height = maxf(result.height, absf(actor.position.y))
	result.progress = (actor.position - contact).dot(tangent)
	return result

func slide_ok(result: Dictionary) -> bool:
	return result.progress > MIN_SLIDE_PROGRESS and result.stall <= MAX_STALL and result.height < 0.12

func sight(label: String, hunter: Vector3, hider: Vector3, expected_clear: bool) -> void:
	game.rules.phase = game.Rules.Phase.SEEK
	game.rules.seeker = 0
	game.rules.alive.assign([true, true, false, false])
	game.rules.grace.assign([0.0, 0.0, 0.0, 0.0])
	game.fighters[0].reset_fight(hunter)
	game.fighters[1].reset_fight(hider)
	await ResetReady.positions(game)
	game.rig.face(hider - hunter)
	game.rig.follow(game.fighters[0], 0, false, true)
	var eye := hunter + Vector3.UP * 1.48
	var target := hider + Vector3.UP * 1.1
	var detail := {
		"hunter_free": game.hiding.free_point(hunter, 0),
		"hider_free": game.hiding.free_point(hider, 1),
		"range": eye.distance_to(target),
		"ray_clear": game.arena.clear_ray(eye, target),
	}
	game._scan_visible_hiders()
	detail.discovered = game.rules.phase != game.Rules.Phase.SEEK
	check(detail.hunter_free and detail.hider_free and detail.range < 6.0 and detail.ray_clear == expected_clear and detail.discovered == expected_clear, label, detail)

func box(parent: Node3D, at: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = at
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)
	return body

func negative_controls() -> void:
	# Disposable independent World3D: no collider is ever inserted into the game.
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	root.add_child(viewport)
	var fixture := Node3D.new()
	viewport.add_child(fixture)
	box(fixture, Vector3(0, -0.2, 0), Vector3(40, 0.4, 40))
	actor = Fighter.new()
	fixture.add_child(actor)
	var a := Vector3(4.2, 0, -5.35)
	var b := Vector3(2.3, 0, -3.5)
	await park(a)
	check(segment_ok(await move_segment(b, CORNER_TICKS)), "control: unobstructed throwaway route passes the same movement predicate")
	var old_box := box(fixture, Vector3(0, 1, -7), Vector3(7, 2, 6))
	await park(a)
	var blocked := await move_segment(b, CORNER_TICKS)
	check(not segment_ok(blocked) and blocked.deviation > MAX_ROUTE_DEVIATION, "control: restored square corner is rejected by the same route predicate", blocked)
	old_box.queue_free()
	await process_frame
	# A wall blocks the exact same steering call, proving arrival/tick bounds fail.
	box(fixture, Vector3(0, 1, 0), Vector3(0.5, 2, 20))
	await park(Vector3(-2, 0, 0))
	var stuck := await move_segment(Vector3(2, 0, 0), CORNER_TICKS)
	check(not segment_ok(stuck) and not stuck.reached and stuck.stall > MAX_STALL, "control: stuck route exhausts its tick budget and is rejected", stuck)
	await park(Vector3(-0.65, 0, 0))
	var stuck_slide := await slide(Vector3.RIGHT, Vector3.RIGHT)
	check(not slide_ok(stuck_slide) and stuck_slide.stall > MAX_STALL, "control: blocked contact escape is rejected by the same slide predicate", stuck_slide)
	viewport.queue_free()
	await process_frame
	actor = game.fighters[0]

func run() -> void:
	check(Engine.physics_ticks_per_second == 60, "fixture runs at the production 60 Hz physics rate")
	game = Scene.instantiate()
	root.add_child(game)
	game.automated = true
	await process_frame
	await process_frame
	await physics_frame
	game.set_process(false)
	game.get_node("ToyStudio").set_process(false)
	game.return_to_menu()
	game.select_map("reedwater_bend")
	await process_frame
	await physics_frame
	game.rng.seed = 8027
	game.start_match(true)
	await ResetReady.wait(game)
	game.accept_drawing()
	game.rules.tick(game.rules.hiding_seconds + 0.01)
	game.set_physics_process(false)
	for index in range(4): game.fighters[index].reset_fight(Vector3(-18 + index * 1.4, 0, 14))
	await ResetReady.positions(game)
	actor = game.fighters[0]
	var descriptor: Dictionary = game.round_layout.descriptor
	check(game.arena.map_id == "reedwater_bend" and descriptor.id == "RW-v1-2" and descriptor.seed == 8027 and descriptor.round == 0 and actor.get_script() == Fighter, "fixture uses the real Fighter and deterministic Reedwater seed8027 round0", descriptor)

	for sx in [-1, 1]:
		for sz in [-1, 1]:
			var a := Vector3(sx * 4.2, 0, -7 + sz * 1.65)
			var b := Vector3(sx * 2.3, 0, -7 + sz * 3.5)
			await route("open corner %d/%d walks both directions" % [sx, sz], [a, b, a], CORNER_TICKS)
			await route("open corner %d/%d dashes both directions" % [sx, sz], [a, b, a], CORNER_TICKS, true)
	var points: Array = []
	for index in range(33):
		var angle := TAU * index / 32.0
		points.append(Vector3(4.05 * cos(angle), 0, -7 + 3.55 * sin(angle)))
	await route("clockwise perimeter reaches all 32 waypoints", points, WAYPOINT_TICKS)
	points.reverse()
	await route("counterclockwise perimeter reaches all 32 waypoints", points, WAYPOINT_TICKS)

	for index in range(16):
		var angle := TAU * index / 16.0
		var outward := Vector3(cos(angle), 0, sin(angle))
		var start := contact_start(angle)
		await park(start)
		var hit_north := await approach(outward)
		var retreat := await move_segment(start, RETREAT_TICKS)
		check(hit_north and segment_ok(retreat), "north contact %d retreats within 40 physics ticks" % index, retreat)
	for direction in [-1, 1]:
		for index in range(32):
			var angle := TAU * index / 32.0
			var outward := Vector3(cos(angle), 0, sin(angle))
			await park(contact_start(angle))
			var hit_north := await approach(outward)
			var tangent: Vector3 = Vector3(-outward.z, 0, outward.x) * direction
			var result := await slide(tangent, (tangent - outward * 0.25).normalized())
			check(hit_north and slide_ok(result), "north contact %d/%d slides without sustained snag" % [index, direction], result)
	for sx in [-1, 1]:
		await sight("south open corner %d discovers an in-range hider" % sx, Vector3(sx * 4.0, 0, -5.8), Vector3(sx * 1.8, 0, -3.65), true)
		await sight("north open corner %d discovers an in-range hider" % sx, Vector3(sx * 4.0, 0, -8.2), Vector3(sx * 1.8, 0, -10.5), true)
	for index in range(BLOCKED_PAIRS.size()):
		await sight("core blocks discovery from legal in-range pair %d" % index, BLOCKED_PAIRS[index][0], BLOCKED_PAIRS[index][1], false)
	await negative_controls()
	check(stepped_once_per_tick, "every real Fighter.step occurs on a distinct physics tick")
	check(checks == 109, "all 102 gameplay cases, four negative/control cases and three fixture checks ran")
	var file := FileAccess.open("res://ci-artifacts/wetland22-playability.json", FileAccess.WRITE)
	if file == null:
		check(false, "playability evidence file is writable")
	else:
		file.store_string(JSON.stringify({"checks": checks, "failures": failures, "records": records}, "  "))
		file.close()
	game.queue_free()
	await process_frame
	print("NORTH_REED22_PLAYABILITY_RESULT: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
