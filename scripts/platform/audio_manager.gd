extends Node
## Music and sound effects. Volumes come from the save file settings.
## Important dialogue lines are meant to be recorded human Persian voice; drop files in
## assets/audio/voice/ and call play_voice() once they exist.

const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_DIR := "res://assets/audio/music/"
const VOICE_DIR := "res://assets/audio/voice/"
const POOL_SIZE := 8

var _music: AudioStreamPlayer
var _voice: AudioStreamPlayer
var _pool: Array[AudioStreamPlayer] = []
var _cache: Dictionary = {}
var _current_music := ""
var _music_volume := 0.7
var _sfx_volume := 0.9


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music = AudioStreamPlayer.new()
	add_child(_music)
	_voice = AudioStreamPlayer.new()
	add_child(_voice)
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_pool.append(player)
	apply_settings()


func apply_settings() -> void:
	var settings: Dictionary = SaveManager.data.settings
	_music_volume = float(settings.get("music", 0.7))
	_sfx_volume = float(settings.get("sfx", 0.9))
	_music.volume_db = _to_db(_music_volume)


func play_music(track: String) -> void:
	if track == _current_music and _music.playing:
		return
	var stream := _load(MUSIC_DIR + track + ".ogg")
	if stream == null:
		return
	_current_music = track
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	_music.stream = stream
	_music.volume_db = -40.0
	_music.play()
	create_tween().tween_property(_music, "volume_db", _to_db(_music_volume), 1.2)


func play_sfx(sound: String, pitch := 1.0) -> void:
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
	player.volume_db = _to_db(_sfx_volume)
	player.play()


## Plays a recorded line if it exists; silently does nothing otherwise (subtitles always show).
func play_voice(line_id: String) -> void:
	var stream := _load(VOICE_DIR + line_id + ".ogg")
	if stream == null:
		return
	_voice.stream = stream
	_voice.volume_db = _to_db(_sfx_volume)
	_voice.play()


func _load(path: String) -> AudioStream:
	if not _cache.has(path):
		_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return _cache[path]


func _to_db(linear: float) -> float:
	return linear_to_db(maxf(linear, 0.0001))
