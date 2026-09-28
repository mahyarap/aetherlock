class_name GameSave
extends RefCounted

const CHECKPOINT_PATH := "user://checkpoint.cfg"
const SAVE_VERSION: int = 1


static func save_checkpoint(has_energy_key: bool) -> Error:
	var config := ConfigFile.new()

	config.set_value("save", "version", SAVE_VERSION)
	config.set_value("checkpoint", "room_id", "laboratory")
	config.set_value("checkpoint", "has_energy_key", has_energy_key)

	return config.save(CHECKPOINT_PATH)


static func load_checkpoint() -> Dictionary:
	var config := ConfigFile.new()
	var result: Error = config.load(CHECKPOINT_PATH)

	if result == ERR_FILE_NOT_FOUND:
		return {}

	if result != OK:
		push_warning("Cannot read checkpoint: %s" % error_string(result))
		return {}

	if config.get_value("save", "version", 0) != SAVE_VERSION:
		push_warning("Unsupported checkpoint version.")
		return {}

	if config.get_value("checkpoint", "room_id", "") != "laboratory":
		push_warning("Unknown checkpoint room.")
		return {}

	var saved_key: Variant = config.get_value(
		"checkpoint",
		"has_energy_key",
		null
	)

	if typeof(saved_key) != TYPE_BOOL:
		push_warning("Invalid checkpoint key value.")
		return {}

	return {"has_energy_key": saved_key}
