extends Node
## Boundary between the game and a store billing SDK (Cafe Bazaar / Myket).
##
## The game only calls purchase(), restore() and owns(). Until an official billing
## plugin is integrated, debug builds use a mock that grants instantly and release
## builds refuse purchases, so nothing can be sold by accident.
## No level ever requires a purchase; content packs and cosmetics are optional.

signal purchase_finished(sku: String, ok: bool, message: String)
signal purchases_restored(skus: Array)

const PRODUCTS := {
	"worlds_pack": {
		"title": "بستهٔ دنیاهای ۲ و ۳",
		"description": "جزیره‌های ابری و غارهای بلورین؛ ۲۰ مرحلهٔ تازه و ادامهٔ داستان.",
		"icon": "res://assets/ui/crystal.png",
		"coming_soon": false,
	},
	"pilo_colors": {
		"title": "رنگ‌های پیلو",
		"description": "سه رنگ تازه برای پیلو. فقط ظاهری است و مرحله‌ها را آسان‌تر نمی‌کند.",
		"icon": "res://assets/ui/backpack.png",
		"coming_soon": false,
	},
}

## Cosmetic colors for Pilo (hue shift applied by a shader). "classic" is always free.
const PILO_COLORS := {
	"classic": {"title": "نارنجی", "hue": 0.0, "sku": ""},
	"mint": {"title": "نعنایی", "hue": 0.33, "sku": "pilo_colors"},
	"sky": {"title": "آسمانی", "hue": 0.55, "sku": "pilo_colors"},
	"berry": {"title": "تمشکی", "hue": 0.83, "sku": "pilo_colors"},
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
	if owns(sku):
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
	if not SaveManager.data.purchases.has(sku):
		SaveManager.data.purchases.append(sku)
		SaveManager.save_game()
