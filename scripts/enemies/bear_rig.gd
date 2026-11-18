class_name BearRig
extends Node2D
## The Old Bear, cut-out animation on a Skeleton2D (assets/art/p5_enemies/bear/: separate parts).
## Bones: hip (root) -> torso; neck -> head; tail; front leg (upper arm -> forearm/paw);
## back leg (thigh -> lower leg); the far-side legs are the same parts, darker, behind the body.
## The heart crystal sits in the socket on the torso (the weak point once the bear is calm).
## Pictures face right; `facing` -1 mirrors the whole rig. Origin = between the feet, on the floor.

const DIR := "res://assets/art/p5_enemies/bear/"
## Scale from art pixels to the game (the bear stands ~330 px tall).
const K := 0.4

var facing := 1.0
var head_mood := "neutral":          ## neutral | angry | calm
	set(value):
		head_mood = value
		_update_head()
var walk := 0.0                      ## 0..1 how much the legs swing
var raise := 0.0                     ## 0..1 front paw lifted for a slam
var crouch := 0.0                    ## 0..1 dazed / low
var smoke := 0.0                     ## 0..1 purple smoke (phase 2)
var heart_open := 0.0                ## 0..1 the crystal shows and glows
var flash := 0.0

var skeleton: Skeleton2D
var _bones := {}
var _sprites := {}
var _heads := {}
var _smoke_sprites: Array = []
var _t := 0.0


func _ready() -> void:
	skeleton = Skeleton2D.new()
	add_child(skeleton)
	var hip := _bone("hip", skeleton, Vector2(0, -560))
	# far side first (drawn behind)
	var back_far := _bone("back_far", hip, Vector2(-250, 120))
	_part(back_far, "bear_thigh.png", Vector2(0, 80), true)
	var back_far_low := _bone("back_far_low", back_far, Vector2(10, 230))
	_part(back_far_low, "bear_lower_leg_foot.png", Vector2(20, 60), true)
	var front_far := _bone("front_far", hip, Vector2(300, 80))
	_part(front_far, "bear_upper_arm_L.png", Vector2(0, 90), true)
	var front_far_low := _bone("front_far_low", front_far, Vector2(20, 240))
	_part(front_far_low, "bear_forearm_paw_R.png", Vector2(90, 110), true, 0.0)
	var tail := _bone("tail", hip, Vector2(-450, -120))
	_part(tail, "bear_tail.png", Vector2(-60, 0))
	_part(hip, "bear_torso.png", Vector2(0, -20))
	var heart := Sprite2D.new()
	heart.texture = _tex("bear_heart_crystal.png")
	heart.position = Vector2(300, -60)
	heart.scale = Vector2(0.62, 0.62)
	hip.add_child(heart)
	_sprites["heart"] = heart
	var back := _bone("back", hip, Vector2(-230, 140))
	_part(back, "bear_thigh.png", Vector2(0, 80))
	var back_low := _bone("back_low", back, Vector2(10, 230))
	_part(back_low, "bear_lower_leg_foot.png", Vector2(20, 60))
	var front := _bone("front", hip, Vector2(390, 110))
	_part(front, "bear_upper_arm_R.png", Vector2(0, 80))
	var front_low := _bone("front_low", front, Vector2(20, 230))
	_part(front_low, "bear_forearm_paw_R.png", Vector2(90, 110), false, 0.0)
	var neck := _bone("neck", hip, Vector2(420, -150))
	for mood in ["neutral", "angry", "calm"]:
		var file: String = {"neutral": "bear_head_neutral.png", "angry": "bear_head_angry_p2.png", "calm": "bear_head_calm_p3.png"}[mood]
		var s := Sprite2D.new()
		s.texture = _tex(file)
		s.position = Vector2(120, -60)
		s.visible = mood == head_mood
		neck.add_child(s)
		_heads[mood] = s
	for i in 4:
		var s := Sprite2D.new()
		s.texture = _tex("bear_smoke_%d.png" % (i + 1))
		s.modulate = Color(1, 1, 1, 0)
		s.position = Vector2(-300 + i * 220, -260 - (i % 2) * 120)
		hip.add_child(s)
		_smoke_sprites.append(s)
	skeleton.scale = Vector2(K, K)


func _bone(bone_name: String, parent: Node, at: Vector2) -> Bone2D:
	var bone := Bone2D.new()
	bone.name = bone_name
	bone.position = at
	bone.set_autocalculate_length_and_angle(false)
	bone.set_length(100.0)
	parent.add_child(bone)
	bone.rest = bone.transform
	_bones[bone_name] = bone
	return bone


func _part(bone: Bone2D, file: String, offset: Vector2, far := false, rot_deg := 0.0) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = _tex(file)
	s.position = offset
	s.rotation_degrees = rot_deg
	if far:
		s.modulate = Color(0.62, 0.55, 0.5)
	bone.add_child(s)
	_sprites[bone.name] = s
	return s


func _tex(file: String) -> Texture2D:
	return load(DIR + file) if ResourceLoader.exists(DIR + file) else null


func _update_head() -> void:
	for mood in _heads:
		_heads[mood].visible = mood == head_mood


func _process(delta: float) -> void:
	_t += delta
	scale.x = absf(scale.x) * signf(facing if facing != 0.0 else 1.0)
	var step := sin(_t * 9.0) * walk
	var breathe := sin(_t * 2.2) * 6.0
	_bones.hip.position = Vector2(0, -560 + breathe + crouch * 70.0 - absf(step) * 12.0)
	_bones.hip.rotation = deg_to_rad(-raise * 10.0 + crouch * 4.0)
	_bones.back.rotation = deg_to_rad(step * 22.0)
	_bones.back_far.rotation = deg_to_rad(-step * 22.0)
	_bones.back_low.rotation = deg_to_rad(maxf(0.0, -step) * 18.0)
	_bones.back_far_low.rotation = deg_to_rad(maxf(0.0, step) * 18.0)
	_bones.front.rotation = deg_to_rad(-step * 20.0 - raise * 75.0)
	_bones.front_far.rotation = deg_to_rad(step * 20.0)
	_bones.front_low.rotation = deg_to_rad(-raise * 40.0)
	_bones.neck.rotation = deg_to_rad(sin(_t * 1.6) * 3.0 - raise * 12.0 + crouch * 14.0)
	_bones.tail.rotation = deg_to_rad(sin(_t * 3.0) * 10.0)
	for i in _smoke_sprites.size():
		var s: Sprite2D = _smoke_sprites[i]
		s.modulate.a = smoke * (0.55 + 0.25 * sin(_t * 2.0 + i))
		s.position.y += sin(_t * 1.5 + i) * 0.4
		s.rotation = sin(_t * 0.8 + i) * 0.2
	var heart: Sprite2D = _sprites.heart
	heart.modulate = Color(1.0 + heart_open * 0.6 * (0.5 + 0.5 * sin(_t * 6.0)), 1.0, 1.0, 0.25 + heart_open * 0.75)
	heart.scale = Vector2.ONE * (0.55 + heart_open * 0.12)
	flash = maxf(0.0, flash - delta * 3.0)
	modulate = Color(1.0 + flash, 1.0 + flash, 1.0 + flash)


## Where the heart crystal is now, in global coordinates (the weak point).
func heart_position() -> Vector2:
	return _sprites.heart.global_position
