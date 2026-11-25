class_name ExitPortal
extends Area2D
## The time gate at the end of a level, drawn in code: a mossy stone arch with a clock on
## top and a swirling portal inside. While locked (a friend still trapped, or the time key
## not found yet) wooden bars and a padlock close it and the clock stands still.
## Origin = top-left of the cell the gate stands in (its feet on the ground below).

const OUTLINE := Color("3b2418")

var game: Node
var locked := false
## Format 4: the gate has two locks, one for the past key (blue) and one for the present key
## (orange). They light up as the keys come in; the gate opens with both.
var two_locks := false
var lock_past := false
var lock_present := false
const KEYHOLE := {
	"past": "res://assets/art/p9_ui/p9_ui_badge_keyhole_past.png",
	"present": "res://assets/art/p9_ui/p9_ui_badge_keyhole_present.png",
}
var _keyholes := {}

var _t := 0.0
var _open := 1.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	z_index = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(64, 128)
	shape.shape = rect
	shape.position = Vector2(32, 0)
	add_child(shape)
	body_entered.connect(_on_body_entered)
	set_locked(locked)


func set_locked(value: bool) -> void:
	var was := locked
	locked = value
	if was and not value and is_inside_tree():
		AudioManager.play_sfx("door")
		FX.burst(get_parent(), global_position + Vector2(32, -20), Color(0.75, 0.6, 1.0), 20)
	_open = 0.0 if locked else 1.0


func set_key_locks(past: bool, present: bool) -> void:
	if two_locks and is_inside_tree():
		if past and not lock_past or present and not lock_present:
			AudioManager.play_sfx("key", 0.9)
			FX.burst(get_parent(), global_position + Vector2(32 + (-34 if past and not lock_past else 34), -150), Color(1, 0.9, 0.5), 12)
	lock_past = past
	lock_present = present


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		game.on_exit_reached()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	_draw_gate()
	if two_locks:
		# the two keyholes over the arch: dim until their key is in
		for i in 2:
			var key: String = ["past", "present"][i]
			if not _keyholes.has(key) and ResourceLoader.exists(KEYHOLE[key]):
				_keyholes[key] = load(KEYHOLE[key])
			var tex: Texture2D = _keyholes.get(key)
			if tex == null:
				continue
			var filled: bool = lock_past if i == 0 else lock_present
			var h := 70.0
			var w := tex.get_width() * h / tex.get_height()
			var c := Vector2(32 + (-38 if i == 0 else 38), -150 + sin(_t * 2.0 + i) * 2.0)
			if filled:
				draw_circle(c, 40.0, Color(0.45, 0.75, 1.0, 0.35) if i == 0 else Color(1.0, 0.7, 0.3, 0.35))
			draw_texture_rect(tex, Rect2(c - Vector2(w, h) * 0.5, Vector2(w, h)), false, Color.WHITE if filled else Color(0.45, 0.45, 0.55, 0.9))


func _draw_gate() -> void:
	# v3 levels: the painted gate (docs/44, v3f_i_markers row 1): closed, opening, then the light breathing inside
	if game != null and game.get("data") is Dictionary and game.data.has("terrain"):
		var idx := 0 if locked else 5 + int(_t * 8.0) % 7
		var tex := SideRig.pic("v3f_i_markers", 1, idx)
		if tex != null:
			var gh := 230.0
			var gw := tex.get_width() * gh / tex.get_height()
			draw_texture_rect(tex, Rect2(Vector2(32 - gw * 0.5, 66 - gh), Vector2(gw, gh)), false)
			return
	var texture := WorldArt.tex("time_gate", "locked" if locked else "open")
	if texture:
		# the rendered gate, feet on the ground under it; the portal glows and breathes
		var h := 262.0
		var w := texture.get_width() * h / texture.get_height()
		var center := Vector2(32, 64 - h * 0.42)
		if not locked:
			draw_circle(center, 62.0 + sin(_t * 3.0) * 6.0, Color(0.7, 0.55, 1.0, 0.18))
		draw_texture_rect(texture, Rect2(Vector2(32 - w * 0.5, 64 - h), Vector2(w, h)), false)
		if not locked:
			for i in 3:
				var start := _t * (1.4 + i * 0.5) + i * 2.0
				draw_arc(center + Vector2(0, 8), 16.0 + i * 11.0, start, start + 2.4, 20, Color(1, 0.9, 1, 0.35 - i * 0.08), 4.0)
		return
	var stone := Color("a7acb6")
	var stone_dark := Color("7b818c")
	var base := Vector2(32, 64)          # middle of the ground under the gate
	# portal swirl inside the arch
	var center := base + Vector2(0, -78)
	if not locked:
		draw_circle(center, 50.0, Color(0.55, 0.45, 1.0, 0.25))
		for i in 4:
			var start := _t * (1.6 + i * 0.4) + i * 1.7
			draw_arc(center, 14.0 + i * 10.0, start, start + 3.6, 24, Color(0.8, 0.7, 1.0, 0.85 - i * 0.15), 6.0)
		draw_circle(center, 10.0, Color(1, 0.95, 1, 0.9))
	else:
		draw_circle(center, 46.0, Color(0.15, 0.12, 0.25, 0.85))
	# the arch: two pillars and a rounded top
	for side in [-1.0, 1.0]:
		var pillar := Rect2(base + Vector2(side * 50.0 - 13.0, -128), Vector2(26, 128))
		draw_rect(pillar.grow(3), OUTLINE)
		draw_rect(pillar, stone)
		for k in 4:
			draw_line(pillar.position + Vector2(0, 32 * k), pillar.position + Vector2(26, 32 * k), stone_dark, 2.0)
		draw_circle(pillar.position + Vector2(6, 10), 6.0, Color("6cc24a"))
	draw_arc(base + Vector2(0, -128), 50.0, PI, TAU, 32, OUTLINE, 32.0)
	draw_arc(base + Vector2(0, -128), 50.0, PI, TAU, 32, stone, 26.0)
	for k in 7:
		var a := PI + PI * k / 6.0
		draw_line(base + Vector2(0, -128) + Vector2(cos(a), sin(a)) * 37.0, base + Vector2(0, -128) + Vector2(cos(a), sin(a)) * 63.0, stone_dark, 2.0)
	# clock on the keystone
	var clock := base + Vector2(0, -186)
	draw_circle(clock, 22.0, OUTLINE)
	draw_circle(clock, 19.0, Color("ffc928"))
	draw_circle(clock, 15.0, Color("fff8e1"))
	for k in 12:
		var a := k * TAU / 12.0
		draw_circle(clock + Vector2(cos(a), sin(a)) * 12.0, 1.4, OUTLINE)
	var turn := 0.0 if locked else _t
	draw_line(clock, clock + Vector2(sin(turn * 2.0), -cos(turn * 2.0)) * 11.0, OUTLINE, 2.0)
	draw_line(clock, clock + Vector2(sin(turn / 6.0), -cos(turn / 6.0)) * 7.0, OUTLINE, 3.0)
	if locked:
		# wooden bars and a padlock
		for x in [-26.0, -9.0, 8.0, 25.0]:
			var bar := Rect2(base + Vector2(x - 6, -124), Vector2(12, 124))
			draw_rect(bar.grow(2), OUTLINE)
			draw_rect(bar, Color("8c5a2e"))
			draw_line(bar.position + Vector2(3, 4), bar.position + Vector2(3, 120), Color("b07a45"), 2.0)
		var lock := base + Vector2(0, -60)
		draw_arc(lock + Vector2(0, -12), 10.0, PI, TAU, 16, OUTLINE, 6.0)
		draw_rect(Rect2(lock + Vector2(-15, -12), Vector2(30, 26)), OUTLINE)
		draw_rect(Rect2(lock + Vector2(-12, -9), Vector2(24, 20)), Color("ffc928"))
		draw_circle(lock + Vector2(0, -1), 3.5, OUTLINE)
		draw_rect(Rect2(lock + Vector2(-1.5, 0), Vector2(3, 7)), OUTLINE)
