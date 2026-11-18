extends Control
## The shop (bazaar), exactly screen_shop_v1: the Persian bazaar with lanterns and carpets; on top
## the coin / gem / heart bar; the purple ribbon with the title; the navy panel with the red close
## button; four tabs (coins, gems, hearts, looks); a 3x2 grid of cream cards, each with its
## picture and a gold price button.
##   coins  - three coin packs (real money)            gems - two gem packs and the starter pack
##   hearts - refill with 10 gems, +1 heart or +30 coins for an optional video (max 5 a day)
##   looks  - flying carpet, the fox's cat hat, the blue bow (coins or gems, cosmetic only)
## Every real-money purchase goes behind the simple parent gate (a sum + «ask your parents»).
## Never a loot box; nothing on the main path is sold.

const S := "shop"
## Each tab's cards: [title key, picture (card index of the design whose art fits), kind, value].
const TABS := [
	[["shop_coins_s", 0, "money", "coins_s"], ["shop_coins_m", 0, "money", "coins_m"], ["shop_coins_l", 0, "money", "coins_l"],
		["shop_coins_video", 0, "video", "coins"], ["shop_starter", 1, "money", "starter"], ["shop_no_ads", 2, "money", "no_ads"]],
	[["shop_gems_s", 1, "money", "gems_s"], ["shop_gems_l", 1, "money", "gems_l"], ["shop_starter", 1, "money", "starter"],
		["shop_hearts_full", 2, "refill", ""], ["shop_skin_bow", 5, "skin", "bow:50:gems"], ["shop_skin_carpet", 3, "skin", "carpet:300:coins"]],
	[["shop_hearts_full", 2, "refill", ""], ["shop_heart_video", 2, "video", "heart"], ["shop_coins_video", 0, "video", "coins"],
		["shop_skin_carpet", 3, "skin", "carpet:300:coins"], ["shop_skin_hat", 4, "skin", "hat:200:coins"], ["shop_skin_bow", 5, "skin", "bow:50:gems"]],
	[["shop_skin_carpet", 3, "skin", "carpet:300:coins"], ["shop_skin_hat", 4, "skin", "hat:200:coins"], ["shop_skin_bow", 5, "skin", "bow:50:gems"],
		["shop_starter", 1, "money", "starter"], ["shop_gems_s", 1, "money", "gems_s"], ["shop_coins_s", 0, "money", "coins_s"]],
]

var _stage: Control
var _tab := 0
var _tabs: Array = []
var _cards: Array = []
var _bar: Array = []


func _ready() -> void:
	UIKit.ensure_theme(get_tree())
	_stage = DesignUI.make_stage(self, DesignUI.piece_path(S, "bg"))
	DesignUI.text(_stage, Strings.t("shop_title"), DesignUI.area(S, "title"), 34, Color("6a2a0a"), 0)
	for k in ["coins", "gems", "hearts"]:
		_bar.append(DesignUI.text(_stage, "", DesignUI.area(S, k), 26, DesignUI.GOLD_TEXT, 6))
	DesignUI.button(_stage, DesignUI.piece_path(S, "close"), DesignUI.rect(S, "close"), func(): LevelManager.goto_village())
	for i in 4:
		_tabs.append(DesignUI.button(_stage, DesignUI.piece_path(S, "tab_%d" % (i + 1)), DesignUI.rect(S, "tab_%d" % (i + 1)), func(): _set_tab(i)))
	for i in 6:
		var holder := Control.new()
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_stage.add_child(holder)
		_cards.append(holder)
	Economy.changed.connect(_refresh_bar)
	StoreAdapter.purchase_finished.connect(_on_purchase)
	_refresh_bar()
	_set_tab(0)
	AudioManager.play_music("menu")


func _exit_tree() -> void:
	Economy.changed.disconnect(_refresh_bar)
	StoreAdapter.purchase_finished.disconnect(_on_purchase)


func _refresh_bar() -> void:
	_bar[0].text = DesignUI.fa_num(Economy.coins())
	_bar[1].text = DesignUI.fa_num(Economy.gems())
	_bar[2].text = DesignUI.fa_num(Economy.hearts()) + "/" + DesignUI.fa_num(Economy.MAX_HEARTS)


func _set_tab(i: int) -> void:
	_tab = i
	for k in 4:
		_tabs[k].modulate = Color.WHITE if k == i else Color(0.75, 0.75, 0.85)
		_tabs[k].scale = Vector2(1.05, 1.05) if k == i else Vector2.ONE
	var items: Array = TABS[i]
	for k in 6:
		var holder: Control = _cards[k]
		for c in holder.get_children():
			c.queue_free()
		if k >= items.size():
			continue
		var it: Array = items[k]
		# the card of the design whose picture fits this product, at this place of the grid
		var r := DesignUI.rect(S, "card_%d" % k)
		var card := DesignUI.picture(holder, DesignUI.piece_path(S, "card_%d" % int(it[1])), r, false)
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var pr := DesignUI.rect(S, "price_%d" % k)
		var price := DesignUI.button(holder, DesignUI.piece_path(S, "price_%d" % k), pr, func(): _buy(it))
		DesignUI.text(price, _price_text(it), Rect2(Vector2.ZERO, pr.size), 22, Color("5a3000"), 0)
		DesignUI.text(holder, Strings.t(String(it[0])), Rect2(r.position + Vector2(10, 4), Vector2(r.size.x - 20, 22)), 20, Color("5a3000"), 0)


func _price_text(it: Array) -> String:
	match String(it[2]):
		"money":
			var p: Dictionary = StoreAdapter.PRODUCTS.get(String(it[3]), {})
			if bool(p.get("once", false)) and SaveManager.data.purchases.has(String(it[3])):
				return Strings.t("shop_owned")
			var amount := int(p.get("coins", 0)) if int(p.get("coins", 0)) > 0 else int(p.get("gems", 0))
			return DesignUI.fa_num(amount) + " · " + Strings.t("shop_price_money")
		"refill":
			return DesignUI.fa_num(Economy.REFILL_GEMS) + " الماس"
		"video":
			return "▶ " + DesignUI.fa_num(Economy.ads_left()) + "/" + DesignUI.fa_num(Economy.ADS_PER_DAY)
		_:
			var parts := String(it[3]).split(":")
			if (SaveManager.data.get("skins", []) as Array).has(parts[0]):
				return Strings.t("shop_owned")
			return DesignUI.fa_num(int(parts[1])) + (" سکه" if parts[2] == "coins" else " الماس")


func _buy(it: Array) -> void:
	match String(it[2]):
		"money":
			# real money: always the parent gate first
			var gate := ParentGate.new()
			add_child(gate)
			var ok: bool = await gate.finished
			if ok:
				StoreAdapter.purchase(String(it[3]))
		"refill":
			if Economy.hearts() >= Economy.MAX_HEARTS:
				ScreenBar.toast(_stage, Strings.t("shop_hearts_already"))
			elif not Economy.refill_with_gems():
				ScreenBar.toast(_stage, Strings.t("shop_not_enough"))
		"video":
			if Economy.watch_ad_for(String(it[3])):
				ScreenBar.toast(_stage, Strings.t("shop_video_left", {"n": DesignUI.fa_num(Economy.ads_left())}))
			else:
				ScreenBar.toast(_stage, Strings.t("shop_no_video"))
		_:
			var parts := String(it[3]).split(":")
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
	_set_tab(_tab)


func _on_purchase(_sku: String, ok: bool, message: String) -> void:
	ScreenBar.toast(_stage, Strings.t("shop_bought") if ok else message)
	_set_tab(_tab)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		LevelManager.goto_village()
