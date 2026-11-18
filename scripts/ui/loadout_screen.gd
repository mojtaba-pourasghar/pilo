class_name LoadoutScreen
extends CanvasLayer
## Workshop / loadout, exactly sheet_screen_loadout_v1: three tabs at the top (gold = open:
## weapons, backpack = tools, paw = companions), the hero on his pedestal (left), a 4x3 grid of
## slots, the item's level as five stars, the fox's card (right) with its three gear slots, and two
## buttons: gold anvil (upgrade) and blue shield (done). Icons come from p3_tools / p4_weapons /
## p2_companions. Locked items are dim; upgrades open later (level 1 is enough for chapter 1).

signal closed

const S := "loadout"
const WEAPONS := [["lens_bow", "res://assets/art/p4_weapons/p4_wpn_lens_bow_l1_icon.png", true],
	["lens_bow_2", "res://assets/art/p4_weapons/p4_wpn_lens_bow_l2_icon.png", false],
	["wood_sword", "res://assets/art/p4_weapons/p4_wpn_wood_sword_l1_icon.png", false],
	["club", "res://assets/art/p4_weapons/p4_wpn_club_l1_icon.png", false],
	["sling", "res://assets/art/p4_weapons/p4_wpn_sling_l1_icon.png", false],
	["spear", "res://assets/art/p4_weapons/p4_wpn_spear_l1_icon.png", false]]
const TOOLS := [["lantern", true], ["map", true], ["mirror", true], ["quiver", false], ["rope", false], ["shield", false], ["smoke", false], ["pocketwatch", false]]
const COMPANIONS := [["pilo", "res://assets/art/p2_companions/p2_companion_pilo_idle_concept.png", true],
	["bargak", "res://assets/art/p2_companions/p2_companion_bargak_form0_egg_concept.png", false]]

var _stage: Control
var _tab := 0
var _tabs: Array = []
var _slots: Array = []
var _stars: Array = []
var _picked := 0


func _ready() -> void:
	layer = 42
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	_stage = DesignUI.make_stage(root, DesignUI.piece_path(S, "bg"))
	_stage.mouse_filter = Control.MOUSE_FILTER_STOP
	for i in 3:
		var t := DesignUI.button(_stage, DesignUI.piece_path(S, "tab_%d" % (i + 1)), DesignUI.rect(S, "tab_%d" % (i + 1)), func(): _set_tab(i))
		_tabs.append(t)
	for i in 12:
		var b := DesignUI.button(_stage, DesignUI.piece_path(S, "slot_%d" % i), DesignUI.rect(S, "slot_%d" % i), func(): _pick(i))
		var icon := TextureRect.new()
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.offset_left = 10
		icon.offset_top = 10
		icon.offset_right = -10
		icon.offset_bottom = -10
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(icon)
		_slots.append(b)
	for i in 3:
		DesignUI.piece(_stage, S, "cslot_%d" % i)
	var sr := DesignUI.area(S, "stars")
	for i in 5:
		var star := DesignUI.picture(_stage, DesignUI.piece_path(S, "star_on"), Rect2(sr.position + Vector2(i * sr.size.x / 5.0, 0), Vector2(sr.size.x / 5.0, sr.size.y)))
		_stars.append(star)
	DesignUI.button(_stage, DesignUI.piece_path(S, "btn_upgrade"), DesignUI.rect(S, "btn_upgrade"), func(): ScreenBar.toast(_stage, Strings.t("ui_upgrade_soon")))
	DesignUI.button(_stage, DesignUI.piece_path(S, "btn_ok"), DesignUI.rect(S, "btn_ok"), _close)
	_set_tab(0)


func _items() -> Array:
	match _tab:
		0:
			return WEAPONS.map(func(w): return {"id": w[0], "icon": w[1], "owned": w[2], "level": 1})
		1:
			return TOOLS.map(func(t): return {"id": t[0], "icon": "res://assets/art/p3_tools/p3_tool_%s_icon_l1.png" % t[0], "owned": t[1], "level": 1})
		_:
			var eggs: Array = SaveManager.data.get("eggs", [])
			return COMPANIONS.map(func(c): return {"id": c[0], "icon": c[1], "owned": c[2] or eggs.has(c[0]), "level": 1})


func _set_tab(i: int) -> void:
	_tab = i
	for k in 3:
		_tabs[k].modulate = Color.WHITE if k == i else Color(0.72, 0.72, 0.8)
	var items := _items()
	for k in 12:
		var icon: TextureRect = _slots[k].get_child(0)
		if k < items.size():
			icon.texture = DesignUI.tex(items[k].icon)
			icon.modulate = Color.WHITE if items[k].owned else Color(0.35, 0.35, 0.45, 0.8)
		else:
			icon.texture = null
	_pick(0)


func _pick(i: int) -> void:
	var items := _items()
	if i >= items.size():
		return
	_picked = i
	for k in 12:
		_slots[k].self_modulate = Color(1.3, 1.25, 0.9) if k == i else Color.WHITE
	var level := int(items[i].level) if items[i].owned else 0
	for k in 5:
		_stars[k].texture = DesignUI.tex(DesignUI.piece_path(S, "star_on" if k < level else "star_off"))


func _close() -> void:
	SaveManager.save_game()
	closed.emit()
	queue_free()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_close()
