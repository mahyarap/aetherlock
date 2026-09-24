extends Node2D

const LABORATORY_ROOM_SCENE: PackedScene = preload(
    "res://scenes/rooms/laboratory_room.tscn"
)
const STORAGE_ROOM_SCENE: PackedScene = preload(
    "res://scenes/rooms/storage_room.tscn"
)
const SENTINEL_ROOM_SCENE: PackedScene = preload(
    "res://scenes/rooms/sentinel_room.tscn"
)

@onready var room_container: Node2D = $RoomContainer
@onready var hud: GameHUD = $HUD
@onready var player: Player = $Player

var current_room: GameRoom
var transition_in_progress := false


func _ready() -> void:
	current_room = $RoomContainer/LaboratoryRoom as GameRoom
	hud.bind_player(player)
	_connect_current_room()
	player.global_position = current_room.get_player_spawn_position()

	print("Bootstrap scene ready")


func _connect_current_room() -> void:
	current_room.status_changed.connect(
		_on_room_status_changed
	)
	current_room.transition_requested.connect(
		_on_room_transition_requested
	)
	current_room.energy_key_awarded.connect(
		_on_energy_key_awarded
	)
	hud.show_room(current_room.room_title)


func _on_energy_key_awarded() -> void:
	if player.grant_energy_key():
		hud.show_status(
            "Energy key acquired. Storage exit unlocked."
		)


func _on_room_transition_requested(
	destination_id: StringName,
) -> void:
	if transition_in_progress:
		return

	var next_scene := _get_room_scene(destination_id)

	if next_scene == null:
		push_warning(
			"Unknown room destination: %s" % destination_id
		)
		return

	await _change_room(next_scene)


func _get_room_scene(destination_id: StringName) -> PackedScene:
	match destination_id:
		&"laboratory":
			return LABORATORY_ROOM_SCENE
		&"storage":
			return STORAGE_ROOM_SCENE
		&"sentinel":
			return SENTINEL_ROOM_SCENE
		_:
			return null


func _change_room(next_scene: PackedScene) -> void:
	var next_room := next_scene.instantiate() as GameRoom

	if next_room == null:
		push_error("Room scene root must use GameRoom.")
		return

	transition_in_progress = true
	player.velocity = Vector2.ZERO
	player.set_process(false)
	player.set_physics_process(false)

	for transient: Node in get_tree().get_nodes_in_group(
		&"room_transient"
	):
		transient.queue_free()

	current_room.queue_free()
	await current_room.tree_exited

	room_container.add_child(next_room)
	current_room = next_room
	_connect_current_room()

	player.global_position = current_room.get_player_spawn_position()
	player.set_process(true)
	player.set_physics_process(true)
	transition_in_progress = false


func _on_room_status_changed(message: String) -> void:
	hud.show_status(message)
