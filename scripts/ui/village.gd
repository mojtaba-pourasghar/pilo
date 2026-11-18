extends Control
## The hub (the tower village), exactly screen_hub_v2: the village at sunset with the clock tower,
## the hero and the fox; coin / gem / heart bars on top; round buttons: map (top-left), workshop
## (top-right, tools), basket = chest (bottom-left), paw = den, gift = daily (bottom-right).
## Places in the picture are buttons too: the portal and the tower lead to the map, the market
## stall to the shop, the well is the daily mini-game (main-path never needs it).

const S := "hub"


func _ready() -> void:
	UIKit.ensure_theme(get_tree())
	var stage := DesignUI.make_stage(self, DesignUI.piece_path(S, "bg"))
	# places in the scene (invisible buttons over the painted buildings)
	for pair in [["portal", func(): LevelManager.goto_map()], ["tower", func(): LevelManager.goto_map()],
			["stall", func(): LevelManager.goto_store()], ["well", func(): ScreenBar.toast(stage, Strings.t("ui_daily_soon"))],
			["workshop", _workshop], ["board", func(): ScreenBar.toast(stage, Strings.t("ui_soon"))]]:
		var hit := Button.new()
		hit.flat = true
		hit.focus_mode = Control.FOCUS_NONE
		var r := DesignUI.area(S, pair[0])
		hit.position = r.position
		hit.size = r.size
		hit.pressed.connect(pair[1])
		hit.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		hit.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
		hit.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
		hit.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		stage.add_child(hit)
	ScreenBar.add(stage, S)
	DesignUI.button(stage, DesignUI.piece_path(S, "btn_map"), DesignUI.rect(S, "btn_map"), func(): LevelManager.goto_map())
	DesignUI.button(stage, DesignUI.piece_path(S, "btn_tools"), DesignUI.rect(S, "btn_tools"), _workshop)
	DesignUI.button(stage, DesignUI.piece_path(S, "btn_basket"), DesignUI.rect(S, "btn_basket"), func(): ScreenBar.toast(stage, Strings.t("ui_chest_soon")))
	DesignUI.button(stage, DesignUI.piece_path(S, "btn_paw"), DesignUI.rect(S, "btn_paw"), func(): ScreenBar.toast(stage, Strings.t("ui_den")))
	DesignUI.button(stage, DesignUI.piece_path(S, "btn_gift"), DesignUI.rect(S, "btn_gift"), func(): _daily_gift(stage))
	AudioManager.play_music("menu")


func _workshop() -> void:
	add_child(LoadoutScreen.new())


## The daily gift: 20 coins once a day (transparent, free; no chance involved).
func _daily_gift(stage: Control) -> void:
	var day := Time.get_date_string_from_system()
	if String(SaveManager.data.get("gift_day", "")) == day:
		ScreenBar.toast(stage, Strings.t("ui_gift_taken"))
		return
	SaveManager.data["gift_day"] = day
	Economy.add_coins(20)
	SaveManager.save_game()
	AudioManager.play_sfx("coin")
	ScreenBar.toast(stage, Strings.t("ui_gift_today"))


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		LevelManager.goto_menu()
