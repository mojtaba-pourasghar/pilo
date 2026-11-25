class_name Upgrades
extends RefCounted
## Tool and companion upgrades sold in the market (docs/40 section 6, CLAUDE.md rule 8).
## Tools have levels 1..5 bought with coins; each level makes the shot fly further (range) and the bow draw faster.
## Companions "evolve" in 3 stages bought with gems; each stage shortens the form cooldown.
## Nothing here locks the route: a missing level only warns and lowers the effect (rule 8).
## Saved in SaveManager.data.upgrades = {id: level}.

## The five tools of the upgrade screen, in the order of its tool scroll (v3_ui_tools_upgrade).
const TOOLS := [
	{"id": "bow", "weapon": "time_bow", "name": "کمان زمان"},
	{"id": "staff", "weapon": "fire_staff", "name": "عصای آتش"},
	{"id": "hammer", "weapon": "", "name": "چکش"},
	{"id": "sword", "weapon": "", "name": "تیغ نور"},
	{"id": "star", "weapon": "star_blaster", "name": "ستاره‌پران"},
]
const MAX_TOOL := 5
const TOOL_COST := [0, 0, 150, 300, 600, 1000]          ## coins to reach level n
const MAX_STAGE := 3
const STAGE_COST := [0, 0, 20, 40]                       ## gems to reach stage n


static func _store() -> Dictionary:
	if not SaveManager.data.has("upgrades") or not SaveManager.data.upgrades is Dictionary:
		SaveManager.data["upgrades"] = {}
	return SaveManager.data.upgrades


static func level(id: String) -> int:
	return clampi(int(_store().get(id, 1)), 1, MAX_TOOL)


static func next_cost(id: String, companion := false) -> int:
	var lv := level(id)
	if companion:
		return STAGE_COST[lv + 1] if lv < MAX_STAGE else 0
	return TOOL_COST[lv + 1] if lv < MAX_TOOL else 0


## Buys the next level; true on success.
static func buy(id: String, companion := false) -> bool:
	var lv := level(id)
	if lv >= (MAX_STAGE if companion else MAX_TOOL):
		return false
	var cost := next_cost(id, companion)
	var paid := Economy.spend_gems(cost) if companion else Economy.spend_coins(cost)
	if not paid:
		return false
	_store()[id] = lv + 1
	SaveManager.save_game()
	return true


static func tool_for_weapon(weapon: String) -> String:
	for t in TOOLS:
		if t.weapon == weapon:
			return String(t.id)
	return ""


## How much further a weapon's shot flies: +12% per level above 1.
static func range_mul(weapon: String) -> float:
	var id := tool_for_weapon(weapon)
	return 1.0 + 0.12 * (level(id) - 1) if id != "" else 1.0


## A companion's form cooldown: 6 s, -1 s per stage above 1.
static func companion_cooldown(id: String, base: float) -> float:
	return maxf(2.5, base - 1.0 * (level(id) - 1))
