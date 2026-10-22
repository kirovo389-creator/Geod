extends Node3D

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const REMOTE_PLAYER_SCENE := preload("res://scenes/player/remote_player.tscn")
const HOUSE_ENVIRONMENT := preload("res://scenes/world/house_environment.tscn")
const HOUSE_INTERACTABLES := preload("res://scenes/world/house_interactables.tscn")

var player: CharacterBody3D
var targets: Dictionary = {}
var remote_players: Dictionary = {}
var car_root: Node3D
var owner_car_root: Node3D
var owner_npc: Node3D
var trunk_content: Node3D
var trunk_lid: Node3D
var trunk_tween: Tween
var loaded_signature := ""
var departure_started := false
var default_target_positions: Dictionary = {}
var interactables_root: Node3D
var sun_ref: DirectionalLight3D
var environment_ref: Environment
var cleaning_tweens: Dictionary = {}
var previous_item_states: Dictionary = {}
var physics_replication_timer := 0.0


func _ready() -> void:
	add_to_group("mission_world")
	_build_environment()
	var house_environment := HOUSE_ENVIRONMENT.instantiate()
	house_environment.name = "HouseEnvironment"
	add_child(house_environment)
	car_root = house_environment.get_node("CleanerVan") as Node3D
	trunk_lid = car_root.get_node("AnimatedTrunkLid") as Node3D
	trunk_content = car_root.get_node("LoadedCargo") as Node3D
	owner_car_root = house_environment.get_node("ClientSedan") as Node3D
	owner_npc = house_environment.get_node("ClientMikhail") as Node3D
	_collect_interactables()
	_build_players()
	GameState.state_changed.connect(_refresh_state)
	_refresh_state()


func _material(color: Color, roughness := 0.78, metallic := 0.0, emission := false) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = roughness
	result.metallic = metallic
	if emission:
		result.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		result.emission_enabled = true
		result.emission = color * 0.8
	return result


func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.11, 0.16, 0.22)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.72, 0.76, 0.83)
	env.ambient_light_energy = 0.78
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.22
	env.glow_bloom = 0.025
	env.fog_enabled = true
	env.fog_light_color = Color(0.55, 0.64, 0.69)
	env.fog_density = 0.002
	world_environment.environment = env
	environment_ref = env
	add_child(world_environment)

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun_ref = sun
	sun.rotation_degrees = Vector3(-42, -28, 0)
	sun.light_energy = 0.62
	sun.light_color = Color(1.0, 0.88, 0.72)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 28.0
	add_child(sun)

	var ceiling_lamp := OmniLight3D.new()
	ceiling_lamp.position = Vector3(-1.5, 2.85, 2.0)
	ceiling_lamp.light_color = Color(1.0, 0.78, 0.54)
	ceiling_lamp.light_energy = 0.65
	ceiling_lamp.omni_range = 8.5
	ceiling_lamp.shadow_enabled = false
	add_child(ceiling_lamp)

	var kitchen_lamp := OmniLight3D.new()
	kitchen_lamp.position = Vector3(-3.2, 2.65, -4.8)
	kitchen_lamp.light_color = Color(0.65, 0.82, 1.0)
	kitchen_lamp.light_energy = 0.48
	kitchen_lamp.omni_range = 6.5
	kitchen_lamp.shadow_enabled = false
	add_child(kitchen_lamp)


func _collect_interactables() -> void:
	interactables_root = HOUSE_INTERACTABLES.instantiate()
	interactables_root.name = "HouseInteractables"
	add_child(interactables_root)
	for candidate in interactables_root.find_children("*", "Node3D", true, false):
		if not candidate.is_in_group("interactable"):
			continue
		var target_id := str(candidate.get_meta("target_id", ""))
		if target_id.is_empty():
			push_warning("Интерактивный объект без target_id: " + candidate.name)
			continue
		targets[target_id] = candidate
		default_target_positions[target_id] = candidate.global_position


func _build_players() -> void:
	player = PLAYER_SCENE.instantiate()
	player.name = "LocalPlayer"
	player.position = Vector3(0, 0.18, 9.75)
	add_child(player)
	player.action_requested.connect(_on_player_action_requested)
	player.focus_changed.connect(_on_focus_changed)


func _on_player_action_requested(action: String, target_id: String) -> void:
	if action == "door":
		NetworkManager.request_game_action("door", target_id)
	elif action == "clean":
		NetworkManager.request_game_action("clean", target_id)
	elif action == "pick_small":
		NetworkManager.request_game_action("pick_small", target_id)
	elif action == "carry_large":
		NetworkManager.request_game_action("carry_large", target_id)
	elif action == "trunk":
		animate_trunk()
		NetworkManager.request_game_action("trunk", target_id)


func _on_focus_changed(info: Dictionary) -> void:
	var hud := get_tree().get_first_node_in_group("game_ui")
	if hud != null:
		hud.set_focus(info)


func get_local_player() -> CharacterBody3D:
	return player


func can_actor_interact(actor_id: int, target_id: String, action: String) -> bool:
	if action == "drop":
		return GameState.carried_item_for(actor_id) == target_id
	var target: Node3D = targets.get(target_id)
	if not is_instance_valid(target):
		return false
	var actor_position := get_actor_position(actor_id)
	if actor_position.distance_to(target.global_position) > 4.4:
		return false
	return true


func get_actor_position(actor_id: int) -> Vector3:
	if actor_id == NetworkManager.local_actor_id() and is_instance_valid(player):
		return player.global_position
	var remote: Node3D = remote_players.get(actor_id)
	if is_instance_valid(remote):
		return remote.global_position
	return Vector3(0, -100, 0)


func add_remote_player(peer_id: int) -> void:
	if peer_id == NetworkManager.local_actor_id() or remote_players.has(peer_id):
		return
	var avatar := REMOTE_PLAYER_SCENE.instantiate()
	avatar.name = "RemotePlayer_%d" % peer_id
	avatar.position = Vector3(1.4, 0.18, 4.65)
	add_child(avatar)
	remote_players[peer_id] = avatar
	_refresh_state()


func remove_remote_player(peer_id: int) -> void:
	var avatar: Node3D = remote_players.get(peer_id)
	if is_instance_valid(avatar):
		avatar.queue_free()
	remote_players.erase(peer_id)


func update_remote_player(peer_id: int, pos: Vector3, world_yaw: float) -> void:
	if peer_id == NetworkManager.local_actor_id():
		return
	if not remote_players.has(peer_id):
		add_remote_player(peer_id)
	var avatar: Node3D = remote_players.get(peer_id)
	if is_instance_valid(avatar):
		avatar.apply_transform(pos, world_yaw)


func play_owner_departure(on_finished: Callable) -> void:
	if departure_started:
		return
	departure_started = true
	if is_instance_valid(owner_npc):
		var owner_tween := create_tween()
		owner_tween.tween_property(owner_npc, "position", Vector3(4.1, 0, 10.0), 1.1)
		owner_tween.tween_callback(func(): owner_npc.visible = false)
	var car_tween := create_tween()
	car_tween.tween_interval(0.5)
	car_tween.tween_property(owner_car_root, "position:z", 27.0, 2.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	car_tween.tween_callback(on_finished)


func _refresh_state() -> void:
	for chore in GameState.chores:
		var target_id := str(chore.get("id", ""))
		var target: Node3D = targets.get(target_id)
		if is_instance_valid(target):
			var completed := bool(chore.get("done", false))
			var collision := target.get_node_or_null("CollisionShape3D") as CollisionShape3D
			if collision != null:
				collision.disabled = completed
			var visual := target.get_node_or_null("Visual") as MeshInstance3D
			var dirt_material := visual.material_override as ShaderMaterial if is_instance_valid(visual) else null
			if completed and dirt_material != null:
				var clean_progress := float(dirt_material.get_shader_parameter("clean_progress"))
				target.visible = clean_progress < 0.99
				if clean_progress >= 0.99:
					continue
				if not cleaning_tweens.has(target_id):
					var clean_tween := create_tween()
					cleaning_tweens[target_id] = clean_tween
					clean_tween.tween_property(dirt_material, "shader_parameter/clean_progress", 1.0, 0.42)
					clean_tween.tween_callback(_finish_clean_animation.bind(target_id, target))
			elif completed:
				target.visible = false
			else:
				if cleaning_tweens.has(target_id):
					var active_tween: Tween = cleaning_tweens[target_id]
					if active_tween.is_running():
						active_tween.kill()
					cleaning_tweens.erase(target_id)
				if dirt_material != null:
					dirt_material.set_shader_parameter("clean_progress", 0.0)
				target.visible = true

	for item_id in GameState.items:
		var target: Node3D = targets.get(str(item_id))
		if not is_instance_valid(target):
			continue
		var key := str(item_id)
		var item: Dictionary = GameState.items[item_id]
		var item_state := str(item.get("state", "world"))
		var was_state := str(previous_item_states.get(key, ""))
		var is_world := item_state == "world"
		var collision := target.get_node_or_null("CollisionShape3D") as CollisionShape3D
		var rigid_item := target as RigidBody3D
		if is_world:
			if not item.has("world_position"):
				item["world_position"] = default_target_positions.get(key, target.global_position)
			var is_remote_client := NetworkManager.is_network_active() and not NetworkManager.is_authority()
			if was_state != "world":
				target.global_position = item.get("world_position", default_target_positions.get(key, target.global_position))
				if rigid_item != null:
					rigid_item.linear_velocity = Vector3.ZERO
					rigid_item.angular_velocity = Vector3.ZERO
					rigid_item.freeze = is_remote_client
					rigid_item.sleeping = is_remote_client
					if not is_remote_client:
						rigid_item.call_deferred("apply_central_impulse", Vector3(0.0, 0.12, 0.0))
			elif rigid_item != null and is_remote_client:
				# The host simulates loose props. Clients display the authoritative position.
				var replicated_position: Vector3 = item.get("world_position", target.global_position)
				if target.global_position.distance_to(replicated_position) > 0.035:
					rigid_item.freeze = true
					target.global_position = replicated_position
			target.visible = true
			if collision != null:
				collision.disabled = false
		else:
			target.visible = false
			if collision != null:
				collision.disabled = true
			if rigid_item != null:
				rigid_item.freeze = true
				rigid_item.linear_velocity = Vector3.ZERO
				rigid_item.angular_velocity = Vector3.ZERO
		previous_item_states[key] = item_state

	var door_target: Node3D = targets.get("door_front")
	if is_instance_valid(door_target):
		var open := bool(GameState.doors.get("door_front", false))
		door_target.visible = true
		door_target.rotation.y = -1.18 if open else 0.0
		var door_collision := door_target.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if door_collision != null:
			door_collision.disabled = open

	var local_carry := GameState.carried_item_for(NetworkManager.local_actor_id())
	if is_instance_valid(player) and player.has_method("update_carried_item"):
		player.update_carried_item(local_carry)
	for actor_key in remote_players:
		var avatar: Node3D = remote_players[actor_key]
		if is_instance_valid(avatar):
			avatar.set_carrying(GameState.carried_item_for(int(actor_key)) != "")

	_refresh_trunk()


func _physics_process(delta: float) -> void:
	if not NetworkManager.is_network_active() or not NetworkManager.is_authority():
		return
	if GameState.phase != GameState.Phase.LOOTING:
		return
	physics_replication_timer += delta
	if physics_replication_timer < 0.25:
		return
	physics_replication_timer = 0.0
	for item_id in GameState.items:
		if str(GameState.items[item_id].get("state", "world")) != "world":
			continue
		var target: RigidBody3D = targets.get(str(item_id)) as RigidBody3D
		if is_instance_valid(target) and not target.freeze:
			GameState.items[item_id]["world_position"] = target.global_position
	# State snapshots piggyback the low-rate loose-item positions.
	GameState.state_changed.emit()


func _finish_clean_animation(target_id: String, target: Node3D) -> void:
	cleaning_tweens.erase(target_id)
	if GameState.is_clean_task_done(target_id) and is_instance_valid(target):
		target.visible = false


func animate_trunk() -> void:
	if not is_instance_valid(trunk_lid):
		return
	if is_instance_valid(trunk_tween) and trunk_tween.is_running():
		trunk_tween.kill()
	trunk_tween = create_tween()
	trunk_tween.tween_property(trunk_lid, "rotation:x", 1.05, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	trunk_tween.tween_interval(0.75)
	trunk_tween.tween_property(trunk_lid, "rotation:x", 0.0, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)


func _refresh_trunk() -> void:
	var signature := ""
	for loaded_id in GameState.trunk:
		signature += loaded_id + ","
	if signature == loaded_signature or not is_instance_valid(trunk_content):
		return
	loaded_signature = signature
	for child in trunk_content.get_children():
		child.queue_free()
	for i in range(GameState.trunk.size()):
		var item_id := GameState.trunk[i]
		var target: Node3D = targets.get(item_id)
		var source_visual := target.get_node_or_null("Visual") as Node3D if is_instance_valid(target) else null
		if is_instance_valid(source_visual):
			var cargo_visual := source_visual.duplicate() as Node3D
			cargo_visual.name = "Cargo_" + item_id
			trunk_content.add_child(cargo_visual)
			cargo_visual.position = Vector3(float(i % 2) * 0.62 - 0.31, 0.72 + float(i / 2) * 0.12, 1.48 + float(i % 2) * 0.12)
			cargo_visual.rotation = Vector3.ZERO
		else:
			var fallback := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(0.42, 0.38, 0.30)
			fallback.mesh = box
			fallback.position = Vector3(float(i % 2) * 0.62 - 0.31, 0.72, 1.48)
			fallback.material_override = _material(Color(0.16, 0.22, 0.28), 0.42)
			trunk_content.add_child(fallback)


func open_mission_door() -> void:
	GameState.doors["door_front"] = true
	_refresh_state()


func reset_world() -> void:
	departure_started = false
	previous_item_states.clear()
	for item_id in GameState.items:
		GameState.items[item_id].erase("world_position")
	if is_instance_valid(car_root):
		car_root.visible = true
		car_root.position = Vector3(-4.4, 0, 11.3)
	if is_instance_valid(trunk_lid):
		trunk_lid.rotation = Vector3.ZERO
	if is_instance_valid(owner_car_root):func open_mission_door() -> void:
	GameState.doors["door_front"] = true
	_refresh_state()


func reset_world() -> void:
	departure_started = false
	previous_item_states.clear()
	for item_id in GameState.items:
		GameState.items[item_id].erase("world_position")
	if is_instance_valid(car_root):
		car_root.visible = true
		car_root.position = Vector3(-4.4, 0, 11.3)
	if is_instance_valid(trunk_lid):
		trunk_lid.rotation = Vector3.ZERO
	if is_instance_valid(owner_car_root):
		owner_car_root.visible = true
		owner_car_root.position = Vector3(4.4, 0, 11.3)
	if is_instance_valid(owner_npc):
		owner_npc.visible = true
		owner_npc.position = Vector3(2.5, 0, 6.2)
	if is_instance_valid(player):
		player.global_position = Vector3(0, 0.18, 9.75)
		player.velocity = Vector3.ZERO
		player.yaw = 0.0
		player.pitch = -0.06
		player.rotation = Vector3.ZERO
		player.camera.rotation = Vector3(-0.06, 0, 0)
	loaded_signature = "__reset__"
	_refresh_state()


func set_quality_mode(quality: String) -> void:
	if is_instance_valid(sun_ref):
		sun_ref.shadow_enabled = quality == "High"
	if environment_ref != null:
		environment_ref.glow_enabled = quality != "Low"
		environment_ref.glow_intensity = 0.24 if quality == "High" else 0.12
	var lights := get_children()
	for child in lights:
		if child is OmniLight3D:
			child.light_energy = 0.34 if quality == "Low" else 0.65
