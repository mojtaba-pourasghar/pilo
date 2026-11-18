class_name SpriteRig
extends CharacterRig
## A character from drawn frames (approved concept art): Arsam (assets/art/p1_heroes) and Pilo
## the fox (assets/art/p2_companions). Pivot: middle of the feet; pictures face right and the
## owner flips with scale.x (flip_h). Each state is a list of frames played at its own speed;
## a missing state falls back to a near one. The round shadow under the feet is drawn here.

const HERO := "res://assets/art/p1_heroes/p1_hero_arsam_"
const FOX := "res://assets/art/p2_companions/p2_companion_pilo_"

## state -> [frames, fps]; a frame is [path, figure height in its picture (px)].
const PRESETS := {
	"arsam": {
		"height": 134.0,
		"states": {
			"idle": [[["idle_f1", 455], ["idle_f2", 456], ["idle_f3", 457], ["idle_f4", 456], ["idle_f5", 439], ["idle_f6", 455]], 8],
			"walk": [[["walk_f1", 455], ["walk_f2", 455], ["walk_f3", 455], ["walk_f4", 455], ["walk_f5", 455], ["walk_f6", 455], ["walk_f7", 455], ["walk_f8", 455]], 12],
			"run": [[["run_f1", 440], ["run_f2", 440], ["run_f3", 440], ["run_f4", 440], ["run_f5", 440], ["run_f6", 440], ["run_f7", 440], ["run_f8", 440]], 14],
			"jump": [[["jump_concept", 692]], 1],
			"fall": [[["jump_concept", 692]], 1],
			"glide": [[["jump_concept", 692]], 1],
			"hurt": [[["hurt_concept", 648]], 1],
			"crouch": [[["crouch_concept", 820]], 1],
			"crawl": [[["crouch_concept", 820]], 1],
			"dash": [[["roll_concept", 700]], 1],
			"celebrate": [[["victory_concept", 690]], 1],
			"shoot": [[["aim_concept", 710]], 1],
			"skid": [[["run_f1", 440]], 1],
		},
		"prefix": HERO, "cells": true,
	},
	"fox": {
		"height": 74.0,
		"states": {
			"idle": [[["idle_concept", 377]], 1],
			"run": [[["walk_concept", 525], ["walk_b_concept", 377]], 6],
			"walk": [[["walk_concept", 525], ["walk_b_concept", 377]], 5],
			"fly": [[["jump_concept", 395]], 1],
			"jump": [[["jump_concept", 395]], 1],
			"dash": [[["dash_concept", 467]], 1],
			"happy": [[["happy_concept", 426]], 1],
			"sad": [[["sleep_concept", 337]], 1],
			"sleep": [[["sleep_concept", 337]], 1],
			"carry": [[["jump_concept", 395]], 1],
		},
		"prefix": FOX, "cells": false,
	},
}

var preset := "arsam"
var glow := Color(1, 1, 1, 0)        ## Pilo's time glow (pilo_companion sets it)
var show_shadow := true
var feet := Vector2.ZERO

var _frames := {}
var _frame_time := 0.0
var _frame := 0
var _last_state := ""


static func make(preset_name: String) -> SpriteRig:
	var rig := SpriteRig.new()
	rig.preset = preset_name
	return rig


func _ready() -> void:
	var p: Dictionary = PRESETS[preset]
	for st in p.states:
		var list: Array = []
		for f in p.states[st][0]:
			var path := String(p.prefix) + String(f[0]) + ".png"
			if ResourceLoader.exists(path):
				list.append([load(path), float(f[1])])
		if not list.is_empty():
			_frames[st] = [list, float(p.states[st][1])]


func has_cycle(name: String) -> bool:
	return _frames.has(name)


func set_hue_shift(_value: float) -> void:
	pass


func _current_state() -> String:
	if _frames.has(state):
		return state
	match state:
		"skid", "walk":
			return "run" if _frames.has("run") else "idle"
		"fall", "glide", "swim", "fly":
			return "jump" if _frames.has("jump") else "idle"
		_:
			return "idle"


func _process(delta: float) -> void:
	t += delta
	var st := _current_state()
	if st != _last_state:
		_last_state = st
		_frame = 0
		_frame_time = 0.0
	var entry: Array = _frames.get(st, [[], 1.0])
	var fps: float = entry[1]
	if st == "run" or st == "walk":
		# the stride follows the speed a little
		fps *= clampf(absf(speed) / maxf(run_speed, 1.0) * 1.3, 0.6, 1.4)
	_frame_time += delta * fps
	if entry[0].size() > 0:
		_frame = int(_frame_time) % entry[0].size()
	phase = _frame_time * PI * 0.5
	queue_redraw()


func _draw() -> void:
	var p: Dictionary = PRESETS[preset]
	if show_shadow:
		draw_set_transform(Vector2(0, 2), 0.0, Vector2(1.0, 0.25))
		draw_circle(Vector2.ZERO, float(p.height) * 0.22, Color(0, 0, 0, 0.25))
		draw_set_transform(Vector2.ZERO)
	var entry: Array = _frames.get(_current_state(), [])
	if entry.is_empty() or entry[0].is_empty():
		return
	var f: Array = entry[0][_frame % entry[0].size()]
	var tex: Texture2D = f[0]
	var k: float = float(p.height) / float(f[1])
	var size := tex.get_size() * k
	if glow.a > 0.01:
		draw_circle(Vector2(0, -size.y * 0.45), size.x * 0.45, Color(glow, glow.a * 0.35))
	draw_texture_rect(tex, Rect2(Vector2(-size.x * 0.5, -size.y + 2.0), size), false)
