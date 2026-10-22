extends CharacterBody3D

signal focus_changed(info: Dictionary)
signal action_requested(action: String, target_id: String)
signal phone_requested
signal pause_requested
signal sprint_changed(held: bool)
signal drop_requested

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
var position_sync_timer := 0.0


func _ready() -> void:
	add_to_group("local_player")
	camera.current = true
	ray.enabled = true
	ray.target_position = Vector3(0, 0, -3.2)
	yaw = rotation.y
	_apply_sensitivity()


func _apply_sensitivity() -> void:
	if SaveManager != null:
		look_sensitivity = float(SaveManager.settings.get("camera_sensitivity", 0.004))


var look_sensitivity := 0.004


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
	var forward := Vector3(sin(yaw), 0.0, -cos(yaw))
	var right := Vector3(cos(yaw), 0.0, sin(yaw))
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

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
	rotation.y = yaw
	camera.rotation.x = pitch
	move_and_slide()

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
	action_requested.emit(str(focus_info.get("action", "")), focus_id)


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
