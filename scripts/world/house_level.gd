extends Node3D

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const REMOTE_PLAYER_SCENE := preload("res://scenes/player/remote_player.tscn")

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
var sun_ref: DirectionalLight3D
var environment_ref: Environment
var cleaning_tweens: Dictionary = {}


func _ready() -> void:
	add_to_group("mission_world")
	_build_environment()
	_build_shell()
	_build_furniture()
	_build_car()
	_build_targets()
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


func _add_box(parent: Node3D, node_name: String, pos: Vector3, size: Vector3, color: Color, collision := true, roughness := 0.78, metallic := 0.0) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 1
	parent.add_child(body)

	var mesh_node := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_node.mesh = box
	mesh_node.material_override = _material(color, roughness, metallic)
	body.add_child(mesh_node)
	if collision:
		var shape := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = size
		shape.shape = box_shape
		body.add_child(shape)
	return body


func _add_visual_box(parent: Node3D, node_name: String, pos: Vector3, size: Vector3, color: Color, roughness := 0.78, metallic := 0.0) -> MeshInstance3D:
	var mesh_node := MeshInstance3D.new()
	mesh_node.name = node_name
	var box := BoxMesh.new()
	box.size = size
	mesh_node.mesh = box
	mesh_node.position = pos
	mesh_node.material_override = _material(color, roughness, metallic)
	parent.add_child(mesh_node)
	return mesh_node


func _add_label(text: String, pos: Vector3, color := Color(0.88, 0.92, 0.95)) -> void:
	var label := Label3D.new()
	label.text = text
	label.position = pos
	label.font_size = 27
	label.outline_size = 5
	label.modulate = color
	label.no_depth_test = false
	add_child(label)


func _build_shell() -> void:
	_add_box(self, "Floor_Wood", Vector3(0, -0.19, 0), Vector3(18.0, 0.38, 16.0), Color(0.33, 0.25, 0.19), true, 0.58)
	_add_box(self, "Left_Wall", Vector3(-9.05, 1.55, 0), Vector3(0.30, 3.1, 16.2), Color(0.76, 0.72, 0.63))
	_add_box(self, "Right_Wall", Vector3(9.05, 1.55, 0), Vector3(0.30, 3.1, 16.2), Color(0.77, 0.73, 0.66))
	_add_box(self, "Rear_Wall", Vector3(0, 1.55, -8.05), Vector3(18.2, 3.1, 0.30), Color(0.70, 0.73, 0.71))
	_add_box(self, "Front_Wall_Left", Vector3(-5.0, 1.55, 8.05), Vector3(8.0, 3.1, 0.30), Color(0.80, 0.75, 0.65))
	_add_box(self, "Front_Wall_Right", Vector3(5.0, 1.55, 8.05), Vector3(8.0, 3.1, 0.30), Color(0.80, 0.75, 0.65))

	# Interior partitions keep a readable route between the living area and kitchen.
	_add_box(self, "Partition_Living_Left", Vector3(-5.05, 1.45, -1.7), Vector3(7.9, 2.9, 0.18), Color(0.81, 0.78, 0.69))
	_add_box(self, "Partition_Living_Right", Vector3(5.05, 1.45, -1.7), Vector3(7.9, 2.9, 0.18), Color(0.81, 0.78, 0.69))
	_add_box(self, "Bedroom_Partition_Back", Vector3(3.2, 1.45, -6.9), Vector3(0.18, 2.9, 2.1), Color(0.76, 0.75, 0.70))
	_add_box(self, "Bedroom_Partition_Front", Vector3(3.2, 1.45, -3.3), Vector3(0.18, 2.9, 2.9), Color(0.76, 0.75, 0.70))
	_add_box(self, "Bath_Partition_Left", Vector3(4.25, 1.45, -5.1), Vector3(2.1, 2.9, 0.16), Color(0.75, 0.79, 0.77))
	_add_box(self, "Bath_Partition_Right", Vector3(7.65, 1.45, -5.1), Vector3(2.7, 2.9, 0.16), Color(0.75, 0.79, 0.77))

	# Window recesses and glass are simple reusable meshes for the mobile renderer.
	_add_box(self, "Living_Window_Frame", Vector3(-7.2, 1.95, 1.2), Vector3(0.06, 1.25, 2.2), Color(0.29, 0.22, 0.16), false)
	var living_glass := _add_box(self, "Living_Window_Glass", Vector3(-7.18, 1.95, 1.2), Vector3(0.03, 1.08, 1.95), Color(0.26, 0.53, 0.65), false)
	var glass_mesh := living_glass.get_child(0) as MeshInstance3D
	var glass_material := _material(Color(0.40, 0.70, 0.82, 0.43), 0.18, 0.15)
	glass_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mesh.material_override = glass_material
	_add_box(self, "Kitchen_Window_Frame", Vector3(-7.2, 2.0, -5.0), Vector3(0.06, 1.0, 1.9), Color(0.30, 0.23, 0.17), false)
	var kitchen_glass := _add_box(self, "Kitchen_Window_Glass", Vector3(-7.18, 2.0, -5.0), Vector3(0.03, 0.82, 1.64), Color(0.32, 0.61, 0.76), false)
	var kitchen_material := _material(Color(0.40, 0.72, 0.87, 0.40), 0.16, 0.12)
	kitchen_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	(kitchen_glass.get_child(0) as MeshInstance3D).material_override = kitchen_material

	_add_label("ГОСТИНАЯ", Vector3(-6.8, 2.65, 6.4))
	_add_label("КУХНЯ", Vector3(-1.4, 2.55, -7.3))
	_add_label("СПАЛЬНЯ", Vector3(5.0, 2.55, -3.0))
	_add_label("ВАННАЯ", Vector3(6.6, 2.55, -7.25))

	# A front entrance step makes the route to the car obvious.
	_add_box(self, "Entrance_Step", Vector3(0, -0.11, 8.65), Vector3(2.7, 0.22, 1.0), Color(0.45, 0.43, 0.39), true)


func _build_furniture() -> void:
	# Living room: fabric sofa, timber table, television cabinet and shelves.
	_add_box(self, "Sofa_Base", Vector3(-4.1, 0.38, 2.3), Vector3(3.3, 0.52, 1.05), Color(0.30, 0.37, 0.43), true)
	_add_box(self, "Sofa_Back", Vector3(-4.1, 0.91, 2.77), Vector3(3.3, 0.9, 0.24), Color(0.26, 0.32, 0.39), true)
	_add_box(self, "Sofa_Arm_Left", Vector3(-5.62, 0.72, 2.25), Vector3(0.26, 0.76, 1.1), Color(0.28, 0.34, 0.40), true)
	_add_box(self, "Sofa_Arm_Right", Vector3(-2.58, 0.72, 2.25), Vector3(0.26, 0.76, 1.1), Color(0.28, 0.34, 0.40), true)
	_add_box(self, "Coffee_Table", Vector3(-2.2, 0.47, 4.15), Vector3(2.1, 0.16, 1.15), Color(0.43, 0.28, 0.16), true, 0.44)
	_add_box(self, "Coffee_Table_Legs", Vector3(-2.2, 0.22, 4.15), Vector3(1.6, 0.42, 0.7), Color(0.30, 0.20, 0.12), true)
	_add_box(self, "TV_Cabinet", Vector3(4.1, 0.48, 2.5), Vector3(3.1, 0.82, 0.8), Color(0.34, 0.23, 0.15), true, 0.5)
	_add_box(self, "TV_Leg_Left", Vector3(3.38, 1.02, 2.5), Vector3(0.12, 0.12, 0.18), Color(0.08, 0.09, 0.10), false, 0.3, 0.4)
	_add_box(self, "TV_Leg_Right", Vector3(4.82, 1.02, 2.5), Vector3(0.12, 0.12, 0.18), Color(0.08, 0.09, 0.10), false, 0.3, 0.4)
	_add_box(self, "Wall_Shelf", Vector3(7.3, 1.6, 0.2), Vector3(0.75, 1.25, 0.18), Color(0.37, 0.26, 0.17), true)
	_add_box(self, "Shelf_Decoration_A", Vector3(7.3, 2.34, 0.2), Vector3(0.34, 0.28, 0.15), Color(0.70, 0.45, 0.26), false)
	_add_box(self, "Shelf_Decoration_B", Vector3(7.3, 1.55, 0.2), Vector3(0.44, 0.25, 0.15), Color(0.20, 0.49, 0.53), false)

	# Kitchen cabinets, countertop, sink, fridge and dining area.
	_add_box(self, "Kitchen_Base_1", Vector3(-4.4, 0.45, -6.25), Vector3(3.5, 0.9, 0.72), Color(0.42, 0.30, 0.22), true)
	_add_box(self, "Kitchen_Counter_1", Vector3(-4.4, 0.96, -6.25), Vector3(3.65, 0.13, 0.82), Color(0.46, 0.49, 0.48), true, 0.28, 0.12)
	_add_box(self, "Kitchen_Upper_1", Vector3(-4.4, 2.1, -7.18), Vector3(3.5, 0.7, 0.5), Color(0.72, 0.67, 0.56), true)
	_add_box(self, "Sink_Bowl", Vector3(-4.1, 1.04, -6.24), Vector3(0.75, 0.035, 0.44), Color(0.16, 0.19, 0.21), false, 0.2, 0.48)
	_add_box(self, "Sink_Faucet", Vector3(-4.1, 1.22, -6.48), Vector3(0.07, 0.30, 0.07), Color(0.70, 0.73, 0.76), false, 0.2, 0.72)
	_add_box(self, "Fridge_Body", Vector3(-7.7, 1.15, -3.55), Vector3(1.0, 2.3, 1.0), Color(0.67, 0.71, 0.72), true, 0.24, 0.18)
	_add_box(self, "Fridge_Handle", Vector3(-7.16, 1.25, -3.75), Vector3(0.045, 0.65, 0.055), Color(0.87, 0.88, 0.88), false, 0.22, 0.58)
	_add_box(self, "Dining_Table", Vector3(0.2, 0.82, -3.35), Vector3(2.25, 0.15, 1.15), Color(0.42, 0.28, 0.17), true, 0.5)
	_add_box(self, "Dining_Leg_A", Vector3(-0.65, 0.42, -3.0), Vector3(0.14, 0.74, 0.14), Color(0.30, 0.19, 0.11), true)
	_add_box(self, "Dining_Leg_B", Vector3(1.05, 0.42, -3.0), Vector3(0.14, 0.74, 0.14), Color(0.30, 0.19, 0.11), true)
	_add_box(self, "Kitchen_Chair", Vector3(1.65, 0.55, -3.35), Vector3(0.42, 1.0, 0.42), Color(0.35, 0.25, 0.17), true)

	# Bedroom and bathroom.
	_add_box(self, "Bed_Frame", Vector3(6.15, 0.36, -3.25), Vector3(3.0, 0.42, 2.0), Color(0.35, 0.25, 0.20), true)
	_add_box(self, "Bed_Mattress", Vector3(6.15, 0.64, -3.25), Vector3(2.85, 0.25, 1.9), Color(0.77, 0.75, 0.69), true)
	_add_box(self, "Bed_Pillow_Left", Vector3(5.35, 0.83, -4.02), Vector3(0.72, 0.16, 0.5), Color(0.91, 0.87, 0.77), false)
	_add_box(self, "Bed_Pillow_Right", Vector3(6.45, 0.83, -4.02), Vector3(0.72, 0.16, 0.5), Color(0.91, 0.87, 0.77), false)
	_add_box(self, "Bedroom_Cabinet", Vector3(7.9, 0.68, -2.45), Vector3(0.85, 1.32, 0.75), Color(0.43, 0.29, 0.19), true)
	_add_box(self, "Bedroom_Nightstand", Vector3(4.8, 0.42, -2.2), Vector3(0.75, 0.84, 0.65), Color(0.42, 0.28, 0.18), true, 0.5)
	_add_box(self, "Bathroom_Vanity", Vector3(7.6, 0.55, -6.8), Vector3(1.8, 1.0, 0.75), Color(0.76, 0.78, 0.73), true)
	_add_box(self, "Bathroom_Sink", Vector3(7.6, 1.08, -6.8), Vector3(1.55, 0.10, 0.62), Color(0.86, 0.87, 0.84), true, 0.22, 0.06)
	_add_box(self, "Bathroom_Mirror", Vector3(7.6, 1.95, -7.45), Vector3(1.25, 1.15, 0.07), Color(0.44, 0.63, 0.67), false, 0.1, 0.62)
	_add_box(self, "Bathroom_Tub", Vector3(4.4, 0.35, -6.9), Vector3(1.9, 0.64, 0.8), Color(0.82, 0.84, 0.80), true, 0.26)
	_add_box(self, "Bathroom_Toilet_Base", Vector3(5.35, 0.30, -6.4), Vector3(0.55, 0.60, 0.72), Color(0.84, 0.85, 0.81), true, 0.28)
	_add_box(self, "Bathroom_Toilet_Tank", Vector3(5.35, 0.80, -6.73), Vector3(0.5, 0.62, 0.22), Color(0.84, 0.85, 0.81), true, 0.28)


func _build_car() -> void:
	car_root = Node3D.new()
	car_root.name = "Cleaner_Van"
	car_root.position = Vector3(-4.4, 0, 11.3)
	add_child(car_root)
	_add_visual_box(car_root, "Van_Body", Vector3(0, 0.83, 0), Vector3(2.15, 1.12, 4.2), Color(0.14, 0.28, 0.36), 0.34, 0.18)
	_add_visual_box(car_root, "Van_Roof", Vector3(0, 1.55, -0.28), Vector3(1.9, 0.45, 2.25), Color(0.17, 0.35, 0.42), 0.30, 0.12)
	_add_visual_box(car_root, "Front_Windshield", Vector3(0, 1.50, -1.35), Vector3(1.55, 0.40, 0.035), Color(0.14, 0.25, 0.29), 0.16, 0.1)
	_add_visual_box(car_root, "Rear_Windshield", Vector3(0, 1.49, 0.86), Vector3(1.52, 0.37, 0.035), Color(0.12, 0.23, 0.28), 0.16, 0.1)
	_add_visual_box(car_root, "Van_Bumper", Vector3(0, 0.37, 2.10), Vector3(2.12, 0.20, 0.15), Color(0.12, 0.14, 0.15), 0.38, 0.2)
	_add_visual_box(car_root, "Trunk_Interior", Vector3(0, 1.18, 1.66), Vector3(1.48, 0.28, 0.50), Color(0.045, 0.055, 0.065), 0.9)
	trunk_lid = Node3D.new()
	trunk_lid.name = "AnimatedTrunkLid"
	trunk_lid.position = Vector3(0, 1.20, 2.08)
	car_root.add_child(trunk_lid)
	_add_visual_box(trunk_lid, "Trunk_Lid_Panel", Vector3(0, 0.25, 0.0), Vector3(1.58, 0.62, 0.12), Color(0.11, 0.23, 0.29), 0.38, 0.14)
	_add_visual_box(trunk_lid, "Trunk_Lid_Inner", Vector3(0, 0.25, -0.065), Vector3(1.38, 0.43, 0.025), Color(0.045, 0.06, 0.07), 0.88)
	for side in [-1.0, 1.0]:
		for z_offset in [-1.28, 1.28]:
			var wheel := MeshInstance3D.new()
			var wheel_mesh := CylinderMesh.new()
			wheel_mesh.top_radius = 0.39
			wheel_mesh.bottom_radius = 0.39
			wheel_mesh.height = 0.22
			wheel.mesh = wheel_mesh
			wheel.position = Vector3(side * 1.0, 0.40, z_offset)
			wheel.rotation_degrees.z = 90
			wheel.material_override = _material(Color(0.055, 0.06, 0.065), 0.78)
			car_root.add_child(wheel)
	_add_visual_box(car_root, "Headlight_Left", Vector3(-0.75, 0.95, -2.11), Vector3(0.33, 0.18, 0.05), Color(1.0, 0.82, 0.49), 0.22, 0.1)
	_add_visual_box(car_root, "Headlight_Right", Vector3(0.75, 0.95, -2.11), Vector3(0.33, 0.18, 0.05), Color(1.0, 0.82, 0.49), 0.22, 0.1)
	trunk_content = Node3D.new()
	trunk_content.name = "LoadedCargo"
	car_root.add_child(trunk_content)

	_make_target("car_trunk", "Багажник фургона", "trunk", Vector3(-4.4, 1.25, 13.6), Vector3(1.6, 1.1, 0.55), Color(0.0, 0.0, 0.0, 0.01), "invisible")

	# The client's car is separate so the employee's van remains parked for loading.
	owner_car_root = Node3D.new()
	owner_car_root.name = "Client_Sedan"
	owner_car_root.position = Vector3(4.4, 0.0, 11.3)
	add_child(owner_car_root)
	_add_visual_box(owner_car_root, "Sedan_Body", Vector3(0, 0.70, 0), Vector3(1.95, 0.72, 3.75), Color(0.40, 0.15, 0.13), 0.32, 0.22)
	_add_visual_box(owner_car_root, "Sedan_Roof", Vector3(0, 1.19, -0.22), Vector3(1.52, 0.48, 1.88), Color(0.34, 0.13, 0.12), 0.30, 0.18)
	_add_visual_box(owner_car_root, "Sedan_Front_Glass", Vector3(0, 1.16, -1.10), Vector3(1.32, 0.34, 0.045), Color(0.10, 0.21, 0.25), 0.16, 0.18)
	_add_visual_box(owner_car_root, "Sedan_Rear_Glass", Vector3(0, 1.16, 0.73), Vector3(1.30, 0.32, 0.045), Color(0.10, 0.21, 0.25), 0.16, 0.18)
	for side in [-1.0, 1.0]:
		for z_offset in [-1.15, 1.15]:
			var sedan_wheel := MeshInstance3D.new()
			var sedan_wheel_mesh := CylinderMesh.new()
			sedan_wheel_mesh.top_radius = 0.32
			sedan_wheel_mesh.bottom_radius = 0.32
			sedan_wheel_mesh.height = 0.19
			sedan_wheel.mesh = sedan_wheel_mesh
			sedan_wheel.position = Vector3(side * 0.92, 0.34, z_offset)
			sedan_wheel.rotation_degrees.z = 90
			sedan_wheel.material_override = _material(Color(0.045, 0.05, 0.055), 0.8)
			owner_car_root.add_child(sedan_wheel)

	owner_npc = Node3D.new()
	owner_npc.name = "Client_Mikhail"
	owner_npc.position = Vector3(2.5, 0, 6.2)
	add_child(owner_npc)
	_add_visual_box(owner_npc, "Client_Body", Vector3(0, 1.0, 0), Vector3(0.55, 0.86, 0.32), Color(0.43, 0.33, 0.27))
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.22
	head_mesh.height = 0.44
	head.mesh = head_mesh
	head.position = Vector3(0, 1.64, 0)
	head.material_override = _material(Color(0.72, 0.54, 0.39), 0.84)
	owner_npc.add_child(head)
	_add_visual_box(owner_npc, "Client_Hair", Vector3(0, 1.82, 0.02), Vector3(0.36, 0.14, 0.34), Color(0.20, 0.15, 0.12))


func _build_targets() -> void:
	_make_target("door_front", "Входная дверь", "door", Vector3(0, 1.34, 7.92), Vector3(1.68, 2.68, 0.14), Color(0.34, 0.22, 0.15), "door")
	_make_target("trash_living", "Мусор у дивана", "clean", Vector3(-1.1, 0.18, 3.15), Vector3(0.42, 0.36, 0.32), Color(0.35, 0.42, 0.37))
	_make_target("stain_living", "Пятно на полу", "clean", Vector3(1.5, 0.025, 4.15), Vector3(1.15, 0.045, 0.84), Color(0.24, 0.14, 0.08), "stain")
	_make_target("trash_kitchen", "Мусор на кухне", "clean", Vector3(-2.2, 0.16, -4.45), Vector3(0.38, 0.31, 0.32), Color(0.37, 0.39, 0.31))
	_make_target("wipe_counter", "Грязь на столешнице", "clean", Vector3(-2.95, 1.055, -6.18), Vector3(0.82, 0.045, 0.38), Color(0.25, 0.15, 0.09), "stain")
	_make_target("dust_bedroom", "Пыль на комоде", "clean", Vector3(7.88, 1.37, -2.42), Vector3(0.60, 0.07, 0.43), Color(0.45, 0.38, 0.28), "stain")

	_make_target("loot_watch", "Наручные часы", "pick_small", Vector3(-2.15, 0.60, 4.15), Vector3(0.28, 0.11, 0.20), Color(0.79, 0.62, 0.24))
	_make_target("loot_tablet", "Планшет", "pick_small", Vector3(-3.20, 1.10, -5.65), Vector3(0.52, 0.07, 0.34), Color(0.07, 0.11, 0.15), "tablet")
	_make_target("loot_camera", "Фотоаппарат", "pick_small", Vector3(0.58, 1.02, -3.32), Vector3(0.34, 0.25, 0.24), Color(0.09, 0.12, 0.13), "camera")
	_make_target("loot_vase", "Декоративная ваза", "pick_small", Vector3(1.0, 1.15, -3.32), Vector3(0.25, 0.48, 0.25), Color(0.47, 0.27, 0.19), "vase")
	_make_target("loot_wallet", "Кошелёк с мелочью", "pick_small", Vector3(4.8, 0.92, -2.2), Vector3(0.32, 0.12, 0.22), Color(0.31, 0.17, 0.09), "wallet")
	_make_target("loot_tv", "Большой телевизор", "carry_large", Vector3(4.1, 1.38, 3.02), Vector3(1.65, 0.96, 0.18), Color(0.045, 0.055, 0.062), "tv")
	_make_target("loot_speaker", "Напольная колонка", "carry_large", Vector3(7.0, 0.69, 2.5), Vector3(0.56, 1.25, 0.48), Color(0.11, 0.13, 0.14), "speaker")


func _make_target(target_id: String, title: String, action: String, pos: Vector3, size: Vector3, color: Color, visual_kind := "box") -> StaticBody3D:
	var target := StaticBody3D.new()
	target.name = target_id
	target.position = pos
	target.collision_layer = 1
	target.collision_mask = 1
	target.add_to_group("interactable")
	target.set_meta("target_id", target_id)
	target.set_meta("title", title)
	target.set_meta("action", action)
	add_child(target)
	targets[target_id] = target
	default_target_positions[target_id] = pos

	if visual_kind != "invisible":
		var visual := MeshInstance3D.new()
		visual.name = "Visual"
		match visual_kind:
			"stain":
				var plane := PlaneMesh.new()
				plane.size = Vector2(size.x, size.z)
				visual.mesh = plane
			"camera":
				var cam_mesh := BoxMesh.new()
				cam_mesh.size = size
				visual.mesh = cam_mesh
				visual.rotation.y = -0.15
			"vase":
				var vase_mesh := CylinderMesh.new()
				vase_mesh.top_radius = 0.10
				vase_mesh.bottom_radius = 0.18
				vase_mesh.height = size.y
				vase_mesh.radial_segments = 8
				visual.mesh = vase_mesh
			"wallet":
				var wallet_mesh := BoxMesh.new()
				wallet_mesh.size = size
				visual.mesh = wallet_mesh
				visual.rotation_degrees.y = -9.0
			"tv":
				var tv_mesh := BoxMesh.new()
				tv_mesh.size = size
				visual.mesh = tv_mesh
			"speaker":
				var speaker_mesh := BoxMesh.new()
				speaker_mesh.size = size
				visual.mesh = speaker_mesh
			_:
				var box := BoxMesh.new()
				box.size = size
				visual.mesh = box
		var material := _material(color, 0.48, 0.06)
		if visual_kind == "stain":
			var dirt_shader := load("res://shaders/dirt_surface.gdshader") as Shader
			var dirt_material := ShaderMaterial.new()
			dirt_material.shader = dirt_shader
			dirt_material.set_shader_parameter("dirt_color", Color(color.r, color.g, color.b, 1.0))
			dirt_material.set_shader_parameter("clean_progress", 0.0)
			material = null
			visual.material_override = dirt_material
		if visual_kind == "tablet":
			material.metallic = 0.25
			material.roughness = 0.26
		if visual_kind == "tv":
			material.metallic = 0.22
			material.roughness = 0.20
		if visual_kind != "stain":
			visual.material_override = material
		target.add_child(visual)
	if visual_kind == "door":
		target.set_meta("original_position", pos)

	var shape := CollisionShape3D.new()
	shape.name = "CollisionShape3D"
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	target.add_child(shape)
	return target


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
				target.visible = true
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
		var item: Dictionary = GameState.items[item_id]
		if not item.has("world_position"):
			item["world_position"] = default_target_positions.get(str(item_id), target.global_position)
		target.global_position = item.get("world_position", target.global_position)
		var is_world := str(item.get("state", "world")) == "world"
		target.visible = is_world
		var collision := target.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if collision != null:
			collision.disabled = not is_world

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
	trunk_tween.tween_property(trunk_lid, "rotation:x", -1.05, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
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
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.56, 0.40, 0.35) if item_id == "loot_tv" else Vector3(0.42, 0.62, 0.38)
		mesh.mesh = box
		mesh.position = Vector3(float(i % 3 - 1) * 0.48, 0.72, 1.57)
		mesh.material_override = _material(Color(0.16, 0.22, 0.28), 0.42)
		trunk_content.add_child(mesh)


func open_mission_door() -> void:
	GameState.doors["door_front"] = true
	_refresh_state()


func reset_world() -> void:
	departure_started = false
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
