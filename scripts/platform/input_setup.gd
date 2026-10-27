extends Node
## Registers input actions in code so keyboard and gamepad mappings live in one readable place.
## Touch buttons in the HUD trigger the same actions.

const KEYS := {
	"move_left": [KEY_LEFT, KEY_A],
	"move_right": [KEY_RIGHT, KEY_D],
	"jump": [KEY_SPACE, KEY_UP, KEY_W],
	"time_shift": [KEY_E, KEY_SHIFT, KEY_X],
	"hint": [KEY_H],
	"pause": [KEY_ESCAPE, KEY_P],
}
const PAD_BUTTONS := {
	"move_left": [JOY_BUTTON_DPAD_LEFT],
	"move_right": [JOY_BUTTON_DPAD_RIGHT],
	"jump": [JOY_BUTTON_A],
	"time_shift": [JOY_BUTTON_X],
	"hint": [JOY_BUTTON_Y],
	"pause": [JOY_BUTTON_START],
}


func _enter_tree() -> void:
	for action in KEYS:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.4)
		for keycode in KEYS[action]:
			var key := InputEventKey.new()
			key.physical_keycode = keycode
			InputMap.action_add_event(action, key)
		for button in PAD_BUTTONS.get(action, []):
			var pad := InputEventJoypadButton.new()
			pad.button_index = button
			InputMap.action_add_event(action, pad)
	for pair in [["move_left", -1.0], ["move_right", 1.0]]:
		var motion := InputEventJoypadMotion.new()
		motion.axis = JOY_AXIS_LEFT_X
		motion.axis_value = pair[1]
		InputMap.action_add_event(pair[0], motion)
