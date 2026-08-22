extends Node

const MUSIC_BUS_NAME: String = "Music"
const SILENT_DB: float = -80.0
const DEFAULT_FADE_SECONDS: float = 1.25

var track_paths: Dictionary = {
	"title": "res://GUI/start_menu/sounds/title-screenv1.wav",
	"shop": "res://NPC's/Audio/Musics/20 - Good Time.ogg",
	"area_1": "res://NPC's/Audio/Musics/21 - Dungeon.ogg",
	"area_2": "res://NPC's/Audio/Musics/2 - The Cave.ogg",
	"area_3": "res://NPC's/Audio/Musics/10 - Dark Castle.ogg",
	"area_4": "res://NPC's/Audio/Musics/14 - Curse.ogg",
	"area_5": "res://NPC's/Audio/Musics/24 - Final Area.ogg",
	"preboss": "res://Music/preboss-room.wav",
}

signal track_changed(track_id: String)

var current_track_id: String = ""
var music_enabled: bool = true
var music_volume_db: float = 0.0

var _players: Array[AudioStreamPlayer] = []
var _active_player: AudioStreamPlayer = null
var _track_cache: Dictionary = {}
var _transition_tween: Tween = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_music_bus()
	_create_players()
	get_tree().scene_changed.connect(_on_scene_changed)
	call_deferred("_sync_current_scene")


func play_track(track_id: String, fade_seconds: float = DEFAULT_FADE_SECONDS, restart: bool = false) -> bool:
	if not track_paths.has(track_id):
		push_warning("Music track is not registered: %s" % track_id)
		return false
	if current_track_id == track_id and _active_player != null and _active_player.playing:
		if restart:
			_active_player.play()
		return true

	var stream: AudioStream = _load_track(track_id)
	if stream == null:
		return false
	_play_stream(stream, track_id, fade_seconds)
	return true


func play_stream(stream: AudioStream, track_id: String = "custom", fade_seconds: float = DEFAULT_FADE_SECONDS) -> void:
	if stream == null:
		return
	_play_stream(stream, track_id, fade_seconds)


func stop_music(fade_seconds: float = DEFAULT_FADE_SECONDS) -> void:
	var old_player: AudioStreamPlayer = _active_player
	current_track_id = ""
	_active_player = null
	if _transition_tween != null and _transition_tween.is_valid():
		_transition_tween.kill()
	if old_player == null or not old_player.playing:
		return
	if fade_seconds <= 0.0:
		old_player.stop()
		old_player.volume_db = SILENT_DB
		return
	_transition_tween = _create_transition_tween()
	_transition_tween.tween_property(old_player, "volume_db", SILENT_DB, fade_seconds)
	_transition_tween.tween_callback(func():
		old_player.stop()
	)


func set_music_enabled(enabled: bool) -> void:
	music_enabled = enabled
	var bus_index: int = AudioServer.get_bus_index(MUSIC_BUS_NAME)
	if bus_index >= 0:
		AudioServer.set_bus_mute(bus_index, not music_enabled)


func set_music_volume_db(volume_db: float) -> void:
	music_volume_db = clampf(volume_db, -80.0, 6.0)
	var bus_index: int = AudioServer.get_bus_index(MUSIC_BUS_NAME)
	if bus_index >= 0:
		AudioServer.set_bus_volume_db(bus_index, music_volume_db)


func set_music_volume_linear(volume: float) -> void:
	var clamped_volume: float = clampf(volume, 0.0, 1.0)
	set_music_volume_db(linear_to_db(maxf(clamped_volume, 0.0001)))


func get_track_for_scene(scene_path: String = "") -> String:
	var path: String = scene_path
	if path.is_empty() and get_tree().current_scene != null:
		path = get_tree().current_scene.scene_file_path
	var lower_path: String = path.to_lower()
	if lower_path.is_empty():
		return ""

	var scene_node: Node = get_tree().current_scene
	if scene_node != null:
		var override_track: Variant = scene_node.get_meta("music_track", "")
		if override_track is String and track_paths.has(override_track as String):
			return override_track as String
	if lower_path.contains("preboss") or lower_path.contains("boss"):
		return "preboss"
	if lower_path.contains("the_shop"):
		return "shop"
	for floor_number: int in range(1, 6):
		if lower_path.contains("/area_%d/" % floor_number):
			return "area_%d" % floor_number
	if lower_path.contains("start_menu"):
		return "title"
	return ""


func play_for_scene(scene_path: String = "", fade_seconds: float = DEFAULT_FADE_SECONDS) -> bool:
	var track_id: String = get_track_for_scene(scene_path)
	if track_id.is_empty():
		return false
	return play_track(track_id, fade_seconds)


func register_track(track_id: String, resource_path: String) -> void:
	if track_id.is_empty() or resource_path.is_empty():
		return
	track_paths[track_id] = resource_path


func _play_stream(stream: AudioStream, track_id: String, fade_seconds: float) -> void:
	if _transition_tween != null and _transition_tween.is_valid():
		_transition_tween.kill()
	var next_player: AudioStreamPlayer = _players[0]
	if _active_player == next_player:
		next_player = _players[1]
	var old_player: AudioStreamPlayer = _active_player
	next_player.stop()
	next_player.stream = stream
	next_player.volume_db = SILENT_DB if fade_seconds > 0.0 else music_volume_db
	next_player.play()
	_active_player = next_player
	current_track_id = track_id
	track_changed.emit(track_id)

	if old_player == null or not old_player.playing:
		next_player.volume_db = music_volume_db
		return
	if fade_seconds <= 0.0:
		old_player.stop()
		next_player.volume_db = music_volume_db
		return

	_transition_tween = _create_transition_tween()
	_transition_tween.tween_property(old_player, "volume_db", SILENT_DB, fade_seconds)
	_transition_tween.parallel().tween_property(next_player, "volume_db", music_volume_db, fade_seconds)
	_transition_tween.tween_callback(func():
		old_player.stop()
	)


func _create_transition_tween() -> Tween:
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	return tween


func _create_players() -> void:
	for index: int in range(2):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = "MusicPlayer%d" % index
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		player.bus = MUSIC_BUS_NAME
		player.volume_db = SILENT_DB
		player.finished.connect(_on_player_finished.bind(player))
		add_child(player)
		_players.append(player)


func _ensure_music_bus() -> void:
	var bus_index: int = AudioServer.get_bus_index(MUSIC_BUS_NAME)
	if bus_index < 0:
		AudioServer.add_bus()
		bus_index = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(bus_index, MUSIC_BUS_NAME)
	AudioServer.set_bus_send(bus_index, "Master")
	AudioServer.set_bus_volume_db(bus_index, music_volume_db)
	AudioServer.set_bus_mute(bus_index, not music_enabled)


func _load_track(track_id: String) -> AudioStream:
	if _track_cache.has(track_id):
		return _track_cache[track_id] as AudioStream
	var resource_path: String = str(track_paths[track_id])
	var stream: AudioStream = load(resource_path) as AudioStream
	if stream == null:
		push_error("Could not load music track: %s" % resource_path)
		return null
	_track_cache[track_id] = stream
	return stream


func _on_scene_changed() -> void:
	call_deferred("_sync_current_scene")


func _sync_current_scene() -> void:
	play_for_scene()


func _on_player_finished(player: AudioStreamPlayer) -> void:
	if player == _active_player and not current_track_id.is_empty() and music_enabled:
		player.play()
