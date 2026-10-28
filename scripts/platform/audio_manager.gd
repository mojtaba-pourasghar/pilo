extends Node
## Sound for the whole game on four channels (buses) with their own volume:
## Music, SFX, Ambient (looping world ambience and positional water) and Voice (character lines).
##
## - Character lines: assets/audio/voice/<id>.mp3 (or .ogg/.wav), made with tools/voice-studio or
##   recorded by an actor (tools/voice/import_recordings.sh). Missing files are skipped silently:
##   the text bubble always shows.
## - Music ducks under a speaking character.
## - In the past the Ambient bus is muffled (low-pass), so the time lens is heard as well as seen.

const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_DIR := "res://assets/audio/music/"
const AMBIENT_DIR := "res://assets/audio/ambient/"
const VOICE_DIR := "res://assets/audio/voice/"
const VOICE_EXTENSIONS := [".mp3", ".ogg", ".wav"]
const POOL_SIZE := 10
const BUSES := ["Music", "SFX", "Ambient", "Voice"]
const DUCK_DB := -9.0
const PAST_CUTOFF := 1400.0

var _music: AudioStreamPlayer
var _voice: AudioStreamPlayer
var _ambient: Array[AudioStreamPlayer] = []   # two players, cross-faded
var _ambient_index := 0
var _pool: Array[AudioStreamPlayer] = []
var _cache: Dictionary = {}
var _current_music := ""
var _current_ambient := ""
var _recent: Dictionary = {}                  # sound -> last play time, for play_sfx_once
var _lowpass: AudioEffectLowPassFilter
var _duck_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_make_buses()
	_music = _player("Music")
	_voice = _player("Voice")
	_voice.finished.connect(_unduck)
	for i in 2:
		_ambient.append(_player("Ambient"))
	for i in POOL_SIZE:
		_pool.append(_player("SFX"))
	apply_settings()


func _make_buses() -> void:
	for bus_name in BUSES:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var index := AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus_name)
			AudioServer.set_bus_send(index, "Master")
	var ambient := AudioServer.get_bus_index("Ambient")
	_lowpass = AudioEffectLowPassFilter.new()
	_lowpass.cutoff_hz = PAST_CUTOFF
	AudioServer.add_bus_effect(ambient, _lowpass)
	AudioServer.set_bus_effect_enabled(ambient, 0, false)


func _player(bus: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = bus
	add_child(player)
	return player


## Volumes per channel from the save file (0..1 each).
func apply_settings() -> void:
	var settings: Dictionary = SaveManager.data.settings
	for bus_name in BUSES:
		var key: String = bus_name.to_lower()
		var volume := float(settings.get(key, 0.9 if key != "music" else 0.7))
		var index := AudioServer.get_bus_index(bus_name)
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(volume, 0.0001)))
		AudioServer.set_bus_mute(index, volume <= 0.001)


func play_music(track: String) -> void:
	if track == _current_music and _music.playing:
		return
	var stream := _load(MUSIC_DIR + track + ".ogg")
	if stream == null:
		return
	_current_music = track
	_set_loop(stream)
	_music.stream = stream
	_music.volume_db = -40.0
	_music.play()
	create_tween().tween_property(_music, "volume_db", 0.0, 1.2)


## Looping world ambience; switching tracks cross-fades over a second and a half.
func play_ambient(track: String) -> void:
	if track == _current_ambient:
		return
	_current_ambient = track
	var old := _ambient[_ambient_index]
	_ambient_index = 1 - _ambient_index
	var new := _ambient[_ambient_index]
	var stream: AudioStream = _load(AMBIENT_DIR + track + ".ogg") if track != "" else null
	var tween := create_tween().set_parallel(true)
	if old.playing:
		tween.tween_property(old, "volume_db", -60.0, 1.5)
		tween.chain().tween_callback(old.stop)
	if stream:
		_set_loop(stream)
		new.stream = stream
		new.volume_db = -60.0
		new.play()
		create_tween().tween_property(new, "volume_db", 0.0, 1.5)


func stop_ambient() -> void:
	play_ambient("")


## Past = muffled ambience (a memory), present = clear.
func set_past_filter(past: bool) -> void:
	AudioServer.set_bus_effect_enabled(AudioServer.get_bus_index("Ambient"), 0, past)


func play_sfx(sound: String, pitch := 1.0, volume_db := 0.0) -> void:
	var stream := _load(SFX_DIR + sound + ".ogg")
	if stream == null:
		return
	var player: AudioStreamPlayer = _pool[0]
	for candidate in _pool:
		if not candidate.playing:
			player = candidate
			break
	player.stream = stream
	player.pitch_scale = pitch
	player.volume_db = volume_db
	player.play()


## Plays a sound at most once per `window` seconds (many blocks reacting to one time shift).
func play_sfx_once(sound: String, window := 0.25, pitch := 1.0, volume_db := 0.0) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_recent.get(sound, -10.0)) < window:
		return
	_recent[sound] = now
	play_sfx(sound, pitch, volume_db)


## Plays a character line if a recording exists. Returns whether one was found.
func play_voice(line_id: String) -> bool:
	var stream: AudioStream = null
	for ext in VOICE_EXTENSIONS:
		stream = _load(VOICE_DIR + line_id + ext)
		if stream:
			break
	if stream == null:
		return false
	_voice.stream = stream
	_voice.play()
	_duck(true)
	return true


func stop_voice() -> void:
	if _voice.playing:
		_voice.stop()
	_unduck()


func is_voice_playing() -> bool:
	return _voice.playing


func _unduck() -> void:
	_duck(false)


func _duck(on: bool) -> void:
	if _duck_tween:
		_duck_tween.kill()
	_duck_tween = create_tween()
	_duck_tween.tween_property(_music, "volume_db", DUCK_DB if on else 0.0, 0.25 if on else 0.6)


func _set_loop(stream: AudioStream) -> void:
	if stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
		stream.loop = true


func _load(path: String) -> AudioStream:
	if not _cache.has(path):
		_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return _cache[path]
