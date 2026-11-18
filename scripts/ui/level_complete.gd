extends CanvasLayer
## Level result, exactly screen_result_v2: the hero and the fox cheering on the left, the freed
## bear with butterflies on the right; a red ribbon (title), three stars (gold = earned, outline =
## not), three reward cases on a shelf (coins, gems, the keys / heart of time) with their amounts,
## the round blue replay button and the long gold ▶ next button.
## Stars (18_gameplay_design §2.2): 1 = finished; 2 = no heart lost or a treasure found;
## 3 = a good time and the keeper's secret without the free hint.

signal action(name: String)

const S := "result"

var level_id := 1
var rating := 1
var stars_found := 0
var stars_total := 3
var first_time := false
var reward := ""
var coins := 0
var diamonds_found := 0
var diamonds_total := 0
var freed := 0
var keys := 2
var boss := false


func _ready() -> void:
	layer = 45
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var stage := DesignUI.make_stage(root, DesignUI.piece_path(S, "bg"))
	stage.mouse_filter = Control.MOUSE_FILTER_STOP
	DesignUI.text(stage, Strings.t("ui_level_boss_done" if boss else "ui_level_done"), DesignUI.area(S, "ribbon"), 40, Color.WHITE, 10, Color("6a0a0a"))
	for i in 3:
		var earned := i < rating
		var piece := "star_%d" % (i + 1)
		var r := DesignUI.rect(S, piece)
		var path := DesignUI.piece_path(S, piece if earned and i < 2 else ("star_1" if earned else "star_3"))
		var star := DesignUI.picture(stage, path, r)
		if earned:
			star.pivot_offset = r.size * 0.5
			star.scale = Vector2.ZERO
			var t := star.create_tween()
			t.tween_interval(0.25 + i * 0.3)
			t.tween_property(star, "scale", Vector2(1.2, 1.2), 0.18).set_trans(Tween.TRANS_BACK)
			t.tween_property(star, "scale", Vector2.ONE, 0.12)
			t.tween_callback(func(): AudioManager.play_sfx("star", 1.0 + i * 0.12))
	var amounts := [DesignUI.fa_num(coins), DesignUI.fa_num(diamonds_found), DesignUI.fa_num(keys) if not boss else "♥"]
	for i in 3:
		DesignUI.text(stage, amounts[i], DesignUI.area(S, "amount_%d" % (i + 1)), 28, Color.WHITE, 7)
	DesignUI.button(stage, DesignUI.piece_path(S, "btn_replay"), DesignUI.rect(S, "btn_replay"), func(): _close("retry"))
	DesignUI.button(stage, DesignUI.piece_path(S, "btn_next"), DesignUI.rect(S, "btn_next"), func(): _close("next"))
	AudioManager.play_voice("app_well_done")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_close("map")


func _close(id: String) -> void:
	get_tree().paused = false
	action.emit(id)
	queue_free()
