extends Node3D

const SPEED := 6.0
const TOTAL := 8
const TOTAL_SHRINES := 3
const MAX_STAMINA := 100.0

var game_started := false
var player: CharacterBody3D
var camera: Camera3D
var joy := Vector2.ZERO
var joy_id := -1
var joy_start := Vector2.ZERO
var joy_knob: Panel
var look_id := -1
var look_last := Vector2.ZERO
var yaw := 0.0
var pitch := -0.15
var jump_now := false
var sprint_held := false
var stamina := MAX_STAMINA
var found := 0
var found_shrines := 0
var counter: Label
var message: Label
var stamina_bar: ProgressBar
var ui_root: Control


func mat(c: Color, emissive := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = c
	material.roughness = 0.85
	if emissive:
		# Unshaded emission avoids needing a separate point light for every crystal.
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.emission_enabled = true
		material.emission = c * 1.2
	return material


func crystal_shader_material(base: Color = Color(0.06, 0.72, 0.95), highlight: Color = Color(0.62, 0.98, 1.0)) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/crystal.gdshader") as Shader
	material.set_shader_parameter("crystal_color", base)
	material.set_shader_parameter("crystal_highlight", highlight)
	return material


func style_action_button(button: Button, accent: Color) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color(0.91, 0.97, 1.0))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color(0.025, 0.07, 0.12))
	var normal := StyleBoxFlat.new()
	normal.bg_color = accent.darkened(0.78)
	normal.border_color = accent
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(20)
	normal.shadow_color = Color(0.0, 0.02, 0.08, 0.5)
	normal.shadow_size = 7
	normal.shadow_offset = Vector2(0, 3)
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = accent.darkened(0.42)
	hover.shadow_size = 10
	button.add_theme_stylebox_override("hover", hover)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = accent
	pressed.shadow_size = 1
	pressed.shadow_offset = Vector2(0, 1)
	button.add_theme_stylebox_override("pressed", pressed)
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0.12, 0.16, 0.22, 0.75)
	disabled.border_color = Color(0.35, 0.42, 0.5, 0.7)
	button.add_theme_stylebox_override("disabled", disabled)


func block(parent: Node3D, p: Vector3, s: Vector3, c: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = s
	node.mesh = mesh
	node.position = p
	node.material_override = mat(c)
	parent.add_child(node)
	return node


func _ready() -> void:
	Engine.max_fps = 60
	# Create a camera and the full scene before the first visible frame.
	# A solid-color background avoids runtime sky shader compilation on older GPUs.
	_build_world()
	make_ui()


func _build_world() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.47, 0.70, 0.91)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.72, 0.79, 0.91)
	environment.ambient_light_energy = 0.82
	environment.glow_enabled = true
	environment.glow_intensity = 0.58
	environment.glow_bloom = 0.08
	world_environment.environment = environment
	add_child(world_environment)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_energy = 1.15
	sun.light_color = Color(1.0, 0.91, 0.78)
	sun.shadow_enabled = false
	add_child(sun)

	# Main floating island and its collision surface. The custom shader adds
	# procedural grass variation and layered stone without textures.
	var island_surface := block(self, Vector3(0, -1.2, 0), Vector3(30, 2, 30), Color(0.18, 0.45, 0.29))
	var island_material := ShaderMaterial.new()
	island_material.shader = load("res://shaders/island.gdshader") as Shader
	island_surface.material_override = island_material
	var island_body := StaticBody3D.new()
	island_body.position = Vector3(0, -1.2, 0)
	var island_shape := CollisionShape3D.new()
	var island_box := BoxShape3D.new()
	island_box.size = Vector3(30, 2, 30)
	island_shape.shape = island_box
	island_body.add_child(island_shape)
	add_child(island_body)
	block(self, Vector3(0, -2.5, 0), Vector3(23, 1, 23), Color(0.29, 0.32, 0.40))
	block(self, Vector3(0, -3.3, 0), Vector3(15, 1, 15), Color(0.18, 0.21, 0.30))

	# Stone trail and ancient pillars.
	for i in range(7):
		block(self, Vector3(0, -0.05, 7.0 - float(i) * 2.25), Vector3(3, 0.28, 1.7), Color(0.45, 0.49, 0.56))
	for i in range(12):
		var angle := TAU * float(i) / 12.0
		block(self, Vector3(cos(angle) * 13.2, 0.1, sin(angle) * 13.2), Vector3(0.8, 2.0 + float(i % 3) * 0.4, 0.8), Color(0.32, 0.39, 0.48))

	# Eight collectible crystals. No OmniLight3D nodes: per-pixel lighting remains cheap.
	for i in range(TOTAL):
		var angle := TAU * float(i) / float(TOTAL)
		var crystal := Node3D.new()
		crystal.name = "Crystal_%d" % i
		crystal.position = Vector3(cos(angle) * 7, 0.5, sin(angle) * 7)
		crystal.set_meta("crystal", true)
		add_child(crystal)
		var shard := MeshInstance3D.new()
		var prism := PrismMesh.new()
		prism.size = Vector3(0.8, 1.5, 0.8)
		shard.mesh = prism
		shard.material_override = crystal_shader_material()
		crystal.add_child(shard)

	# Three ancient runes provide a second objective beyond crystal collecting.
	var shrine_positions: Array[Vector3] = [
		Vector3(-10.0, -0.04, -7.0),
		Vector3(10.0, -0.04, -7.0),
		Vector3(0.0, -0.04, 11.0)
	]
	for i in range(TOTAL_SHRINES):
		var shrine := Node3D.new()
		shrine.name = "AncientRune_%d" % i
		shrine.position = shrine_positions[i]
		shrine.set_meta("shrine", true)
		shrine.set_meta("activated", false)
		add_child(shrine)
		var pedestal := MeshInstance3D.new()
		var pedestal_mesh := CylinderMesh.new()
		pedestal_mesh.top_radius = 0.95
		pedestal_mesh.bottom_radius = 1.18
		pedestal_mesh.height = 0.42
		pedestal_mesh.radial_segments = 8
		pedestal.mesh = pedestal_mesh
		pedestal.position.y = 0.02
		pedestal.material_override = mat(Color(0.20, 0.27, 0.39))
		shrine.add_child(pedestal)
		var rune := MeshInstance3D.new()
		var rune_mesh := PrismMesh.new()
		rune_mesh.size = Vector3(0.72, 1.35, 0.72)
		rune.mesh = rune_mesh
		rune.position.y = 0.88
		rune.material_override = crystal_shader_material(Color(1.0, 0.43, 0.08), Color(1.0, 0.91, 0.46))
		shrine.add_child(rune)

	# Low-poly trees.
	for i in range(14):
		var angle := TAU * float(i) / 14.0
		var position := Vector3(cos(angle) * 10, 0.3, sin(angle) * 10)
		block(self, position + Vector3(0, 0.8, 0), Vector3(0.35, 1.6, 0.35), Color(0.30, 0.20, 0.13))
		var crown := block(self, position + Vector3(0, 2, 0), Vector3(1.5, 1.5, 1.5), Color(0.13, 0.43 + float(i % 3) * 0.07, 0.31))
		crown.rotation.y = angle

	# Small distant floating rocks add depth without expensive post-processing.
	for i in range(5):
		var x := -23.0 + float(i) * 11.5
		var z := -27.0 - float(i % 2) * 8.0
		block(self, Vector3(x, -1, z), Vector3(7, 1, 7), Color(0.22, 0.38, 0.42))
		block(self, Vector3(x, -2, z), Vector3(4.5, 1.2, 4.5), Color(0.25, 0.28, 0.38))

	player = CharacterBody3D.new()
	player.name = "Player"
	player.position = Vector3(0, -0.1, 9)
	add_child(player)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.8
	collision.shape = capsule
	collision.position.y = 0.9
	player.add_child(collision)
	camera = Camera3D.new()
	camera.position = Vector3(0, 1.48, 0)
	camera.current = true
	player.add_child(camera)


func make_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)
	ui_root = root

	counter = Label.new()
	counter.position = Vector2(24, 18)
	counter.add_theme_font_size_override("font_size", 22)
	counter.add_theme_color_override("font_color", Color(0.77, 0.96, 1.0))
	counter.text = "AETHER • ОСКОЛКИ НЕБА\nКристаллы: 0 / 8  •  Руны: 0 / 3"
	root.add_child(counter)

	var stamina_caption := Label.new()
	stamina_caption.anchor_left = 1.0
	stamina_caption.anchor_right = 1.0
	stamina_caption.offset_left = -278
	stamina_caption.offset_top = 5
	stamina_caption.offset_right = -28
	stamina_caption.offset_bottom = 23
	stamina_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stamina_caption.text = "ЭНЕРГИЯ РЫВКА"
	stamina_caption.add_theme_font_size_override("font_size", 12)
	stamina_caption.add_theme_color_override("font_color", Color(0.74, 0.89, 1.0))
	root.add_child(stamina_caption)

	stamina_bar = ProgressBar.new()
	stamina_bar.anchor_left = 1.0
	stamina_bar.anchor_right = 1.0
	stamina_bar.offset_left = -278
	stamina_bar.offset_top = 27
	stamina_bar.offset_right = -28
	stamina_bar.offset_bottom = 47
	stamina_bar.min_value = 0.0
	stamina_bar.max_value = MAX_STAMINA
	stamina_bar.value = stamina
	stamina_bar.show_percentage = false
	var stamina_style := StyleBoxFlat.new()
	stamina_style.bg_color = Color(0.04, 0.09, 0.17, 0.82)
	stamina_style.set_corner_radius_all(8)
	stamina_bar.add_theme_stylebox_override("background", stamina_style)
	var stamina_fill := StyleBoxFlat.new()
	stamina_fill.bg_color = Color(0.22, 0.86, 0.98)
	stamina_fill.set_corner_radius_all(8)
	stamina_bar.add_theme_stylebox_override("fill", stamina_fill)
	root.add_child(stamina_bar)

	message = Label.new()
	message.anchor_left = 0.5
	message.anchor_right = 0.5
	message.anchor_top = 1.0
	message.anchor_bottom = 1.0
	message.offset_left = -300
	message.offset_right = 300
	message.offset_top = -72
	message.offset_bottom = -24
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size", 19)
	message.add_theme_color_override("font_color", Color.WHITE)
	message.text = "Собери все кристаллы древнего острова"
	root.add_child(message)

	var pad := Panel.new()
	pad.anchor_left = 0.0
	pad.anchor_right = 0.0
	pad.anchor_top = 1.0
	pad.anchor_bottom = 1.0
	pad.offset_left = 30
	pad.offset_top = -195
	pad.offset_right = 195
	pad.offset_bottom = -30
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pad_style := StyleBoxFlat.new()
	pad_style.bg_color = Color(0.05, 0.12, 0.22, 0.53)
	pad_style.border_color = Color(0.25, 0.75, 0.91, 0.55)
	pad_style.set_border_width_all(2)
	pad_style.set_corner_radius_all(82)
	pad_style.shadow_color = Color(0.0, 0.02, 0.08, 0.45)
	pad_style.shadow_size = 8
	pad.add_theme_stylebox_override("panel", pad_style)
	root.add_child(pad)
	var pad_text := Label.new()
	pad_text.text = "MOVE"
	pad_text.anchor_left = 0.0
	pad_text.anchor_right = 1.0
	pad_text.anchor_top = 0.0
	pad_text.anchor_bottom = 0.0
	pad_text.offset_top = 10
	pad_text.offset_bottom = 32
	pad_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pad_text.add_theme_font_size_override("font_size", 11)
	pad_text.add_theme_color_override("font_color", Color(0.72, 0.91, 1.0))
	pad_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.add_child(pad_text)
	joy_knob = Panel.new()
	joy_knob.position = Vector2(55, 60)
	joy_knob.size = Vector2(54, 54)
	joy_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var knob_style := StyleBoxFlat.new()
	knob_style.bg_color = Color(0.19, 0.52, 0.69, 0.76)
	knob_style.border_color = Color(0.53, 0.91, 1.0, 0.95)
	knob_style.set_border_width_all(2)
	knob_style.set_corner_radius_all(28)
	knob_style.shadow_color = Color(0.0, 0.02, 0.08, 0.3)
	knob_style.shadow_size = 4
	joy_knob.add_theme_stylebox_override("panel", knob_style)
	pad.add_child(joy_knob)

	var jump := Button.new()
	jump.text = "ПРЫЖОК"
	jump.anchor_left = 1.0
	jump.anchor_right = 1.0
	jump.anchor_top = 1.0
	jump.anchor_bottom = 1.0
	jump.offset_left = -155
	jump.offset_top = -145
	jump.offset_right = -25
	jump.offset_bottom = -35
	style_action_button(jump, Color(0.22, 0.88, 1.0))
	jump.pressed.connect(func(): jump_now = true)
	root.add_child(jump)

	var take := Button.new()
	take.text = "РЕЛИКТ"
	take.anchor_left = 1.0
	take.anchor_right = 1.0
	take.anchor_top = 1.0
	take.anchor_bottom = 1.0
	take.offset_left = -290
	take.offset_top = -120
	take.offset_right = -165
	take.offset_bottom = -35
	style_action_button(take, Color(1.0, 0.72, 0.28))
	take.pressed.connect(collect_nearby)
	root.add_child(take)

	var sprint := Button.new()
	sprint.text = "РЫВОК"
	sprint.anchor_left = 1.0
	sprint.anchor_right = 1.0
	sprint.anchor_top = 1.0
	sprint.anchor_bottom = 1.0
	sprint.offset_left = -425
	sprint.offset_top = -120
	sprint.offset_right = -300
	sprint.offset_bottom = -35
	style_action_button(sprint, Color(0.64, 0.48, 1.0))
	sprint.button_down.connect(func(): sprint_held = true)
	sprint.button_up.connect(func(): sprint_held = false)
	root.add_child(sprint)

	var menu := Control.new()
	menu.name = "StartMenu"
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(menu)
	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.025, 0.05, 0.11, 0.96)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	menu.add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(440, 390)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.055, 0.105, 0.19, 0.98)
	panel_style.border_color = Color(0.15, 0.78, 0.95, 0.9)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(24)
	panel_style.content_margin_left = 28
	panel_style.content_margin_right = 28
	panel_style.content_margin_top = 26
	panel_style.content_margin_bottom = 26
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 15)
	panel.add_child(stack)

	var logo := Label.new()
	logo.text = "AETHER"
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.add_theme_font_size_override("font_size", 48)
	logo.add_theme_color_override("font_color", Color(0.5, 0.9, 1.0))
	stack.add_child(logo)

	var subtitle := Label.new()
	subtitle.text = "ОСКОЛКИ НЕБА"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 22)
	subtitle.add_theme_color_override("font_color", Color(0.91, 0.96, 1.0))
	stack.add_child(subtitle)

	var story := Label.new()
	story.text = "Исследуй древний остров в облаках\nи собери 8 светящихся кристаллов."
	story.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story.add_theme_font_size_override("font_size", 17)
	story.add_theme_color_override("font_color", Color(0.71, 0.81, 0.91))
	stack.add_child(story)

	var play := Button.new()
	play.text = "ИГРАТЬ"
	play.custom_minimum_size = Vector2(270, 62)
	play.add_theme_font_size_override("font_size", 23)
	play.add_theme_color_override("font_color", Color(0.02, 0.08, 0.14))
	var play_style := StyleBoxFlat.new()
	play_style.bg_color = Color(0.24, 0.84, 0.98)
	play_style.border_color = Color(0.71, 0.97, 1.0)
	play_style.set_border_width_all(1)
	play_style.set_corner_radius_all(16)
	play_style.shadow_color = Color(0.0, 0.16, 0.28, 0.55)
	play_style.shadow_size = 9
	play_style.shadow_offset = Vector2(0, 4)
	play_style.content_margin_top = 12
	play_style.content_margin_bottom = 12
	play.add_theme_stylebox_override("normal", play_style)
	var hover_style := play_style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color(0.48, 0.91, 1.0)
	hover_style.shadow_size = 13
	play.add_theme_stylebox_override("hover", hover_style)
	var pressed_style := play_style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = Color(0.16, 0.68, 0.84)
	pressed_style.shadow_size = 2
	pressed_style.shadow_offset = Vector2(0, 1)
	play.add_theme_stylebox_override("pressed", pressed_style)
	play.pressed.connect(func():
		game_started = true
		menu.queue_free()
	)
	stack.add_child(play)

	var hints := Label.new()
	hints.text = "Слева — движение, правая сторона — обзор\nПРЫЖОК • РЕЛИКТ • РЫВОК (тратит энергию)"
	hints.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hints.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hints.add_theme_font_size_override("font_size", 13)
	hints.add_theme_color_override("font_color", Color(0.61, 0.73, 0.85))
	stack.add_child(hints)


func _input(event: InputEvent) -> void:
	if not game_started:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x < get_viewport().get_visible_rect().size.x * 0.42 and joy_id == -1:
				joy_id = event.index
				joy_start = event.position
				joy = Vector2.ZERO
				if is_instance_valid(joy_knob):
					joy_knob.position = Vector2(55, 60)
			elif event.position.y < get_viewport().get_visible_rect().size.y - 180 and look_id == -1:
				look_id = event.index
				look_last = event.position
		else:
			if event.index == joy_id:
				joy_id = -1
				joy = Vector2.ZERO
				if is_instance_valid(joy_knob):
					joy_knob.position = Vector2(55, 60)
			if event.index == look_id:
				look_id = -1
	if event is InputEventScreenDrag:
		if event.index == joy_id:
			joy = ((event.position - joy_start) / 65.0).limit_length(1.0)
			if is_instance_valid(joy_knob):
				joy_knob.position = Vector2(55, 60) + joy * 38.0
		elif event.index == look_id:
			var difference: Vector2 = event.position - look_last
			yaw -= difference.x * 0.006
			pitch = clampf(pitch - difference.y * 0.004, -1.0, 0.7)
			look_last = event.position
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		yaw -= event.relative.x * 0.004
		pitch = clampf(pitch - event.relative.y * 0.004, -1.0, 0.7)


func _physics_process(delta: float) -> void:
	if not game_started or not is_instance_valid(player):
		return
	var movement := joy
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		movement.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		movement.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		movement.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		movement.x += 1
	movement = movement.limit_length(1.0)

	var current_speed := SPEED
	var wants_sprint := sprint_held or Input.is_key_pressed(KEY_SHIFT)
	if wants_sprint and stamina > 0.5 and movement.length() > 0.08:
		stamina = maxf(0.0, stamina - 30.0 * delta)
		current_speed = SPEED * 1.65
	else:
		stamina = minf(MAX_STAMINA, stamina + 21.0 * delta)
	if is_instance_valid(stamina_bar):
		stamina_bar.value = stamina

	var direction := Vector3(
		sin(yaw) * movement.y + cos(yaw) * movement.x,
		0.0,
		cos(yaw) * movement.y - sin(yaw) * movement.x
	)
	if direction.length() > 0.01:
		player.velocity.x = direction.x * current_speed
		player.velocity.z = direction.z * current_speed
	else:
		player.velocity.x = move_toward(player.velocity.x, 0.0, SPEED * 4.0 * delta)
		player.velocity.z = move_toward(player.velocity.z, 0.0, SPEED * 4.0 * delta)

	if not player.is_on_floor():
		player.velocity.y -= 18.0 * delta
	elif jump_now or Input.is_key_pressed(KEY_SPACE):
		player.velocity.y = 7.5
	jump_now = false
	player.rotation.y = yaw
	camera.rotation.x = pitch
	player.move_and_slide()

	for node in get_children():
		if node.has_meta("crystal"):
			node.rotation.y += delta * 0.7
			node.position.y = 0.5 + sin(Time.get_ticks_msec() * 0.002 + node.position.x) * 0.18
		elif node.has_meta("shrine"):
			for child in node.get_children():
				if child is MeshInstance3D and child.position.y > 0.5:
					child.rotation.y += delta * 0.45

	if player.position.y < -10.0:
		player.position = Vector3(0, -0.1, 9)
		player.velocity = Vector3.ZERO


func update_counter() -> void:
	if is_instance_valid(counter):
		counter.text = "AETHER • ОСКОЛКИ НЕБА\nКристаллы: %d / %d  •  Руны: %d / %d" % [found, TOTAL, found_shrines, TOTAL_SHRINES]


func collect_nearby() -> void:
	if not game_started or not is_instance_valid(player):
		return
	var nearest: Node3D = null
	var nearest_distance := 3.8
	for node in get_children():
		var available_crystal: bool = node.has_meta("crystal")
		var available_shrine: bool = node.has_meta("shrine") and not bool(node.get_meta("activated", false))
		if available_crystal or available_shrine:
			var distance: float = player.global_position.distance_to(node.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest = node
	if nearest == null:
		message.text = "Подойди ближе к кристаллу или древней руне"
		return

	if nearest.has_meta("crystal"):
		nearest.queue_free()
		found += 1
		stamina = minf(MAX_STAMINA, stamina + 18.0)
		message.text = "Осколок собран — осталось: %d" % (TOTAL - found)
	else:
		nearest.set_meta("activated", true)
		found_shrines += 1
		for child in nearest.get_children():
			if child is MeshInstance3D and child.position.y > 0.5:
				child.material_override = mat(Color(1.0, 0.67, 0.18), true)
		message.text = "Древняя руна пробуждена — осталось: %d" % (TOTAL_SHRINES - found_shrines)

	update_counter()
	if found >= TOTAL and found_shrines >= TOTAL_SHRINES:
		show_victory()
	elif found >= TOTAL:
		message.text = "Кристаллы найдены! Активируй оставшиеся руны."
	elif found_shrines >= TOTAL_SHRINES:
		message.text = "Руны пробуждены! Найди оставшиеся кристаллы."


func show_victory() -> void:
	game_started = false
	message.text = "ОСТРОВ ПРОБУЖДЁН"
	var backdrop := ColorRect.new()
	backdrop.name = "VictoryOverlay"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.015, 0.035, 0.075, 0.88)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	ui_root.add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(430, 285)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.045, 0.095, 0.17, 0.98)
	panel_style.border_color = Color(0.28, 0.85, 1.0, 0.95)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(24)
	panel_style.shadow_color = Color(0.0, 0.02, 0.1, 0.65)
	panel_style.shadow_size = 14
	panel_style.content_margin_left = 26
	panel_style.content_margin_right = 26
	panel_style.content_margin_top = 25
	panel_style.content_margin_bottom = 25
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 16)
	panel.add_child(stack)
	var title := Label.new()
	title.text = "ОСТРОВ ПРОБУЖДЁН"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 27)
	title.add_theme_color_override("font_color", Color(0.54, 0.94, 1.0))
	stack.add_child(title)
	var detail := Label.new()
	detail.text = "8/8 кристаллов • 3/3 руны\nПамять древнего острова восстановлена."
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_theme_font_size_override("font_size", 16)
	detail.add_theme_color_override("font_color", Color(0.78, 0.87, 0.96))
	stack.add_child(detail)
	var restart := Button.new()
	restart.text = "ИГРАТЬ СНОВА"
	restart.custom_minimum_size = Vector2(280, 58)
	style_action_button(restart, Color(0.22, 0.88, 1.0))
	restart.pressed.connect(func(): get_tree().reload_current_scene())
	stack.add_child(restart)
