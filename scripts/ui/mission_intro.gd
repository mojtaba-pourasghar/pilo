class_name MissionIntro
extends CanvasLayer
## An animated mission briefing (docs/40 section 3): a painted scene with the real side-view characters moving in it,
## a slow camera drift, props that play frame animations (a flower opening, an egg shaking, a tandoor lighting...),
## captions, and the objective with an hourglass at the end. NOT a still picture. Always skippable (tap).
## Data-driven: the level's "intro" entry (see tools/levels/pair1_*.py):
##   backdrop  picture name in assets/art/v3 (or ""), duration (s), zoom [from, to], pan [dx, dy] in view fractions
##   actors    [{who, at:[x,y], scale, anim, flip}]            view fractions, side-view rig, `anim` is a SideRig animation
##   props     [{sheet, row, at:[x,y], scale, fps, from, loop}] frames of a cut sheet (assets/art/v3/cut/<sheet>)
##   events    [{t, actor, anim, move:[x,y], dur, flip} | {t, caption, dur} | {t, prop, show} | {t, objective}]

signal finished

const BACK := "res://assets/art/v3/%s.png"

var spec: Dictionary = {}
var game: Node
var _root: Control
var _back: TextureRect
var _stage: Node2D
var _bars: Array = []
var _actors: Array = []        ## [SideRig, Node2D holder]
var _props: Array = []         ## {node, frames, fps, loop, from, shown}
var _caption: Label
var _objective: Control
var _events: Array = []
var _t := 0.0
var _duration := 9.0
var _done := false
var _skip_hint: Label


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_duration = float(spec.get("duration", 9.0))
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	var view := get_viewport().get_visible_rect().size
	var art := String(spec.get("backdrop", ""))
	var keyed := art + "_k"
	var path := BACK % (keyed if ResourceLoader.exists(BACK % keyed) else art)
	var dark := ColorRect.new()
	dark.color = Color("1d2440")
	dark.set_anchors_preset(Control.PRESET_FULL_RECT)
	dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(dark)
	_back = TextureRect.new()
	_back.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_back.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if art != "" and ResourceLoader.exists(path):
		_back.texture = load(path)
	_root.add_child(_back)
	_back.size = view * 1.3
	_stage = Node2D.new()
	_stage.z_index = 5
	add_child(_stage)
	for a in spec.get("actors", []):
		var holder := Node2D.new()
		var rig := SideRig.make(String(a.who))
		rig.show_shadow = true
		rig.lock_anim = String(a.get("anim", "idle"))
		holder.add_child(rig)
		var sc := float(a.get("scale", 2.0))
		holder.scale = Vector2(-sc if bool(a.get("flip", false)) else sc, sc)
		holder.position = Vector2(float(a.at[0]) * view.x, float(a.at[1]) * view.y)
		holder.z_index = 5
		_stage.add_child(holder)           # in front of the picture, under the bars
		_actors.append([rig, holder])
	for p in spec.get("props", []):
		var frames: Array = SideRig.build_frames({"sheet": String(p.sheet), "row": int(p.row), "frames": range(int(p.get("n", 8)))})
		var sp := Sprite2D.new()
		sp.centered = false
		sp.visible = false
		sp.z_index = 4
		_stage.add_child(sp)
		_props.append({"node": sp, "frames": frames, "fps": float(p.get("fps", 8)), "loop": bool(p.get("loop", true)),
			"from": float(p.get("from", 0.0)), "at": Vector2(float(p.at[0]) * view.x, float(p.at[1]) * view.y),
			"scale": float(p.get("scale", 1.0)), "shown": bool(p.get("start_shown", false))})
	_events = (spec.get("events", []) as Array).duplicate(true)
	_events.sort_custom(func(a, b): return float(a.t) < float(b.t))
	# letterbox bars slide in
	for i in 2:
		var bar := ColorRect.new()
		bar.color = Color(0.04, 0.05, 0.1)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.size = Vector2(view.x, view.y * 0.12)
		bar.position = Vector2(0, -bar.size.y if i == 0 else view.y)
		bar.z_index = 100
		_root.add_child(bar)
		_bars.append(bar)
		var tw := bar.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(bar, "position:y", 0.0 if i == 0 else view.y - bar.size.y, 0.6)
	_caption = UIKit.make_label("", 34, Color("fff6dc"), 8, Color("1d2440"))
	_caption.size = Vector2(view.x * 0.82, 120)
	_caption.position = Vector2(view.x * 0.09, view.y * 0.74)
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.modulate.a = 0.0
	_caption.z_index = 110
	_root.add_child(_caption)
	_skip_hint = UIKit.make_label(Strings.t("intro_skip"), 22, Color(1, 1, 1, 0.8), 5, Color("1d2440"))
	_skip_hint.position = Vector2(view.x - 190.0, view.y * 0.88 + 6.0)
	_skip_hint.z_index = 110
	_root.add_child(_skip_hint)
	_root.gui_input.connect(_on_input)


func _on_input(event: InputEvent) -> void:
	if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed):
		finish()


func _process(delta: float) -> void:
	if _done:
		return
	_t += delta
	var view := get_viewport().get_visible_rect().size
	# the camera drifts: a slow zoom and pan of the picture
	var k := clampf(_t / _duration, 0.0, 1.0)
	var z: Array = spec.get("zoom", [1.0, 1.1])
	var zoom := lerpf(float(z[0]), float(z[1]), k)
	var pan: Array = spec.get("pan", [0.0, 0.0])
	_back.size = view * 1.15 * zoom
	_back.position = Vector2(-view.x * 0.075 * zoom + float(pan[0]) * view.x * k, -view.y * 0.075 * zoom + float(pan[1]) * view.y * k)
	# events
	while not _events.is_empty() and float(_events[0].t) <= _t:
		_run_event(_events.pop_front())
	for pr in _props:
		var sp: Sprite2D = pr.node
		var show: bool = pr.shown or _t >= pr.from and pr.from > 0.0
		sp.visible = show and not pr.frames.is_empty()
		if sp.visible:
			var n: int = pr.frames.size()
			var idx := int((_t - pr.from) * pr.fps)
			idx = idx % n if pr.loop else mini(idx, n - 1)
			var fr: Dictionary = pr.frames[maxi(idx, 0)]
			var tex: Texture2D = fr.tex
			if tex:
				sp.texture = tex
				var h: float = view.y * 0.30 * float(pr.scale)
				var s: float = h / maxf(float(tex.get_height()), 1.0)
				sp.scale = Vector2(s, s)
				sp.position = pr.at - Vector2(tex.get_width() * s * 0.5, tex.get_height() * s)
	for a in _actors:
		var rig: SideRig = a[0]
		var holder: Node2D = a[1]
		if holder.has_meta("goal"):
			var goal: Vector2 = holder.get_meta("goal")
			var spd: float = holder.get_meta("speed")
			holder.position = holder.position.move_toward(goal, spd * delta)
			if holder.position.distance_to(goal) < 2.0:
				holder.remove_meta("goal")
				if holder.has_meta("after"):
					rig.lock_anim = String(holder.get_meta("after"))
	if _t >= _duration:
		finish()


func _run_event(e: Dictionary) -> void:
	var view := get_viewport().get_visible_rect().size
	if e.has("caption"):
		_caption.text = Strings.t(String(e.caption))
		var tw := _caption.create_tween()
		tw.tween_property(_caption, "modulate:a", 1.0, 0.4)
		tw.tween_interval(float(e.get("dur", 2.4)))
		tw.tween_property(_caption, "modulate:a", 0.0, 0.5)
	if e.has("actor"):
		var a: Array = _actors[int(e.actor)]
		var rig: SideRig = a[0]
		var holder: Node2D = a[1]
		if e.has("anim"):
			rig.lock_anim = String(e.anim)
		if e.has("flip"):
			var sc := absf(holder.scale.x)
			holder.scale = Vector2(-sc if bool(e.flip) else sc, holder.scale.y)
		if e.has("move"):
			var goal := Vector2(float(e.move[0]) * view.x, float(e.move[1]) * view.y)
			var dur := maxf(float(e.get("dur", 2.0)), 0.1)
			holder.set_meta("goal", goal)
			holder.set_meta("speed", holder.position.distance_to(goal) / dur)
			if e.has("after"):
				holder.set_meta("after", String(e.after))
			if goal.x != holder.position.x and not e.has("flip"):
				var sc2 := absf(holder.scale.x)
				holder.scale = Vector2(sc2 if goal.x > holder.position.x else -sc2, holder.scale.y)
	if e.has("prop"):
		var pr: Dictionary = _props[int(e.prop)]
		pr.shown = bool(e.get("show", true))
		if e.has("restart"):
			pr.from = _t
	if e.has("objective"):
		_show_objective(String(e.get("text", "")))


func _show_objective(text_key: String) -> void:
	var view := get_viewport().get_visible_rect().size
	_objective = Control.new()
	_objective.z_index = 120
	_root.add_child(_objective)
	var plate := ColorRect.new()
	plate.color = Color(0.1, 0.16, 0.32, 0.88)
	plate.size = Vector2(view.x * 0.6, 84)
	plate.position = Vector2(view.x * 0.2, view.y * 0.12 + 20.0)
	_objective.add_child(plate)
	var glass := Label.new()
	glass.text = "⌛"
	glass.add_theme_font_size_override("font_size", 52)
	glass.position = plate.position + Vector2(18, 4)
	_objective.add_child(glass)
	var label := UIKit.make_label(Strings.t(text_key), 34, Color("ffd34d"), 6, Color("1d2440"))
	label.size = Vector2(plate.size.x - 110.0, 80)
	label.position = plate.position + Vector2(96, 10)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_objective.add_child(label)
	_objective.modulate.a = 0.0
	_objective.create_tween().tween_property(_objective, "modulate:a", 1.0, 0.5)


func finish() -> void:
	if _done:
		return
	_done = true
	var tw := create_tween()
	tw.tween_property(_root, "modulate:a", 0.0, 0.35)
	tw.parallel().tween_property(_stage, "modulate:a", 0.0, 0.35)
	tw.tween_callback(func():
		finished.emit()
		queue_free())
