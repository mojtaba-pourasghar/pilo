extends Control
## The opening (first «play», or «story» in the main menu): the grandfather tells how the great
## clock stopped over storyboard panels s01-s03 (StoryPanels), then - the first time - the player
## picks the hero's name («آرسام» by default; Names). Then: the first level, the hub or the menu.


func _ready() -> void:
	UIKit.ensure_theme(get_tree())
	set_anchors_preset(Control.PRESET_FULL_RECT)
	AudioManager.play_music("menu")
	var panels := StoryPanels.new()
	add_child(panels)
	await get_tree().process_frame
	await panels.play(StoryPanels.OPENING)
	if not Names.chosen():
		var pick: int = await panels.dialogue.ask({"who": "pilo", "text": Strings.t("ui_name_prompt")},
			[Strings.t("ui_name_keep"), Strings.t("ui_name_ok")], Names.hero())
		Names.set_hero(Names.DEFAULT_HERO if pick == 0 else panels.dialogue.edited)
	SaveManager.data.intro_seen = true
	SaveManager.save_game()
	_leave()


func _leave() -> void:
	var then := LevelManager.after_intro
	LevelManager.after_intro = "menu"
	match then:
		"level":
			# v3: the first level is the old level of pair 1 (free, no heart, CLAUDE.md rule 6)
			LevelManager.play_pair_level("old_01")
		"hub":
			LevelManager.goto_village()
		_:
			LevelManager.goto_menu()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_leave()
