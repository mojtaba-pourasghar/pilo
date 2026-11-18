extends Control
## Main menu, exactly sheet_screen_main_menu_v1: the hero and the fox before the clock gate at
## dawn; three blue hexagon buttons on the right (top to bottom: play, settings, story); the
## game's name over the empty sky at the top-centre. Text from strings_fa.json.

const S := "main_menu"


func _ready() -> void:
	UIKit.ensure_theme(get_tree())
	var stage := DesignUI.make_stage(self, DesignUI.piece_path(S, "bg"))
	var logo := DesignUI.text(stage, Strings.t("ui_game_title"), DesignUI.area(S, "logo"), 64, Color("ffd76a"), 14, Color("3a1f0a"))
	logo.add_theme_font_override("font", UIKit.FONT_BLACK)
	var items := [
		["btn_1", Strings.t("ui_continue") if ProgressManager.is_done(1) else Strings.t("ui_play"), _play],
		["btn_2", Strings.t("ui_settings"), _settings],
		["btn_3", Strings.t("ui_story"), func(): LevelManager.goto_intro("menu")],
	]
	for it in items:
		var r := DesignUI.rect(S, it[0])
		var b := DesignUI.button(stage, DesignUI.piece_path(S, it[0]), r, it[2])
		DesignUI.text(b, it[1], Rect2(Vector2.ZERO, r.size), 34, Color.WHITE, 8, Color("0b2a6b"))
	AudioManager.play_music("menu")


func _play() -> void:
	if not bool(SaveManager.data.get("intro_seen", false)):
		LevelManager.goto_intro("level")
	elif ProgressManager.is_done(8):
		LevelManager.goto_village()
	else:
		LevelManager.goto_map()


func _settings() -> void:
	var pause := PauseScreen.new()
	pause.settings_only = true
	add_child(pause)
