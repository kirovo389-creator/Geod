extends CharacterBody3D

signal focus_changed(info: Dictionary)
signal action_requested(action: String, target_id: String)
signal phone_requested
signal pause_requested
signal sprint_changed(held: bool)
signal drop_requested
signal stamina_changed(value: float)

const WALK_SPEED := 4.7
const SPRINT_SPEED := 6.8
const CARRY_SPEED := 2.8
const GRAVITY := 20.0

@onready var camera: Camera3D = $Camera3D
@onready var ray: RayCast3D = $Camera3D/InteractRay

var can_control := false
var move_touch_id := -1
var move_touch_origin := Vector2.ZERO
var move_touch := Vector2.ZERO
var look_touch_id := -1
var look_last := Vector2.ZERO
var yaw := 0.0
var pitch := -0.06
var sprinting := false
var stamina := 100.0
var focus_id := ""
var focus_info: Dictionary = {}
var carry_visual: Node3D
var view_hands: Node3D
var cleaning_tool: MeshInstance3D
var hands_tween: Tween
var walk_phase := 0.0
var position_sync_timer := 0.0
var footstep_timer := 0.0


func _ready() -> void:
	add_to_group("local_player")
	camera.current = true
	ray.enabled = true
	ray.target_position = Vector3(0, 0, -3.2)
	yaw = rotation.y
	_apply_sensitivity()
	_build_view_hands()


func _apply_sensitivity() -> void:
	if SaveManager != null:
		look_sensitivity = float(SaveManager.settings.get("camera_sensitivity", 0.004))


var look_sensitivity := 0.004


func _build_view_hands() -> void:
	view_hands = Node3D.new()
	view_hands.name = "FirstPersonHands"
	camera.add_child(view_hands)

	_add_forearm("Left_Sleeve", Vector3(-0.37, -0.54, -0.76), 0.64, Color(0.12, 0.24, 0.30))
	_add_forearm("Right_Sleeve", Vector3(0.37, -0.54, -0.76), -0.64, Color(0.12, 0.24, 0.30))
	_add_hand_piece("Left_Glove", Vector3(-0.17, -0.80, -1.00), Vector3(0.20, 0.14, 0.20), Color(0.13, 0.39, 0.45))
	_add_hand_piece("Right_Glove", Vector3(0.17, -0.80, -1.00), Vector3(0.20, 0.14, 0.20), Color(0.13, 0.39, 0.45))
	_add_hand_piece("Left_Cuff", Vector3(-0.24, -0.70, -0.91), Vector3(0.18, 0.14, 0.18), Color(0.84, 0.66, 0.27))
	_add_hand_piece("Right_Cuff", Vector3(0.24, -0.70, -0.91), Vector3(0.18, 0.14, 0.18), Color(0.84, 0.66, 0.27))
	for finger_index in range(4):
		var finger_offset := -0.066 + float(finger_index) * 0.044
		_add_hand_digit("Left_Finger_%d" % finger_index, Vector3(-0.17 + finger_offset, -0.815, -1.105), 0.0)
		_add_hand_digit("Right_Finger_%d" % finger_index, Vector3(0.17 + finger_offset, -0.815, -1.105), 0.0)
	_add_hand_digit("Left_Thumb", Vector3(-0.285, -0.805, -1.055), -0.48)
	_add_hand_digit("Right_Thumb", Vector3(0.285, -0.805, -1.055), 0.48)

	cleaning_tool = MeshInstance3D.new()
	cleaning_tool.name = "CleaningSponge"
	var sponge_mesh := BoxMesh.new()
	sponge_mesh.size = Vector3(0.18, 0.07, 0.12)
	cleaning_tool.mesh = sponge_mesh
	cleaning_tool.position = Vector3(-0.22, -0.78, -1.12)
	cleaning_tool.rotation_degrees = Vector3(-12, 18, -18)
	cleaning_tool.visible = false
	var sponge_material := StandardMaterial3D.new()
	sponge_material.albedo_color = Color(0.98, 0.72, 0.18)
	sponge_material.roughness = 0.72
	cleaning_tool.material_override = sponge_material
	view_hands.add_child(cleaning_tool)


func _add_forearm(part_name: String, pos: Vector3, roll: float, tint: Color) -> void:
	var forearm := MeshInstance3D.new()
	forearm.name = part_name
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.105
	capsule.height = 0.66
	capsule.radial_segments = 8
	capsule.rings = 4
	forearm.mesh = capsule
	forearm.position = pos
	forearm.rotation.z = roll
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.roughness = 0.84
	forearm.material_override = material
	view_hands.add_child(forearm)


func _add_hand_piece(part_name: String, pos: Vector3, dimensions: Vector3, tint: Color) -> void:
	var piece := MeshInstance3D.new()
	piece.name = part_name
	var shape := BoxMesh.new()
	shape.size = dimensions
	piece.mesh = shape
	piece.position = pos
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.roughness = 0.8
	piece.material_override = material
	view_hands.add_child(piece)





func _add_hand_digit(part_name: String, pos: Vector3, rotation_z: float) -> void:
	var digit := MeshInstance3D.new()
	digit.name = part_name
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.022
	capsule.height = 0.105
	capsule.radial_segments = 8
	capsule.rings = 4
	digit.mesh = capsule
	digit.position = pos
	digit.rotation = Vector3(1.5708, 0.0, rotation_z)
	var glove_material := StandardMaterial3D.new()
	glove_material.albedo_color = Color(0.10, 0.14, 0.15)
	glove_material.roughness = 0.9
	digit.material_override = glove_material
	view_hands.add_child(digit)


func play_interaction_animation(action: String) -> void:
	if not is_instance_valid(view_hands):
		return
	if is_instance_valid(hands_tween) and hands_tween.is_running():
		hands_tween.kill()
	if is_instance_valid(cleaning_tool):
		cleaning_tool.visible = action == "clean"
	hands_tween = create_tween()
	hands_tween.tween_property(view_hands, "position", Vector3(0.0, -0.045, -0.16), 0.09)
	hands_tween.tween_property(view_hands, "position", Vector3.ZERO, 0.16)
	hands_tween.tween_callback(func():
		if is_instance_valid(cleaning_tool):
			cleaning_tool.visible = false
	)


func _animate_view_hands(delta: float, movement_amount: float) -> void:
	if not is_instance_valid(view_hands):
		return
	if is_instance_valid(hands_tween) and hands_tween.is_running():
		return
	if movement_amount > 0.05:
		walk_phase += delta * (12.0 if sprinting else 7.5)
	var sway := sin(walk_phase) * 0.012 * clampf(movement_amount, 0.0, 1.0)
	var target_position := Vector3(0.0, sway, 0.0)
	view_hands.position = view_hands.position.lerp(target_position, clampf(delta * 8.0, 0.0, 1.0))
	view_hands.rotation.z = move_toward(view_hands.rotation.z, sin(walk_phase * 0.5) * 0.012, delta * 0.08)


func set_control_enabled(enabled: bool) -> void:
	can_control = enabled
	if not enabled:
		move_touch = Vector2.ZERO
		move_touch_id = -1
		look_touch_id = -1
		if sprinting:
			sprinting = false
			sprint_changed.emit(false)


func _input(event: InputEvent) -> void:
	if not can_control:
		return
	var view_size := get_viewport().get_visible_rect().size
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x < view_size.x * 0.42 and event.position.y > view_size.y * 0.50 and move_touch_id == -1:
				move_touch_id = event.index
				move_touch_origin = event.position
				move_touch = Vector2.ZERO
			elif event.position.x >= view_size.x * 0.42 and event.position.y < view_size.y - 170.0 and look_touch_id == -1:
				look_touch_id = event.index
				look_last = event.position
		else:
			if event.index == move_touch_id:
				move_touch_id = -1
				move_touch = Vector2.ZERO
			if event.index == look_touch_id:
				look_touch_id = -1
		return
	if event is InputEventScreenDrag:
		if event.index == move_touch_id:
			move_touch = ((event.position - move_touch_origin) / 62.0).limit_length(1.0)
		elif event.index == look_touch_id:
			var delta: Vector2 = event.position - look_last
			yaw -= delta.x * look_sensitivity
			pitch = clampf(pitch - delta.y * look_sensitivity * 0.72, -1.10, 0.78)
			look_last = event.position
		return
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		yaw -= event.relative.x * look_sensitivity
		pitch = clampf(pitch - event.relative.y * look_sensitivity * 0.72, -1.10, 0.78)
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_E:
				perform_primary_action()
			KEY_F:
				phone_requested.emit()
			KEY_ESCAPE:
				pause_requested.emit()
			KEY_Q:
				drop_requested.emit()


func _physics_process(delta: float) -> void:
	if not can_control:
		velocity.x = move_toward(velocity.x, 0.0, WALK_SPEED * delta * 5.0)
		velocity.z = move_toward(velocity.z, 0.0, WALK_SPEED * delta * 5.0)
		if not is_on_floor():
			velocity.y -= GRAVITY * delta
		else:
			velocity.y = 0.0
		move_and_slide()
		return

	var keyboard := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		keyboard.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		keyboard.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		keyboard.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		keyboard.y += 1.0
	var input_vector := (keyboard + Vector2(move_touch.x, move_touch.y)).limit_length(1.0)
	# Match movement axes to Camera3D's actual rotated -Z forward vector.
	var forward := Vector3(-sin(yaw), 0.0, -cos(yaw))
	var right := Vector3(cos(yaw), 0.0, -sin(yaw))
	var direction := (right * input_vector.x + forward * -input_vector.y).normalized()
	var has_large_item := GameState.carried_item_for(NetworkManager.local_actor_id()) != ""
	var wants_sprint := sprinting or Input.is_key_pressed(KEY_SHIFT)
	var speed := WALK_SPEED
	if has_large_item:
		speed = CARRY_SPEED
		wants_sprint = false
	if wants_sprint and stamina > 0.5 and input_vector.length() > 0.08:
		speed = SPRINT_SPEED
		stamina = maxf(0.0, stamina - 28.0 * delta)
	else:
		stamina = minf(100.0, stamina + 19.0 * delta)
	stamina_changed.emit(stamina)

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
	rotation.y = yaw
	camera.rotation.x = pitch
	move_and_slide()
	_animate_view_hands(delta, direction.length())
	if is_on_floor() and Vector2(velocity.x, velocity.z).length() > 0.8:
		footstep_timer -= delta
		if footstep_timer <= 0.0:
			AudioManager.play_event("footstep_heavy" if has_large_item else "footstep")
			footstep_timer = 0.52 if wants_sprint else (0.78 if has_large_item else 0.64)
	else:
		footstep_timer = minf(footstep_timer, 0.12)

	if global_position.y < -5.0:
		global_position = Vector3(0, 0.15, 4.5)
		velocity = Vector3.ZERO
		GameState.toast_requested.emit("Ты вернулся в безопасную зону.")

	position_sync_timer += delta
	if position_sync_timer >= 0.10:
		position_sync_timer = 0.0
		NetworkManager.broadcast_player_transform(global_position, yaw)


func _process(_delta: float) -> void:
	if not can_control:
		_set_focus({})
		return
	ray.force_raycast_update()
	var info: Dictionary = {}
	if ray.is_colliding():
		var collider := ray.get_collider() as Node
		if collider != null and collider.is_in_group("interactable"):
			info = {
				"id": str(collider.get_meta("target_id", "")),
				"action": str(collider.get_meta("action", "")),
				"title": str(collider.get_meta("title", ""))
			}
	_set_focus(info)


func _set_focus(info: Dictionary) -> void:
	var next_id := str(info.get("id", ""))
	if next_id == focus_id and info == focus_info:
		return
	focus_id = next_id
	focus_info = info.duplicate(true)
	focus_changed.emit(focus_info)


func perform_primary_action() -> void:
	if not can_control:
		return
	if focus_id.is_empty():
		GameState.toast_requested.emit("Посмотри на предмет поближе и нажми «Использовать».")
		return
	var action := str(focus_info.get("action", ""))
	play_interaction_animation(action)
	action_requested.emit(action, focus_id)


func update_carried_item(item_id: String) -> void:
	if is_instance_valid(carry_visual):
		carry_visual.queue_free()
		carry_visual = null
	if item_id.is_empty():
		return
	var item: Dictionary = GameState.items.get(item_id, {})
	var root := Node3D.new()
	root.name = "CarriedProp"
	camera.add_child(root)
	root.position = Vector3(0.33, -0.48, -0.85)
	root.rotation_degrees = Vector3(-8, -13, 0)
	var prop := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	var size := Vector3(0.75, 0.50, 0.22)
	if item_id == "loot_speaker":
		size = Vector3(0.45, 0.75, 0.32)
	mesh.size = size
	prop.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.10, 0.13, 0.17)
	material.roughness = 0.36
	prop.material_override = material
	root.add_child(prop)
	var edge := MeshInstance3D.new()
	var edge_mesh := BoxMesh.new()
	edge_mesh.size = size * Vector3(1.025, 1.025, 1.025)
	edge.mesh = edge_mesh
	var edge_material := StandardMaterial3D.new()
	edge_material.albedo_color = Color(0.43, 0.52, 0.59)
	edge_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	edge_material.cull_mode = BaseMaterial3D.CULL_FRONT
	edge.material_override = edge_material
	root.add_child(edge)
	carry_visual = root


func get_focus_info() -> Dictionary:
	return focus_info.duplicate(true)


func set_sensitivity(value: float) -> void:
	look_sensitivity = clampf(value, 0.0015, 0.010)
