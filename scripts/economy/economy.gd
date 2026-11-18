extends Node
## «Economy» (content/09_economy_shop.md): coins, gems, hearts (lives) and the price of a level.
##   - 5 hearts; one comes back every 20 minutes (device clock, with a simple check that it did
##     not go backwards); starting a level costs one heart, replaying a finished level does not.
##   - Entry fee: chapters 1-3 cost 10 coins; the first three levels of a chapter are free the
##     first time. Winning with three stars gives a heart back.
##   - Never stuck: a finished level can always be replayed for coins, an optional video gives a
##     heart (at most 5 videos a day), 10 gems refill the hearts. The main path never needs money.
##   - Real money only buys coins and gems (StoreAdapter, behind the parent gate); no loot boxes.

signal changed

const MAX_HEARTS := 5
const HEART_SECONDS := 20 * 60
const REFILL_GEMS := 10
const ADS_PER_DAY := 5
const FEES := [[3, 10], [7, 20], [11, 30], [15, 40]]     ## [last chapter, coins]


func _data() -> Dictionary:
	return SaveManager.data


func coins() -> int:
	return int(_data().get("coins", 0))


func gems() -> int:
	return int(_data().get("diamonds", 0))


func add_coins(n: int) -> void:
	_data()["coins"] = maxi(0, coins() + n)
	changed.emit()


func add_gems(n: int) -> void:
	_data()["diamonds"] = maxi(0, gems() + n)
	changed.emit()


func spend_coins(n: int) -> bool:
	if coins() < n:
		return false
	add_coins(-n)
	return true


func spend_gems(n: int) -> bool:
	if gems() < n:
		return false
	add_gems(-n)
	return true


func now() -> int:
	return int(Time.get_unix_time_from_system())


## Hearts after the time that has passed (regenerated, saved).
func hearts() -> int:
	var d := _data()
	var h := int(d.get("lives", MAX_HEARTS))
	var t := now()
	var last := int(d.get("lives_time", t))
	if t < last:
		last = t                 # the clock went back: start counting again, give nothing
	if h < MAX_HEARTS:
		var gained := (t - last) / HEART_SECONDS
		if gained > 0:
			h = mini(MAX_HEARTS, h + gained)
			last += gained * HEART_SECONDS
	if h >= MAX_HEARTS:
		last = t
	d["lives"] = h
	d["lives_time"] = last
	return h


## Seconds until the next heart (0 when full).
func next_heart_in() -> int:
	var h := hearts()
	if h >= MAX_HEARTS:
		return 0
	return HEART_SECONDS - (now() - int(_data().get("lives_time", now())))


func add_hearts(n: int) -> void:
	_data()["lives"] = clampi(hearts() + n, 0, MAX_HEARTS)
	changed.emit()


func refill_with_gems() -> bool:
	if hearts() >= MAX_HEARTS or not spend_gems(REFILL_GEMS):
		return false
	_data()["lives"] = MAX_HEARTS
	changed.emit()
	return true


func chapter_of(level_id: int) -> int:
	var world := LevelManager.world_of(level_id)
	return int(world.get("index", 1))


func fee_for(level_id: int) -> int:
	if ProgressManager.is_done(level_id):
		return 0                 # a replay is free: it is how coins are earned back
	var world := LevelManager.world_of(level_id)
	var index := level_id - int(world.get("first", 1)) + 1
	if index <= 3:
		return 0                 # the first three levels of a chapter: free (teaching)
	var ch := chapter_of(level_id)
	for row in FEES:
		if ch <= int(row[0]):
			return int(row[1])
	return 40


## What starting a level costs: {"hearts": 0|1, "coins": n}.
func cost_of(level_id: int) -> Dictionary:
	return {"hearts": 0 if ProgressManager.is_done(level_id) else 1, "coins": fee_for(level_id)}


func can_enter(level_id: int) -> bool:
	var c := cost_of(level_id)
	return hearts() >= int(c.hearts) and coins() >= int(c.coins)


## Pays for a level; false (nothing paid) when it cannot be afforded.
func enter(level_id: int) -> bool:
	if not can_enter(level_id):
		return false
	var c := cost_of(level_id)
	add_coins(-int(c.coins))
	if int(c.hearts) > 0:
		var h := hearts()
		if h >= MAX_HEARTS:
			_data()["lives_time"] = now()
		_data()["lives"] = h - int(c.hearts)
	SaveManager.save_game()
	changed.emit()
	return true


## The level was won: a heart back for three stars.
func on_win(stars: int) -> void:
	if stars >= 3:
		add_hearts(1)


func ads_left() -> int:
	var day := Time.get_date_string_from_system()
	var ads: Dictionary = _data().get("ads", {})
	return ADS_PER_DAY - int(ads.get(day, 0))


## An optional rewarded video (AdsAdapter; never forced). Returns true when it was allowed.
func watch_ad_for(reward: String) -> bool:
	if ads_left() <= 0:
		return false
	var day := Time.get_date_string_from_system()
	_data()["ads"] = {day: ADS_PER_DAY - ads_left() + 1}
	match reward:
		"heart":
			add_hearts(1)
		"coins":
			add_coins(30)
	SaveManager.save_game()
	return true
