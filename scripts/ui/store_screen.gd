extends Control
## Store as its own screen: the store panel over the key art; closing returns to the menu.


func _ready() -> void:
	UIKit.ensure_theme()
	add_child(UIKit.make_cover("res://assets/environments/key_art.webp"))
	var popup := StorePopup.new()
	popup.closed.connect(LevelManager.goto_menu)
	add_child(popup)
