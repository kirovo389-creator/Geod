extends Node3D

var body_root: Node3D
var carried_prop: MeshInstance3D
var name_tag: Label3D


func _ready() -> void:
	body_root = Node3D.new()
	add_child(body_root)
	_add_part(Vector3(0, 1.15, 0), Vector3(0.56, 0.72, 0.30), Color(0.20, 0.47, 0.64))
	_add_part(Vector3(0, 0.55, 0), Vector3(0.42, 0.36, 0.28), Color(0.10, 0.12, 0.15))
	_add_part(Vector3(0, 1.72, 0), Vector3(0.38, 0.38, 0.38), Color(0.72, 0.55, 0.40), true)
	_add_part(Vector3(-0.20, 0.46, 0.03), Vector3(0.16, 0.45, 0.18), Color(0.13, 0.18, 0.24))
	_add_part(Vector3(0.20, 0.46, 0.03), Vector3(0.16, 0.45, 0.18), Color(0.13, 0.18, 0.24))
	_add_part(Vector3(0, 1.15, 0.20), Vector3(0.36, 0.45, 0.15), Color(0.36, 0.25, 0.16))
	name_tag = Label3D.new()
	name_tag.text = "НАПАРНИК"
	name_tag.position = Vector3(0, 2.18, 0)
	name_tag.font_size = 32
	name_tag.outline_size = 5
	name_tag.modulate = Color(0.72, 0.96, 1.0)
	name_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(name_tag)


func _add_part(pos: Vector3, size: Vector3, color: Color, round_part := false) -> void:
	var mesh_node := MeshInstance3D.new()
	if round_part:
		var sphere := SphereMesh.new()
		sphere.radius = size.x * 0.5
		sphere.height = size.y
		mesh_node.mesh = sphere
	else:
		var box := BoxMesh.new()
		box.size = size
		mesh_node.mesh = box
	mesh_node.position = pos
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	mesh_node.material_override = material
	body_root.add_child(mesh_node)


func apply_transform(world_position: Vector3, world_yaw: float) -> void:
	global_position = global_position.lerp(world_position, 0.45)
	rotation.y = lerp_angle(rotation.y, world_yaw, 0.45)


func set_carrying(enabled: bool) -> void:
	if enabled and not is_instance_valid(carried_prop):
		carried_prop = MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.65, 0.48, 0.2)
		carried_prop.mesh = mesh
		carried_prop.position = Vector3(0, 1.25, -0.48)
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.12, 0.15, 0.18)
		carried_prop.material_override = material
		add_child(carried_prop)
	elif not enabled and is_instance_valid(carried_prop):
		carried_prop.queue_free()
		carried_prop = null
