extends Node
## Consumes immutable facts from the match; all responses are cosmetic and bounded.
const Reaction=preload("res://scripts/smash/reaction.gd")
const Impact=preload("res://scripts/smash/impact_pool.gd")
const Audio=preload("res://scripts/smash/audio.gd")
const Art=preload("res://scripts/phase4/art.gd")
const Shapes=preload("res://scripts/smash/shapes.gd")
var game
var effects
var audio
var reactions: Array=[]
var ghosts: Array[Dictionary]=[]
var recent: Array[String]=[]
var active:=false
var enabled:=true
var last_kind:=""
var handled:=0

func _ready() -> void:
	game=get_parent(); call_deferred("initialize")

func initialize() -> void:
	if active or not is_instance_valid(game): return
	active=true
	effects=Impact.new(); game.add_child(effects)
	audio=Audio.new(); game.add_child(audio)
	for actor in game.fighters:
		var reaction=Reaction.new(); reaction.setup(actor); reactions.append(reaction)
		# Four reusable exit echoes. They use the last public contact transform, never a hidden position.
		var root:=Node3D.new(); root.name="SmashExitEcho%d"%actor.player_id; game.add_child(root)
		var toy: Node3D=Art.avatar(actor.tint); root.add_child(toy)
		var pupils: Array=[]
		for side in [-1,1]: pupils.append(Shapes.item(toy,Shapes.spiral(),Vector3(side*0.19,1.36,0.433),Vector3.ONE*0.145,Color("29444c")))
		for label in ["LeftEye","RightEye","LeftGlint","RightGlint"]: toy.get_node(label).visible=false
		root.visible=false
		ghosts.append({"root":root,"toy":toy,"pending":false,"age":0.0,"life":0.0,"base":Transform3D.IDENTITY,"side":1.0})
	game.smash_contact.connect(contact)
	game.smash_frame.connect(advance)
	game.smash_reset.connect(reset)
	game.smash_presentation=true

func contact(event: Dictionary) -> void:
	if not active or not enabled: return
	if not event.get("world_point") is Vector3 or not event.world_point.is_finite(): return
	var attacker: int=event.get("attacker_id",-1); var target: int=event.get("target_id",-1)
	if attacker<0 or attacker>=4: return
	if event.get("outcome") not in ["hit","blocked"]: return
	if event.outcome=="hit" and (target<0 or target>=4): return
	var key:="%d:%d:%d:%s"%[event.get("attack_id",0),attacker,target,event.outcome]
	if key in recent: return
	if recent.size()>=128: recent.pop_front()
	recent.append(key)
	if game.fighters[attacker].hidden_in_box or not game.fighters[attacker].visible: return
	var finisher:=false
	if event.outcome=="hit":
		if game.fighters[target].hidden_in_box or not game.fighters[target].visible: return
		finisher=bool(event.get("finisher",false))
	var kind: String="finish" if finisher else event.outcome
	var handling: String=event.get("handling","balanced")
	var normal: Vector3=event.get("normal",Vector3.BACK)
	if not normal.is_finite(): return
	last_kind=kind; handled+=1
	var reduced: bool=game.preferences.reduced_motion
	var amount: float=game.preferences.feedback_strength
	effects.language=game.preferences.language; effects.enabled=not reduced and amount>0
	effects.emit_contact(event.world_point,normal,kind,handling,amount)
	audio.volume=game.preferences.volume; audio.play_contact(kind,event.world_point,handling,int(event.attack_id))
	if event.outcome=="hit" and not reduced and amount>0:
		reactions[target].start(-normal,handling,int(event.attack_id),finisher)
		if finisher:
			var ghost:=ghosts[target]
			ghost.pending=true; ghost.age=0.0; ghost.life=0.54
			ghost.base=Transform3D(game.fighters[target].visual.global_basis.orthonormalized(),game.fighters[target].global_position)
			ghost.side=-1.0 if int(event.attack_id)%2 else 1.0

func advance(delta: float) -> void:
	if not active or not is_finite(delta) or delta<0: return
	var reduced: bool=game.preferences.reduced_motion or not enabled
	var amount: float=game.preferences.feedback_strength
	var in_world: bool=game.world_view_active() and not game.ui.modal.visible
	if reduced or amount<=0:
		effects.reset()
		for ghost in ghosts: ghost.life=0.0; ghost.pending=false; ghost.root.visible=false
	effects.advance(delta,game.camera.global_basis.orthonormalized())
	effects.visible=in_world
	for i in range(reactions.size()):
		reactions[i].advance(delta,reduced,amount)
		var ghost:=ghosts[i]
		if ghost.life<=0: continue
		ghost.age=minf(ghost.life,ghost.age+delta)
		var t: float=ghost.age/ghost.life
		# Show an echo only once authoritative elimination has hidden the real actor.
		ghost.root.visible=not game.fighters[i].visible and not game.fighters[i].hidden_in_box and in_world
		if t>=1: ghost.life=0; ghost.pending=false; ghost.root.visible=false; continue
		ghost.root.transform=ghost.base
		ghost.toy.position=Vector3(0,0.18*sin(t*PI),0)
		ghost.toy.rotation=Vector3(0.30*sin(t*PI),0,ghost.side*0.95*sin(t*PI))
		ghost.toy.scale=Vector3.ONE*(1-smoothstep(0.65,1.0,t))
		ghost.toy.get_node("LeftArm").rotation.z=-sin(t*PI)*1.0
		ghost.toy.get_node("RightArm").rotation.z=sin(t*PI)*1.0
		ghost.toy.get_node("LeftFoot").rotation.x=-sin(t*PI)*0.7
		ghost.toy.get_node("RightFoot").rotation.x=sin(t*PI)*0.7

func reset() -> void:
	recent.clear(); last_kind=""
	if is_instance_valid(effects): effects.reset()
	if is_instance_valid(audio): audio.reset()
	for reaction in reactions:
		if is_instance_valid(reaction): reaction.reset()
	for ghost in ghosts: ghost.life=0; ghost.pending=false; ghost.root.visible=false
