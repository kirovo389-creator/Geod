extends Node3D

var body_root: Node3D
var carried_prop: Node3D
var name_tag: Label3D
var motion_phase := 0.0


func _ready() -> void:
	body_root = Node3D.new()
	body_root.name = "WorkerModel"
	add_child(body_root)

	# Work shoes, separate trousers and visible seams form a readable silhouette.
	_add_box("Boot_Left", Vector3(-0.135, 0.13, -0.045), Vector3(0.23, 0.16, 0.34), Color(0.045, 0.055, 0.065), 0.86)
	_add_box("Boot_Right", Vector3(0.135, 0.13, -0.045), Vector3(0.23, 0.16, 0.34), Color(0.045, 0.055, 0.065), 0.86)
	_add_box("Boot_Sole_Left", Vector3(-0.135, 0.065, -0.04), Vector3(0.235, 0.035, 0.34), Color(0.015, 0.02, 0.025), 0.98)
	_add_box("Boot_Sole_Right", Vector3(0.135, 0.065, -0.04), Vector3(0.235, 0.035, 0.34), Color(0.015, 0.02, 0.025), 0.98)
	_add_capsule("Trouser_Left", Vector3(-0.14, 0.48, 0.025), 0.105, 0.67, Color(0.10, 0.16, 0.21))
	_add_capsule("Trouser_Right", Vector3(0.14, 0.48, 0.025), 0.105, 0.67, Color(0.10, 0.16, 0.21))
	_add_box("Utility_Belt", Vector3(0, 0.86, 0.0), Vector3(0.44, 0.095, 0.32), Color(0.16, 0.12, 0.085), 0.96)
	_add_box("Belt_Buckle", Vector3(0, 0.86, -0.168), Vector3(0.075, 0.045, 0.018), Color(0.68, 0.52, 0.22), 0.35, 0.6)

	# Layered work jacket and simple reflective safety panels.
	_add_capsule("Jacket_Torso", Vector3(0, 1.25, 0), 0.275, 0.76, Color(0.10, 0.24, 0.29))
	_add_box("Jacket_Front_Panel", Vector3(0, 1.29, -0.235), Vector3(0.30, 0.48, 0.035), Color(0.13, 0.29, 0.34), 0.88)
	_add_box("Reflective_Chest_Band", Vector3(0, 1.34, -0.258), Vector3(0.51, 0.075, 0.026), Color(0.80, 0.63, 0.23), 0.55, 0.12)
	_add_box("Reflective_Waist_Band", Vector3(0, 1.00, -0.255), Vector3(0.47, 0.055, 0.024), Color(0.80, 0.63, 0.23), 0.58, 0.08)
	_add_capsule("Neck", Vector3(0, 1.69, 0), 0.095, 0.17, Color(0.56, 0.39, 0.29))
	_add_sphere("Head", Vector3(0, 1.83, -0.005), 0.158, 0.34, Color(0.69, 0.50, 0.37))
	_add_sphere("Hair", Vector3(0, 1.94, 0.015), 0.162, 0.17, Color(0.16, 0.12, 0.095))
	_add_box("Hairline", Vector3(0, 1.91, -0.135), Vector3(0.245, 0.065, 0.048), Color(0.16, 0.12, 0.095), 0.9)

	# Small face features make the head less like a featureless cube/sphere.
	_add_sphere("Eye_Left", Vector3(-0.052, 1.84, -0.151), 0.018, 0.022, Color(0.93, 0.88, 0.76))
	_add_sphere("Eye_Right", Vector3(0.052, 1.84, -0.151), 0.018, 0.022, Color(0.93, 0.88, 0.76))
	_add_sphere("Pupil_Left", Vector3(-0.052, 1.84, -0.166), 0.008, 0.01, Color(0.04, 0.045, 0.05))
	_add_sphere("Pupil_Right", Vector3(0.052, 1.84, -0.166), 0.008, 0.01, Color(0.04, 0.045, 0.05))
	_add_capsule("Nose", Vector3(0, 1.79, -0.164), 0.024, 0.065, Color(0.62, 0.43, 0.31))

	# Arms hang below the shoulder line; gloves and cuffs are distinct pieces.
	_add_capsule("Sleeve_Left", Vector3(-0.365, 1.22, 0.005), 0.09, 0.62, Color(0.10, 0.23, 0.28), Vector3(0, 0, -0.12))
	_add_capsule("Sleeve_Right", Vector3(0.365, 1.22, 0.005), 0.09, 0.62, Color(0.10, 0.23, 0.28), Vector3(0, 0, 0.12))
	_add_box("Cuff_Left", Vector3(-0.39, 0.94, -0.01), Vector3(0.16, 0.075, 0.16), Color(0.78, 0.61, 0.22), 0.75)
	_add_box("Cuff_Right", Vector3(0.39, 0.94, -0.01), Vector3(0.16, 0.075, 0.16), Color(0.78, 0.61, 0.22), 0.75)
	_add_sphere("Glove_Left", Vector3(-0.40, 0.85, -0.03), 0.095, 0.14, Color(0.07, 0.11, 0.13))
	_add_sphere("Glove_Right", Vector3(0.40, 0.85, -0.03), 0.095, 0.14, Color(0.07, 0.11, 0.13))

	# Work backpack: shell, top flap, side pockets and shoulder straps.
	_add_box("Backpack_Main", Vector3(0, 1.25, 0.245), Vector3(0.39, 0.48, 0.18), Color(0.18, 0.15, 0.11), 0.98)
	_add_box("Backpack_Flap", Vector3(0, 1.49, 0.155), Vector3(0.34, 0.105, 0.035), Color(0.25, 0.20, 0.14), 0.96)
	_add_box("Backpack_Pocket", Vector3(0, 1.17, 0.145), Vector3(0.27, 0.15, 0.035), Color(0.23, 0.19, 0.14), 0.96)
	_add_box("Backpack_Strap_Left", Vector3(-0.19, 1.31, -0.105), Vector3(0.065, 0.43, 0.04), Color(0.29, 0.23, 0.16), 0.98)
	_add_box("Backpack_Strap_Right", Vector3(0.19, 1.31, -0.105), Vector3(0.065, 0.43, 0.04), Color(0.29, 0.23, 0.16), 0.98)
	_add_box("Tool_Pouch", Vector3(0.26, 0.95, 0.07), Vector3(0.14, 0.22, 0.12), Color(0.20, 0.16, 0.11), 0.98)

	name_tag = Label3D.new()
	name_tag.text = "НАПАРНИК"
	name_tag.position = Vector3(0, 2.24, 0)
	name_tag.font_size = 27
	name_tag.outline_size = 5
	name_tag.modulate = Color(0.75, 0.94, 0.96)
	name_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(name_tag)


func _add_box(part_name: String, pos: Vector3, dimensions: Vector3, tint: Color, roughness := 0.84, metallic := 0.0) -> MeshInstance3D:
	var mesh_node := MeshInstance3D.new()
	mesh_node.name = part_name
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	mesh_node.mesh = mesh
	mesh_node.position = pos
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.roughness = roughness
	material.metallic = metallic
	mesh_node.material_override = material
	body_root.add_child(mesh_node)
	return mesh_node


func _add_capsule(part_name: String, pos: Vector3, radius: float, height: float, tint: Color, rotation_value := Vector3.ZERO) -> MeshInstance3D:
	var mesh_node := MeshInstance3D.new()
	mesh_node.name = part_name
	var capsule := CapsuleMesh.new()
	capsule.radius = radius
	capsule.height = height
	capsule.radial_segments = 10
	capsule.rings = 5
	mesh_node.mesh = capsule
	mesh_node.position = pos
	mesh_node.rotation = rotation_value
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.roughness = 0.87
	mesh_node.material_override = material
	body_root.add_child(mesh_node)
	return mesh_node


func _add_sphere(part_name: String, pos: Vector3, radius: float, height: float, tint: Color) -> MeshInstance3D:
	var mesh_node := MeshInstance3D.new()
	mesh_node.name = part_name
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = height
	sphere.radial_segments = 12
	sphere.rings = 6
	mesh_node.mesh = sphere
	mesh_node.position = pos
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.roughness = 0.86
	mesh_node.material_override = material
	body_root.add_child(mesh_node)
	return mesh_node


func apply_transform(world_position: Vector3, world_yaw: float) -> void:
	global_position = global_position.lerp(world_position, 0.45)
	rotation.y = lerp_angle(rotation.y, world_yaw, 0.45)


func set_carrying(enabled: bool) -> void:
	if enabled and not is_instance_valid(carried_prop):
		carried_prop = Node3D.new()
		carried_prop.name = "CarriedProp"
		carried_prop.position = Vector3(0, 1.25, -0.48)
		add_child(carried_prop)
		var prop := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.65, 0.48, 0.2)
		prop.mesh = mesh
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.10, 0.13, 0.17)
		material.roughness = 0.36
		prop.material_override = material
		carried_prop.add_child(prop)
	elif not enabled and is_instance_valid(carried_prop):
		carried_prop.queue_free()
		carried_prop = null
