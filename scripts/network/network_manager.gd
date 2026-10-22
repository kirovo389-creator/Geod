extends Node

signal status_changed(text: String)
signal peer_joined(peer_id: int)
signal peer_left(peer_id: int)
signal session_ready
signal session_ended(reason: String)

const PORT := 24777
const MAX_CLIENTS := 1
const POSITION_SEND_INTERVAL := 0.10
const MAX_POSITION_STEP := 2.0

var status_text := "Одиночная игра"
var last_positions: Dictionary = {}
var position_send_timer := 0.0


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	GameState.state_changed.connect(_on_game_state_changed)
	GameState.toast_requested.connect(_on_game_toast)


func is_network_active() -> bool:
	return multiplayer.multiplayer_peer != null and not (multiplayer.multiplayer_peer is OfflineMultiplayerPeer)


func is_authority() -> bool:
	return not is_network_active() or multiplayer.is_server()


func local_actor_id() -> int:
	return multiplayer.get_unique_id() if is_network_active() else 1


func set_status(text: String) -> void:
	status_text = text
	status_changed.emit(status_text)


func create_host(port: int = PORT) -> Error:
	close_session()
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(port, MAX_CLIENTS)
	if error != OK:
		set_status("Не удалось создать комнату. Код ошибки: %d" % error)
		return error
	multiplayer.multiplayer_peer = peer
	set_status("Комната создана. Порт: %d. Сообщи другу IP из настроек Wi-Fi." % port)
	return OK


func join_host(address: String, port: int = PORT) -> Error:
	var ip := address.strip_edges()
	if ip.is_empty():
		set_status("Введи локальный IP хоста, например 192.168.1.20.")
		return ERR_INVALID_PARAMETER
	close_session()
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(ip, port)
	if error != OK:
		set_status("Не удалось начать подключение. Код: %d" % error)
		return error
	multiplayer.multiplayer_peer = peer
	set_status("Подключение к %s:%d…" % [ip, port])
	return OK


func close_session() -> void:
	if is_network_active():
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	last_positions.clear()
	set_status("Одиночная игра")


func request_game_action(action: String, target_id: String) -> void:
	if not is_network_active():
		if GameState.perform_action(action, target_id, 1, _local_player_position()):
			AudioManager.play_event("success" if GameState.phase == GameState.Phase.COMPLETE else action)
		return
	if multiplayer.is_server():
		_server_process_action(1, action, target_id)
	else:
		rpc_id(1, "server_request_action", action, target_id)


func _local_player_position() -> Vector3:
	var world := get_tree().get_first_node_in_group("mission_world")
	if world != null:
		return world.get_actor_position(local_actor_id())
	return Vector3.ZERO


func _server_process_action(actor_id: int, action: String, target_id: String) -> void:
	if not multiplayer.is_server() and is_network_active():
		return
	var world := get_tree().get_first_node_in_group("mission_world")
	if world == null:
		_report_action_failure(actor_id, "Миссия ещё загружается. Повтори действие.")
		return
	if not world.can_actor_interact(actor_id, target_id, action):
		_report_action_failure(actor_id, "Подойди ближе к объекту.")
		return
	if not GameState.can_apply_action(action, target_id, actor_id):
		_report_action_failure(actor_id, GameState.action_failure_text(action, target_id, actor_id))
		return
	var succeeded := GameState.perform_action(action, target_id, actor_id, world.get_actor_position(actor_id))
	if succeeded:
		var sound_name := "success" if GameState.phase == GameState.Phase.COMPLETE else action
		AudioManager.play_event(sound_name)
		if is_network_active() and multiplayer.is_server():
			rpc("client_action_sound", sound_name)


func _report_action_failure(actor_id: int, feedback: String) -> void:
	if is_network_active() and multiplayer.is_server() and actor_id != local_actor_id():
		rpc_id(actor_id, "client_toast", feedback)
	else:
		GameState.toast_requested.emit(feedback)


func _on_game_toast(feedback: String) -> void:
	if is_network_active() and multiplayer.is_server():
		rpc("client_toast", feedback)


@rpc("authority", "call_remote", "reliable")
func client_toast(feedback: String) -> void:
	GameState.toast_requested.emit(feedback)


@rpc("authority", "call_remote", "reliable")
func client_action_sound(sound_name: String) -> void:
	AudioManager.play_event(sound_name)


@rpc("any_peer", "call_remote", "reliable")
func server_request_action(action: String, target_id: String) -> void:
	if not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	if sender <= 1 or sender > 65535:
		return
	_server_process_action(sender, action, target_id)


func broadcast_player_transform(position: Vector3, yaw: float) -> void:
	if not is_network_active():
		return
	if multiplayer.is_server():
		rpc("remote_transform", 1, position, yaw)
	else:
		rpc_id(1, "submit_transform", multiplayer.get_unique_id(), position, yaw)


@rpc("any_peer", "call_remote", "unreliable_ordered")
func submit_transform(claimed_peer_id: int, position: Vector3, yaw: float) -> void:
	if not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	if sender != claimed_peer_id or sender <= 1:
		return
	if not is_finite(position.x) or not is_finite(position.y) or not is_finite(position.z) or position.length() > 150.0:
		return
	var previous: Vector3 = last_positions.get(sender, Vector3(0, 0.18, 9.75))
	if previous.distance_to(position) > MAX_POSITION_STEP:
		return
	last_positions[sender] = position
	var world := get_tree().get_first_node_in_group("mission_world")
	if world != null:
		world.update_remote_player(sender, position, yaw)
	rpc("remote_transform", sender, position, yaw)


@rpc("authority", "call_remote", "unreliable_ordered")
func remote_transform(peer_id: int, position: Vector3, yaw: float) -> void:
	var world := get_tree().get_first_node_in_group("mission_world")
	if world != null:
		world.update_remote_player(peer_id, position, yaw)


@rpc("any_peer", "call_remote", "reliable")
func request_initial_snapshot() -> void:
	if not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	if sender <= 1:
		return
	rpc_id(sender, "receive_snapshot", GameState.make_snapshot())
	rpc_id(sender, "remote_player_joined", 1)


@rpc("authority", "call_remote", "reliable")
func receive_snapshot(snapshot: Dictionary) -> void:
	GameState.apply_snapshot(snapshot)


@rpc("authority", "call_remote", "reliable")
func remote_player_joined(peer_id: int) -> void:
	var world := get_tree().get_first_node_in_group("mission_world")
	if world != null:
		world.add_remote_player(peer_id)


@rpc("authority", "call_remote", "reliable")
func remote_player_left(peer_id: int) -> void:
	var world := get_tree().get_first_node_in_group("mission_world")
	if world != null:
		world.remove_remote_player(peer_id)


func _on_peer_connected(peer_id: int) -> void:
	peer_joined.emit(peer_id)
	var world := get_tree().get_first_node_in_group("mission_world")
	if world != null:
		world.add_remote_player(peer_id)
		# Only the host may call authority-owned RPCs. The joining client asks
		# for the mission snapshot from connected_to_server().
		if multiplayer.is_server():
			rpc("remote_player_joined", peer_id)
	set_status("Игрок подключился. В комнате: 2/2")


func _send_initial_snapshot(peer_id: int) -> void:
	if is_network_active() and multiplayer.is_server() and multiplayer.get_peers().has(peer_id):
		rpc_id(peer_id, "receive_snapshot", GameState.make_snapshot())


func _on_peer_disconnected(peer_id: int) -> void:
	peer_left.emit(peer_id)
	last_positions.erase(peer_id)
	var world := get_tree().get_first_node_in_group("mission_world")
	if world != null:
		world.remove_remote_player(peer_id)
	if is_network_active() and multiplayer.is_server():
		rpc("remote_player_left", peer_id)
	set_status("Игрок отключился. Можно продолжать одному.")


func _on_connected_to_server() -> void:
	set_status("Подключено к хосту. Синхронизация миссии…")
	session_ready.emit()
	rpc_id(1, "request_initial_snapshot")


func _on_connection_failed() -> void:
	set_status("Подключение не удалось. Проверь IP, Wi-Fi и порт.")
	close_session()
	session_ended.emit("Не удалось подключиться к хосту.")


func _on_server_disconnected() -> void:
	close_session()
	session_ended.emit("Хост отключился. Сеанс закрыт.")


func _on_game_state_changed() -> void:
	if is_network_active() and multiplayer.is_server():
		rpc("receive_snapshot", GameState.make_snapshot())
