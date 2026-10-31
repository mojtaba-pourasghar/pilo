extends Node
## Registers input actions in code so keyboard and gamepad mappings live in one readable place.
## Touch buttons in the HUD trigger the same actions.

const KEYS := {
	"move_left": [KEY_LEFT, KEY_A],
	"move_right": [KEY_RIGHT, KEY_D],
	"jump": [KEY_SPACE, KEY_UP, KEY_W],
	"down": [KEY_DOWN, KEY_S],
	"dash": [KEY_C, KEY_K, KEY_SHIFT],
	"pilo": [KEY_F, KEY_J],
	"time_shift": [KEY_E, KEY_X],
	"fire": [KEY_V, KEY_L, KEY_CTRL],
	"swap_weapon": [KEY_Q, KEY_TAB],
	"team": [KEY_B, KEY_I],
	"hint": [KEY_H],
	"pause": [KEY_ESCAPE, KEY_P],
}
const PAD_BUTTONS := {
	"move_left": [JOY_BUTTON_DPAD_LEFT],
	"move_right": [JOY_BUTTON_DPAD_RIGHT],
	"down": [JOY_BUTTON_DPAD_DOWN],
	"jump": [JOY_BUTTON_A],
	"dash": [JOY_BUTTON_B, JOY_BUTTON_RIGHT_SHOULDER],
	"pilo": [JOY_BUTTON_Y],
	"time_shift": [JOY_BUTTON_X],
	"fire": [JOY_BUTTON_LEFT_SHOULDER],
	"swap_weapon": [JOY_BUTTON_RIGHT_STICK],
	"hint": [JOY_BUTTON_BACK],
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
