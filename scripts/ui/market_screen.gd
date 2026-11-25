extends Control
## The v3 market (docs/40 section 6, docs/41 images 19-24), built on the painted mockups so it looks exactly like them:
##   the market stall (v3_ui_market_hub): back button, coin/diamond pill, 6 tabs along the top, the board in the middle
##   tab 0 tools      the tool-upgrade kit (v3_ui_tools_upgrade) laid into the board; levels 1-5 with coins (Upgrades)
##   tab 1 heroes     waiting for the owner (the mockup shows heroes that are not in the story; DECISION_QUEUE Q17)
##   tab 2 companions the companions screen (v3_ui_companions_shop), full screen: pick, evolve with gems
##   tab 3 hearts     the coin kit (v3_ui_coins_shop) in the board: coin packs, a video for a heart, the daily gift
##   tab 4 bundles    the six bundle cards of the hub itself, each with its price plate
##   tab 5 outfits    waiting for the owner (no outfit design yet; Q17)
## All text is Persian from strings_fa.json, drawn over the empty plates. Real money always goes behind the parent
## gate. No loot boxes, no countdown pressure.

const HUB := "res://assets/art/v3/v3_ui_market_hub.png"
const TOOLS_KIT := "res://assets/art/v3/v3_ui_tools_upgrade_k.png"
const COINS_KIT := "res://assets/art/v3/v3_ui_coins_shop_k.png"
const COMPANIONS := "res://assets/art/v3/v3_ui_companions_shop.png"
const SIZE := Vector2(1680, 944)                 ## the mockups' pixel size = the design space
const BOARD := Rect2(372, 318, 936, 522)         ## the hub's blue board, where tab content goes
const TAB_X := [452, 608, 764, 920, 1076, 1232]
const TAB_Y := 232.0
const NAVY := Color("1a1030")
const PLATE_TEXT := Color("5a3000")

## The hub's six bundle cards (tab 4), in reading order: [title key, kind, value]
const BUNDLES := [
	["shop_starter", "money", "starter"], ["shop_skin_carpet", "skin", "carpet:300:coins"], ["shop_coins_l", "money", "coins_l"],
	["shop_hearts_full", "refill", ""], ["shop_no_ads", "money", "no_ads"], ["shop_coins_m", "money", "coins_m"],
]
const BUNDLE_PLATES := [Vector2(545, 522), Vector2(840, 522), Vector2(1135, 522), Vector2(545, 775), Vector2(840, 775), Vector2(1135, 775)]

## The companions screen: the three cards on the shelf and what they are in the story.
const COMPANION_CARDS := [
	{"id": "tikkit", "name": "تیکیت", "rect": Rect2(62, 236, 262, 404), "art": Rect2(86, 292, 222, 262)},
	{"id": "embri", "name": "امبری", "rect": Rect2(342, 236, 262, 404), "art": Rect2(366, 292, 222, 262)},
	{"id": "moth", "name": "", "rect": Rect2(622, 236, 262, 404), "art": Rect2(646, 292, 222, 262)},
]

var _stage: Control
var _content: Control
var _tab := 4
var _tool := 0
var _companion := 0
var _coins: Label
var _gems: Label
var _hub_parts: Array = []


func _ready() -> void:
	UIKit.ensure_theme(get_tree())
	var back := ColorRect.new()
	back.color = Color("1d2440")
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(back)
	_stage = Control.new()
	_stage.size = SIZE
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)
	_fit()
	get_viewport().size_changed.connect(_fit)
	Economy.changed.connect(_refresh_bar)
	StoreAdapter.purchase_finished.connect(_on_purchase)
	_show(_tab)
	AudioManager.play_music("menu")


func _exit_tree() -> void:
	Economy.changed.disconnect(_refresh_bar)
	StoreAdapter.purchase_finished.disconnect(_on_purchase)


## The design space is scaled to fit the screen and centred (the mockups are 16:9 like the game).
func _fit() -> void:
	var view := get_viewport_rect().size
	var k := minf(view.x / SIZE.x, view.y / SIZE.y)
	_stage.scale = Vector2(k, k)
	_stage.position = (view - SIZE * k) * 0.5


# ---------------------------------------------------------------- building blocks

func _pic(parent: Control, path: String, r: Rect2) -> TextureRect:
	var t := TextureRect.new()
	t.texture = load(path) if ResourceLoader.exists(path) else null
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.position = r.position
	t.size = r.size
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(t)
	return t


## A piece cut from one of the pictures (`src` in that picture's pixels), drawn at `r`.
func _crop(parent: Control, path: String, src: Rect2, r: Rect2) -> TextureRect:
	var at := AtlasTexture.new()
	at.atlas = load(path)
	at.region = src
	var t := TextureRect.new()
	t.texture = at
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.position = r.position
	t.size = r.size
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(t)
	return t


## An invisible pressable area over a painted button; it dips while held.
func _hot(parent: Control, r: Rect2, on_press: Callable, look: Control = null) -> Button:
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.position = r.position
	b.size = r.size
	b.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	b.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	b.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.button_down.connect(func():
		if look:
			look.modulate = Color(0.82, 0.82, 0.82))
	b.button_up.connect(func():
		if look:
			look.modulate = Color.WHITE)
	b.pressed.connect(func():
		UIKit.play_click()
		on_press.call())
	parent.add_child(b)
	return b


func _label(parent: Control, value: String, r: Rect2, size := 30, color := Color.WHITE, outline := 7) -> Label:
	return DesignUI.text(parent, value, r, size, color, outline, NAVY)


# ---------------------------------------------------------------- screens

## `tab` may come as text (the screenshot tool's --call=_show:0).
func _show(tab_in: Variant) -> void:
	var tab := int(tab_in)
	if tab == 1 or tab == 5:
		ScreenBar.toast(_stage, Strings.t("market_soon"))
		return
	_tab = tab
	for c in _stage.get_children():
		c.queue_free()
	_hub_parts.clear()
	if tab == 2:
		_companions_screen()
		return
	_pic(_stage, HUB, Rect2(Vector2.ZERO, SIZE))
	_hot(_stage, Rect2(22, 18, 150, 124), _leave)
	_coins = _label(_stage, "", Rect2(1262, 30, 132, 50), 30, DesignUI.GOLD_TEXT)
	_gems = _label(_stage, "", Rect2(1482, 30, 140, 50), 30, DesignUI.GOLD_TEXT)
	_hot(_stage, Rect2(1170, 16, 480, 80), func(): _show(3))
	for i in 6:
		if i == tab:
			# the open tab: a soft golden ring under the painted medallion
			var ring := Ring.new()
			ring.position = Vector2(TAB_X[i], TAB_Y)
			_stage.add_child(ring)
		_hot(_stage, Rect2(TAB_X[i] - 70, TAB_Y - 70, 140, 140), _show.bind(i))
	_refresh_bar()
	_content = Control.new()
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_content)
	if tab == 0 or tab == 3:
		_clear_board()
	match tab:
		0:
			_tools_screen()
		3:
			_coins_screen()
		_:
			_bundles_screen()


## The board without the hub's printed cards: the board's own navy, a little lighter toward the middle.
func _clear_board() -> void:
	var g := Gradient.new()
	g.set_color(0, Color8(9, 30, 68))
	g.set_color(1, Color8(14, 44, 92))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(0.0, 0.0)
	gt.width = 64
	gt.height = 64
	var panel := TextureRect.new()
	panel.texture = gt
	panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	panel.stretch_mode = TextureRect.STRETCH_SCALE
	panel.position = BOARD.position + Vector2(4, 4)
	panel.size = BOARD.size - Vector2(8, 8)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(panel)
	var g2 := g.duplicate()
	g2.set_color(0, Color8(14, 44, 92))
	g2.set_color(1, Color8(9, 30, 68))
	gt.gradient = g2


func _refresh_bar() -> void:
	if is_instance_valid(_coins):
		_coins.text = DesignUI.fa_num(Economy.coins())
	if is_instance_valid(_gems):
		_gems.text = DesignUI.fa_num(Economy.gems())


## Tab 4: the hub's own six cards; each price plate shows the price and buys.
func _bundles_screen() -> void:
	for i in 6:
		var it: Array = BUNDLES[i]
		var c: Vector2 = BUNDLE_PLATES[i]
		var r := Rect2(c - Vector2(110, 24), Vector2(220, 48))
		_label(_content, _price_text(it), r, 26, PLATE_TEXT, 0)
		_label(_content, Strings.t(String(it[0])), Rect2(c - Vector2(130, 186), Vector2(260, 36)), 24, Color.WHITE, 6)
		_hot(_content, Rect2(c - Vector2(134, 200), Vector2(268, 232)), _buy.bind(it))


## Tab 0: the upgrade kit laid into the board; the five gem slots show the tool's level.
func _tools_screen() -> void:
	var k := BOARD.size.x / SIZE.x                  # the kit (same 16:9 size) scaled into the board
	var at := func(p: Vector2) -> Vector2: return BOARD.position + p * k
	_pic(_content, TOOLS_KIT, BOARD)
	var t: Dictionary = Upgrades.TOOLS[_tool]
	var lv := Upgrades.level(String(t.id))
	# level slots: the painted kit has three lit gems; lit/dark pieces are laid over to show the real level
	var lit := Rect2(774, 198, 132, 144)
	var dark := Rect2(1224, 198, 132, 144)
	for i in 5:
		var x := 840.0 + i * 149.0
		var src := lit if i < lv else dark
		_crop(_content, TOOLS_KIT, src, Rect2(at.call(Vector2(x - 66, 198)), Vector2(132, 144) * k))
	_label(_content, String(t.name), Rect2(at.call(Vector2(975, 88)), Vector2(320, 74) * k), 22, PLATE_TEXT, 0)
	_label(_content, Strings.t("market_level", {"n": DesignUI.fa_num(lv)}) + " / " + DesignUI.fa_num(Upgrades.MAX_TOOL),
		Rect2(at.call(Vector2(840, 346)), Vector2(600, 40) * k), 18, DesignUI.GOLD_TEXT, 5)
	var cost := Upgrades.next_cost(String(t.id))
	_label(_content, Strings.t("market_upgrade") if cost > 0 else Strings.t("market_max"),
		Rect2(at.call(Vector2(790, 552)), Vector2(380, 106) * k), 30, PLATE_TEXT, 0)
	_label(_content, DesignUI.fa_num(cost) if cost > 0 else "—", Rect2(at.call(Vector2(1310, 560)), Vector2(170, 96) * k), 28, DesignUI.GOLD_TEXT)
	_hot(_content, Rect2(at.call(Vector2(760, 540)), Vector2(740, 130) * k), _upgrade_tool)
	# range now -> next level (the two bars of the kit)
	var now := Upgrades.range_mul(String(t.weapon)) if String(t.weapon) != "" else 1.0
	_label(_content, "×" + str(snappedf(now, 0.01)), Rect2(at.call(Vector2(840, 430)), Vector2(130, 44) * k), 20, Color.WHITE, 5)
	_label(_content, "×" + str(snappedf(now + (0.12 if lv < Upgrades.MAX_TOOL and String(t.weapon) != "" else 0.0), 0.01)),
		Rect2(at.call(Vector2(1240, 430)), Vector2(130, 44) * k), 20, Color.WHITE, 5)
	# the tool scroll: pick another tool
	for i in 5:
		var cx := 505.0 + i * 184.5
		if i == _tool:
			var ring := Ring.new()
			ring.radius = 64.0 * k / 0.75
			ring.position = at.call(Vector2(cx, 790))
			_content.add_child(ring)
		_hot(_content, Rect2(at.call(Vector2(cx - 70, 720)), Vector2(140, 140) * k), func():
			_tool = i
			_show(0))


## Tab 3: the coin kit in the board: coin packs (parent gate), a video for a heart, the daily gift.
func _coins_screen() -> void:
	var k := BOARD.size.x / SIZE.x
	var at := func(p: Vector2) -> Vector2: return BOARD.position + p * k
	_pic(_content, COINS_KIT, BOARD)
	var plates := [Rect2(210, 642, 346, 92), Rect2(670, 682, 346, 88), Rect2(1130, 642, 342, 92)]
	var texts := [Strings.t("shop_coins_m"), "▶ " + Strings.t("shop_heart_video"), Strings.t("market_daily") if _gift_ready() else Strings.t("market_daily_done")]
	var actions := [_buy.bind(["shop_coins_m", "money", "coins_m"]), _video_heart, _daily_gift]
	for i in 3:
		var r: Rect2 = plates[i]
		_label(_content, texts[i], Rect2(at.call(r.position), r.size * k), 22, PLATE_TEXT, 0)
		_hot(_content, Rect2(at.call(Vector2(170 + i * 460, 220)), Vector2(430, 580) * k), actions[i])
	# the three tickets show today's videos (lit = still available)
	var left := mini(Economy.ads_left(), 3)
	for i in 3:
		if i >= left:
			var dim := ColorRect.new()
			dim.color = Color(0.1, 0.12, 0.3, 0.55)
			dim.position = at.call(Vector2(690 + i * 104, 580))
			dim.size = Vector2(96, 70) * k
			dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_content.add_child(dim)


## Tab 2: the companions screen (full screen): pick a card, the big panel shows it; evolve with gems.
func _companions_screen() -> void:
	_pic(_stage, COMPANIONS, Rect2(Vector2.ZERO, SIZE))
	# back: the hub's painted back button, at the same corner
	var back := _pic(_stage, "res://assets/art/v3/v3_ui_back_round.png", Rect2(10, 8, 120, 112))
	_hot(_stage, Rect2(10, 8, 120, 100), func(): _show(4), back)
	var card: Dictionary = COMPANION_CARDS[_companion]
	var id := String(card.id)
	for i in 3:
		var c: Dictionary = COMPANION_CARDS[i]
		var r: Rect2 = c.rect
		var known := String(c.id) != "moth"
		_label(_stage, String(c.name) if known else Strings.t("market_soon_short"), Rect2(r.position + Vector2(40, 6), Vector2(r.size.x - 80, 44)), 24, Color.WHITE, 6)
		var state := Strings.t("market_in_story") if known else Strings.t("market_locked")
		_label(_stage, state, Rect2(r.position + Vector2(40, 336), Vector2(r.size.x - 80, 56)), 22, PLATE_TEXT, 0)
		if i == _companion:
			var ring := Ring.new()
			ring.radius = 40.0
			ring.position = r.position + Vector2(r.size.x * 0.5, -8)
			_stage.add_child(ring)
		_hot(_stage, r, func():
			_companion = i
			_show(2))
	# the big panel shows the chosen card's picture (the painting holds the egg; others are laid over it)
	if _companion != 0:
		_crop(_stage, COMPANIONS, card.art, Rect2(1010, 150, 404, 404))
	var known := id != "moth"
	_label(_stage, String(card.name) if known else Strings.t("market_soon_short"), Rect2(1110, 52, 320, 64), 32, Color.WHITE, 8)
	var stage_n := Upgrades.level(id) if known else 0
	_label(_stage, Strings.t("market_stage", {"n": DesignUI.fa_num(stage_n), "m": DesignUI.fa_num(Upgrades.MAX_STAGE)}), Rect2(1450, 284, 186, 52), 22, PLATE_TEXT, 0)
	_label(_stage, Strings.t("market_cooldown", {"s": str(Upgrades.companion_cooldown(id, 6.0))}) if known else "", Rect2(1486, 362, 150, 46), 18, Color.WHITE, 5)
	var cost := Upgrades.next_cost(id, true) if known else 0
	_label(_stage, (DesignUI.fa_num(cost) + " الماس") if cost > 0 else "—", Rect2(1012, 776, 146, 110), 24, Color.WHITE, 6)
	_label(_stage, Strings.t("market_evolve") if cost > 0 else Strings.t("market_max"), Rect2(1188, 776, 250, 100), 28, PLATE_TEXT, 0)
	_hot(_stage, Rect2(1180, 768, 266, 116), _evolve)
	_label(_stage, Strings.t("market_pick"), Rect2(1462, 778, 162, 92), 24, Color.WHITE, 6)
	_hot(_stage, Rect2(1456, 770, 176, 108), func(): ScreenBar.toast(_stage, Strings.t("market_team_hint")))
	# the coin pill does not exist on this painting: a small bar of the same style top-right
	_gems = _label(_stage, "", Rect2(1500, 8, 170, 44), 26, DesignUI.GOLD_TEXT)
	_coins = _label(_stage, "", Rect2(1330, 8, 170, 44), 26, DesignUI.GOLD_TEXT)
	_refresh_bar()
	_coins.text = _coins.text + " سکه"
	_gems.text = _gems.text + " الماس"


# ---------------------------------------------------------------- actions

func _upgrade_tool() -> void:
	var t: Dictionary = Upgrades.TOOLS[_tool]
	if Upgrades.next_cost(String(t.id)) <= 0:
		ScreenBar.toast(_stage, Strings.t("market_max"))
	elif Upgrades.buy(String(t.id)):
		ScreenBar.toast(_stage, Strings.t("market_upgraded"))
		AudioManager.play_sfx("star", 1.0)
	else:
		ScreenBar.toast(_stage, Strings.t("shop_not_enough"))
	_show(0)


func _evolve() -> void:
	var id := String(COMPANION_CARDS[_companion].id)
	if id == "moth":
		ScreenBar.toast(_stage, Strings.t("market_soon"))
		return
	if Upgrades.next_cost(id, true) <= 0:
		ScreenBar.toast(_stage, Strings.t("market_max"))
	elif Upgrades.buy(id, true):
		ScreenBar.toast(_stage, Strings.t("market_evolved"))
		AudioManager.play_sfx("star", 1.1)
	else:
		ScreenBar.toast(_stage, Strings.t("shop_not_enough"))
	_show(2)


func _video_heart() -> void:
	if Economy.watch_ad_for("heart"):
		ScreenBar.toast(_stage, Strings.t("shop_video_left", {"n": DesignUI.fa_num(Economy.ads_left())}))
	else:
		ScreenBar.toast(_stage, Strings.t("shop_no_video"))
	_show(3)


func _gift_ready() -> bool:
	return String(SaveManager.data.get("daily_gift", "")) != Time.get_date_string_from_system()


## Once a day, free: 20 coins. No streak pressure, no countdown.
func _daily_gift() -> void:
	if not _gift_ready():
		ScreenBar.toast(_stage, Strings.t("market_daily_done"))
		return
	SaveManager.data["daily_gift"] = Time.get_date_string_from_system()
	Economy.add_coins(20)
	SaveManager.save_game()
	ScreenBar.toast(_stage, Strings.t("market_daily_got"))
	_show(3)


func _price_text(it: Array) -> String:
	match String(it[1]):
		"money":
			var p: Dictionary = StoreAdapter.PRODUCTS.get(String(it[2]), {})
			if bool(p.get("once", false)) and SaveManager.data.get("purchases", []).has(String(it[2])):
				return Strings.t("shop_owned")
			return Strings.t("shop_price_money")
		"refill":
			return DesignUI.fa_num(Economy.REFILL_GEMS) + " الماس"
		_:
			var parts := String(it[2]).split(":")
			if (SaveManager.data.get("skins", []) as Array).has(parts[0]):
				return Strings.t("shop_owned")
			return DesignUI.fa_num(int(parts[1])) + (" سکه" if parts[2] == "coins" else " الماس")


func _buy(it: Array) -> void:
	match String(it[1]):
		"money":
			var gate := ParentGate.new()
			add_child(gate)
			var ok: bool = await gate.finished
			if ok:
				StoreAdapter.purchase(String(it[2]))
		"refill":
			if Economy.hearts() >= Economy.MAX_HEARTS:
				ScreenBar.toast(_stage, Strings.t("shop_hearts_already"))
			elif not Economy.refill_with_gems():
				ScreenBar.toast(_stage, Strings.t("shop_not_enough"))
		_:
			var parts := String(it[2]).split(":")
			var skins: Array = SaveManager.data.get("skins", [])
			if skins.has(parts[0]):
				ScreenBar.toast(_stage, Strings.t("shop_owned"))
				return
			var paid := Economy.spend_coins(int(parts[1])) if parts[2] == "coins" else Economy.spend_gems(int(parts[1]))
			if not paid:
				ScreenBar.toast(_stage, Strings.t("shop_not_enough"))
				return
			skins.append(parts[0])
			SaveManager.data["skins"] = skins
			SaveManager.save_game()
			ScreenBar.toast(_stage, Strings.t("shop_bought"))
	_show(_tab)


func _on_purchase(_sku: String, ok: bool, message: String) -> void:
	ScreenBar.toast(_stage, Strings.t("shop_bought") if ok else message)
	_show(_tab)


func _leave() -> void:
	LevelManager.goto_village()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_leave()


## A soft breathing golden ring that marks the chosen tab, tool or card.
class Ring extends Node2D:
	var radius := 74.0
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var a := 0.45 + 0.25 * sin(_t * 3.0)
		draw_arc(Vector2.ZERO, radius, 0, TAU, 48, Color(1, 0.88, 0.4, a), 6.0)
		draw_arc(Vector2.ZERO, radius + 6.0, 0, TAU, 48, Color(1, 0.95, 0.7, a * 0.4), 3.0)
