class_name WorldMapScreen
extends Control
## Chapter 1 map, exactly sheet_screen_level_map_v1: the forest path with 12 round nodes (gold =
## finished, glowing blue = the next one, dark with a padlock = closed) and the Old Bear's cave
## (the guardian) at the top-right; coin / gem / heart bars at the top; green back (left) and
## purple settings (right). Chapter 1 has 8 levels: nodes 1-7 are levels 1-7 (7 = the memory
## room), the cave is level 8; the other five nodes stay closed for now (comms/DECISION_QUEUE Q8).

const S := "level_map"
## Nodes in path order (pieces of the cut design); the first seven carry levels 1-7.
const NODES := ["node_done", "n_d2", "n_d3", "n_d4", "node_current", "n_l5", "n_l6", "n_l7", "node_locked", "n_l2", "n_l3", "n_l4"]

var _stage: Control


func _ready() -> void:
	UIKit.ensure_theme(get_tree())
	_stage = DesignUI.make_stage(self, DesignUI.piece_path(S, "bg"))
	ScreenBar.add(_stage, S)
	DesignUI.button(_stage, DesignUI.piece_path(S, "back"), DesignUI.rect(S, "back"), func(): LevelManager.goto_village())
	DesignUI.button(_stage, DesignUI.piece_path(S, "settings"), DesignUI.rect(S, "settings"), func():
		var p := PauseScreen.new()
		p.settings_only = true
		add_child(p))
	for i in NODES.size():
		_node(i)
	# the cave of the Old Bear: level 8
	var cave := Button.new()
	cave.flat = true
	cave.focus_mode = Control.FOCUS_NONE
	var r := DesignUI.area(S, "cave")
	cave.position = r.position
	cave.size = r.size
	for st in ["normal", "hover", "pressed", "focus"]:
		cave.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	cave.pressed.connect(func(): _open(8))
	_stage.add_child(cave)
	if not unlocked(8):
		var lock := DesignUI.picture(_stage, DesignUI.piece_path(S, "node_locked"), Rect2(r.get_center() + Vector2(-26, 20), Vector2(52, 52)))
		lock.modulate = Color(1, 1, 1, 0.95)
	AudioManager.play_music("menu")


static func unlocked(level_id: int) -> bool:
	if level_id == 1:
		return true
	if level_id == 7:
		return ProgressManager.is_done(6) and marks() >= 3
	if level_id == 8:
		return ProgressManager.is_done(6)
	return ProgressManager.is_done(level_id - 1)


## Hidden carvings found in levels 1-6 (three open the memory room).
static func marks() -> int:
	var n := 0
	var all: Dictionary = SaveManager.data.get("memory_marks", {})
	for i in range(1, 7):
		n += (all.get(str(i), []) as Array).size()
	return n


static func current_level() -> int:
	for i in range(1, 9):
		if not ProgressManager.is_done(i) and unlocked(i):
			return i
	return 8


func _node(i: int) -> void:
	var r := DesignUI.rect(S, NODES[i])
	var center := r.get_center()
	var level := i + 1 if i < 7 else 0
	var state := "locked"
	if level > 0 and ProgressManager.is_done(level):
		state = "done"
	elif level > 0 and level == current_level():
		state = "current"
	var piece: String = {"done": "node_done", "current": "node_current", "locked": "node_locked"}[state]
	var size := DesignUI.rect(S, piece).size
	var b := DesignUI.button(_stage, DesignUI.piece_path(S, piece), Rect2(center - size * 0.5, size), func(): _open(level))
	if state == "current":
		var t := b.create_tween().set_loops()
		t.tween_property(b, "modulate", Color(1.25, 1.25, 1.35), 0.6)
		t.tween_property(b, "modulate", Color.WHITE, 0.6)
	b.set_meta("level", level)


func _open(level: int) -> void:
	if level <= 0:
		ScreenBar.toast(_stage, Strings.t("ui_soon"))
		return
	if not unlocked(level):
		if level == 7 and ProgressManager.is_done(6):
			ScreenBar.toast(_stage, Strings.t("ui_memory_locked", {"n": DesignUI.fa_num(marks())}))
		else:
			ScreenBar.toast(_stage, Strings.t("ui_locked"))
		return
	var cost := Economy.cost_of(level)
	if Economy.hearts() < int(cost.hearts):
		ScreenBar.toast(_stage, Strings.t("ui_no_hearts", {"m": DesignUI.fa_num(int(ceil(Economy.next_heart_in() / 60.0)))}))
		return
	if Economy.coins() < int(cost.coins):
		ScreenBar.toast(_stage, Strings.t("ui_no_coins", {"n": DesignUI.fa_num(int(cost.coins))}))
		return
	Economy.enter(level)
	LevelManager.play_level(level)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		LevelManager.goto_village()
