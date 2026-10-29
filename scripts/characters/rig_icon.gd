class_name RigIcon
extends Control
## A code-drawn character shown as an icon in menus (store, rewards): no pictures, the same
## animated rig as in the levels, scaled to fit the box.

var who := "pilo"
var hue := 0.0
var pose := "idle"


static func make(character: String, icon_size: float, hue_shift := 0.0, state := "idle") -> RigIcon:
	var icon := RigIcon.new()
	icon.who = character
	icon.hue = hue_shift
	icon.pose = state
	icon.custom_minimum_size = Vector2(icon_size, icon_size)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


func _ready() -> void:
	var rig: CharacterRig
	if PaintedRig.available(who):
		var painted := PaintedRig.make(who)
		rig = painted
		if who == "pilo":
			painted.ready.connect(func(): painted.set_hue_shift(hue))
	elif who == "nima":
		rig = NimaRig.new()
	else:
		var fox := PiloRig.new()
		fox.set_hue_shift(hue)
		rig = fox
	rig.state = pose
	add_child(rig)
	resized.connect(_fit.bind(rig))
	_fit(rig)


func _fit(rig: CharacterRig) -> void:
	# Nima is ~125 px tall, Pilo ~70 px wide: scale to the box, feet at the bottom.
	var s := size.y / 130.0 if who == "nima" else size.x / 78.0
	rig.scale = Vector2(s, s)
	rig.position = Vector2(size.x * 0.5 + (0.0 if who == "nima" else -4.0 * s), size.y - 4.0 * s)
