class_name ScreenBar
extends RefCounted
## The coin / gem / heart counters of a screen design (hub, level map): numbers drawn in the
## design's empty bars, kept up to date with Economy.


static func add(stage: Control, screen: String, pieces := ["bar_coin", "bar_gem", "bar_heart"]) -> Array:
	var labels: Array = []
	for p in pieces:
		DesignUI.piece(stage, screen, p)
		labels.append(DesignUI.text(stage, "", DesignUI.content(screen, p), 26, DesignUI.GOLD_TEXT, 6))
	var refresh := func():
		labels[0].text = DesignUI.fa_num(Economy.coins())
		labels[1].text = DesignUI.fa_num(Economy.gems())
		var h := Economy.hearts()
		var s := DesignUI.fa_num(h) + "/" + DesignUI.fa_num(Economy.MAX_HEARTS)
		if h < Economy.MAX_HEARTS:
			s += "  " + DesignUI.fa_num(int(ceil(Economy.next_heart_in() / 60.0))) + "′"
		labels[2].text = s
	refresh.call()
	Economy.changed.connect(refresh)
	stage.tree_exiting.connect(func(): Economy.changed.disconnect(refresh))
	return labels


## A short message over the screen (no design of its own: Pilo's dialogue box style is used for
## anything longer).
static func toast(stage: Control, text: String) -> void:
	var l := DesignUI.text(stage, text, Rect2(240, 600, 800, 70), 26, Color.WHITE, 8, Color(0.05, 0.08, 0.2))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var t := l.create_tween()
	t.tween_interval(2.6)
	t.tween_property(l, "modulate:a", 0.0, 0.5)
	t.tween_callback(l.queue_free)
