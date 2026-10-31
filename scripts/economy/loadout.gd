class_name Loadout
extends RefCounted
## The companion team and the tool bag (see the scenario document):
## - Pilo is always with Nima; one more companion can be picked in the village. Each one has a
##   real ability. Seven join through the story (one per freed guardian), the others are bought
##   with coins, coins + diamonds, or (two of them) real money behind the parent gate.
## - Two tool slots (three with the golden toolbox). Tools are bought with coins, coins +
##   diamonds, or real money.
## The main path of every level never needs anything bought: these open shortcuts, secrets
## and comfort. Coins and diamonds are never sold for money.

const COMPANIONS := {
	"squirrel": {"name": "سنجابک", "ability": "از دیوارها بالا می‌پرد (پرش از دیوار)", "unlock": "world:1"},
	"turtle": {"name": "لاکی", "ability": "شنای تند و بی‌خستگی در آب", "unlock": "world:2"},
	"mole": {"name": "خال‌خالی", "ability": "شن روان کندش نمی‌کند و جعبه‌های پنهان را حس می‌کند", "unlock": "world:3"},
	"penguin": {"name": "یخک", "ability": "روی یخ لیز نمی‌خورد", "unlock": "world:4"},
	"butterfly": {"name": "پَرپَری", "ability": "سُر خوردن با پیلو دو برابر طول می‌کشد", "unlock": "world:5"},
	"owl": {"name": "پیچ‌پیچ", "ability": "نور بیشتر در تاریکی و بوکشیدن از دورتر", "unlock": "world:6"},
	"spark": {"name": "جرقه", "ability": "حملهٔ پیلو از دو برابر فاصله", "unlock": "world:7"},
	"hedgehog": {"name": "توپولی", "ability": "دَش، خارپشت‌ها را هم آزاد می‌کند و آجرها را می‌شکند", "coins": 800},
	"goat": {"name": "شاخ‌طلا", "ability": "پرش دوبل", "coins": 2000, "diamonds": 8},
	"cat": {"name": "گربهٔ سایه", "ability": "خار و تیغ آسیبش نمی‌زند", "coins": 3500, "diamonds": 20},
	"dragon": {"name": "اژدهاک", "ability": "سُر خوردن بدون پایین آمدن", "sku": "companion_dragon"},
	"lion": {"name": "شیرک بالدار", "ability": "یک قلب بیشتر", "sku": "companion_lion"},
}

const TOOLS := {
	"hammer": {"name": "چکش کوچک", "use": "دَش آجرها را می‌شکند", "coins": 300},
	"umbrella": {"name": "چتر", "use": "آرام‌تر فرود می‌آیی و سُر خوردن طولانی‌تر است", "coins": 400},
	"magnet": {"name": "آهنربای سکه", "use": "سکه‌های اطراف خودشان می‌آیند", "coins": 500},
	"compass": {"name": "قطب‌نمای گنج", "use": "پیلو جای الماس‌ها را از دور حس می‌کند", "coins": 700},
	"shoes": {"name": "کفش تندرو", "use": "دویدن تندتر", "coins": 900},
	"shield": {"name": "سپر حبابی", "use": "اولین ضربهٔ هر مرحله را دفع می‌کند", "coins": 1000, "diamonds": 3},
	"springs": {"name": "کفش فنری", "use": "پرش بلندتر", "coins": 1500, "diamonds": 5},
	"glasses": {"name": "عینک راز", "use": "جعبه‌های پنهان دیده می‌شوند", "coins": 2000, "diamonds": 8},
	"watch": {"name": "ساعت آرام", "use": "سایه‌ها آرام‌تر حرکت می‌کنند", "coins": 2500, "diamonds": 10},
	"skateboard": {"name": "اسکیت موشکی", "use": "دَش بلندتر و تندتر", "sku": "tool_skateboard"},
	"balloon": {"name": "بالن رنگین‌کمان", "use": "سُر خوردن بی‌پایان", "sku": "tool_balloon"},
	"toolbox": {"name": "جعبه‌ابزار طلایی", "use": "یک جای ابزار سوم", "sku": "tool_toolbox"},
	# weapons (Weapons): not in the backpack slots; the swap button picks one, fire shoots it
	"slingshot": {"name": "تیرکمان", "use": "بلوط پرتاب می‌کند و سایه‌ها را می‌زند", "weapon": true, "free": true},
	"bubble": {"name": "تفنگ حبابی", "use": "حباب، سایه را به دام می‌اندازد و می‌ترکاند", "weapon": true, "coins": 600},
	"boomerang": {"name": "بومرنگ", "use": "می‌رود و برمی‌گردد و از همه رد می‌شود", "weapon": true, "coins": 1200, "diamonds": 3},
	"fire_staff": {"name": "عصای آتش", "use": "گلولهٔ آتش جهنده؛ آجر و دیوار ترک‌دار را می‌شکند", "weapon": true, "coins": 2500, "diamonds": 10},
	"star_blaster": {"name": "ستاره‌پران", "use": "سه ستاره با هم پرتاب می‌کند", "weapon": true, "sku": "tool_starblaster"},
}


static func data() -> Dictionary:
	return SaveManager.data


static func companion() -> String:
	return String(data().get("companion", ""))


static func has_companion(id: String) -> bool:
	return companion() == id


static func owns_companion(id: String) -> bool:
	var entry: Dictionary = COMPANIONS.get(id, {})
	if entry.is_empty():
		return false
	if entry.has("unlock"):
		var world_index := int(String(entry.unlock).split(":")[1])
		return int(data().get("hearts_of_time", 0)) >= world_index
	if entry.has("sku"):
		return StoreAdapter.owns(String(entry.sku))
	return data().get("companions", []).has(id)


static func owns_tool(id: String) -> bool:
	var entry: Dictionary = TOOLS.get(id, {})
	if entry.get("free", false):
		return true
	if entry.has("sku"):
		return StoreAdapter.owns(String(entry.sku))
	return data().get("tools", []).has(id)


static func slots() -> int:
	return 3 if owns_tool("toolbox") else 2


static func equipped() -> Array:
	return data().get("equipped", [])


## Is this tool in use right now (owned and in a slot)?
static func has_tool(id: String) -> bool:
	return equipped().has(id) and owns_tool(id)


static func is_weapon(id: String) -> bool:
	return bool(TOOLS.get(id, {}).get("weapon", false))


static func price_text(entry: Dictionary) -> String:
	if entry.get("free", false):
		return "رایگان"
	if entry.has("unlock"):
		return "با آزاد کردن نگهبان جهان %s" % String(entry.unlock).split(":")[1]
	if entry.has("sku"):
		return "خرید (با اجازهٔ بزرگ‌ترها)"
	var text := "%d سکه" % int(entry.get("coins", 0))
	if int(entry.get("diamonds", 0)) > 0:
		text += " + %d الماس" % int(entry.diamonds)
	return text


static func can_afford(entry: Dictionary) -> bool:
	return int(data().get("coins", 0)) >= int(entry.get("coins", 0)) and int(data().get("diamonds", 0)) >= int(entry.get("diamonds", 0))


## Buys with coins / diamonds. Returns false when there is not enough.
static func buy_with_wallet(kind: String, id: String) -> bool:
	var entry: Dictionary = (COMPANIONS if kind == "companion" else TOOLS)[id]
	if entry.has("sku") or entry.has("unlock") or not can_afford(entry):
		return false
	data().coins = int(data().get("coins", 0)) - int(entry.get("coins", 0))
	data().diamonds = int(data().get("diamonds", 0)) - int(entry.get("diamonds", 0))
	var key := "companions" if kind == "companion" else "tools"
	var owned: Array = data().get(key, [])
	if not owned.has(id):
		owned.append(id)
	data()[key] = owned
	SaveManager.save_game()
	return true


static func pick_companion(id: String) -> void:
	data().companion = id if owns_companion(id) else ""
	SaveManager.save_game()


## Puts a tool in a slot, or takes it out. Returns false when all slots are full.
static func toggle_tool(id: String) -> bool:
	var list: Array = equipped()
	if list.has(id):
		list.erase(id)
	elif list.size() >= slots() or not owns_tool(id):
		return false
	else:
		list.append(id)
	data().equipped = list
	SaveManager.save_game()
	return true
