extends Node
## Boundary between the game and a store billing SDK (Cafe Bazaar / Myket).
##
## The game only calls purchase(), restore() and owns(). Until an official billing
## plugin is integrated, debug builds use a mock that grants instantly and release
## builds refuse purchases, so nothing can be sold by accident.
## No level ever requires a purchase; content packs and cosmetics are optional.

signal purchase_finished(sku: String, ok: bool, message: String)
signal purchases_restored(skus: Array)

## Real-money products: only coins and gems (and two one-time packs). Never a loot box, never
## something the main path needs (content/09). Granted through Economy after the parent gate.
const PRODUCTS := {
	"coins_s": {"title_key": "shop_coins_s", "coins": 500, "tab": 0},
	"coins_m": {"title_key": "shop_coins_m", "coins": 3000, "tab": 0},
	"coins_l": {"title_key": "shop_coins_l", "coins": 15000, "tab": 0},
	"gems_s": {"title_key": "shop_gems_s", "gems": 50, "tab": 1},
	"gems_l": {"title_key": "shop_gems_l", "gems": 300, "tab": 1},
	"starter": {"title_key": "shop_starter", "coins": 1000, "gems": 50, "once": true, "tab": 1},
	"no_ads": {"title_key": "shop_no_ads", "once": true, "tab": -1},
}

## Cosmetic colors for Pilo (hue shift applied by a shader). "classic" is always free.
const PILO_COLORS := {
	"classic": {"title": "نارنجی", "hue": 0.0, "sku": ""},
	# Earned, not bought: finishing the last level of Rangarestan (ProgressManager.REWARDS).
	"gold": {"title": "طلایی", "hue": 0.1, "sku": "reward_rangarestan"},
}

var _busy := false


func owns(sku: String) -> bool:
	return sku == "" or SaveManager.data.purchases.has(sku) or SaveManager.data.get("rewards", []).has(sku)


func is_coming_soon(sku: String) -> bool:
	return bool(PRODUCTS.get(sku, {}).get("coming_soon", false))


## Prices are set after market testing; the store SDK will supply the localized price.
func price_label(_sku: String) -> String:
	return "قیمت: به‌زودی"


func purchase(sku: String) -> void:
	if _busy:
		return
	if not PRODUCTS.has(sku) or is_coming_soon(sku):
		purchase_finished.emit(sku, false, "این بسته به‌زودی می‌آید.")
		return
	if bool(PRODUCTS[sku].get("once", false)) and SaveManager.data.purchases.has(sku):
		purchase_finished.emit(sku, true, "این بسته را قبلاً گرفته‌اید.")
		return
	if not OS.is_debug_build():
		purchase_finished.emit(sku, false, "پرداخت هنوز فعال نشده است.")
		return
	_busy = true
	await get_tree().create_timer(0.6).timeout
	_busy = false
	_grant(sku)
	purchase_finished.emit(sku, true, "خرید انجام شد. ممنونیم!")


## Real backend: ask the store which products are owned and grant each one.
## Purchases are also kept in the save file so a network error never locks owned content.
func restore() -> void:
	purchases_restored.emit(SaveManager.data.purchases.duplicate())


func _grant(sku: String) -> void:
	var p: Dictionary = PRODUCTS.get(sku, {})
	if bool(p.get("once", false)) and SaveManager.data.purchases.has(sku):
		return
	SaveManager.data.purchases.append(sku)
	var log: Array = SaveManager.data.get("purchases_log", [])
	log.append({"sku": sku, "at": Time.get_datetime_string_from_system()})
	SaveManager.data["purchases_log"] = log
	Economy.add_coins(int(p.get("coins", 0)))
	Economy.add_gems(int(p.get("gems", 0)))
	SaveManager.save_game()
