extends Node

const SAVE_PATH := "user://how_to_suck_save.json"

var settings: Dictionary = {
	"camera_sensitivity": 0.004,
	"master_volume": 0.8,
	"graphics_quality": "Medium",
	"fps_limit": 60
}


func _ready() -> void:
	load_settings()


func load_progress() -> Dictionary:
	var data := _read_data()
	var progress: Variant = data.get("progress", {})
	return progress if progress is Dictionary else {}


func save_progress(progress: Dictionary) -> void:
	var data := _read_data()
	data["progress"] = progress.duplicate(true)
	_write_data(data)


func load_settings() -> void:
	var data := _read_data()
	var saved: Variant = data.get("settings", {})
	if saved is Dictionary:
		for key in settings.keys():
			if saved.has(key):
				settings[key] = saved[key]


func update_setting(key: String, value: Variant) -> void:
	if not settings.has(key):
		return
	settings[key] = value
	var data := _read_data()
	data["settings"] = settings.duplicate(true)
	_write_data(data)


func _read_data() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed
	return {}


func _write_data(data: Dictionary) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not open save file for writing.")
		return
	file.store_string(JSON.stringify(data, "\t"))
