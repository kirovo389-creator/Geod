extends Node3D

const SPEED := 6.0
var game_started := false
var player: CharacterBody3D
var camera: Camera3D
var joy := Vector2.ZERO
var joy_id := -1
var joy_start := Vector2.ZERO
var look_id := -1
var look_last := Vector2.ZERO
var yaw := 0.0
var pitch := -0.15
var jump_now := false
var found := 0
var counter: Label
var message: Label
const TOTAL := 8

func mat(c: Color, metal := 0.0, emissive := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.72
	m.metallic = metal
	if emissive:
		m.emission_enabled = true
		m.emission = c
	return m

func block(parent: Node3D, p: Vector3, s: Vector3, c: Color) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = s
	n.mesh = mesh
	n.position = p
	n.material_override = mat(c)
	parent.add_child(n)
	return n

func _ready() -> void:
	# Render the menu before constructing the 3D world, avoiding a blank launch frame.
	make_ui()
	await get_tree().create_timer(0.5).timeout
	_build_world()

func _build_world() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.5, 0.75, 0.94)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.72, 0.9)
	env.ambient_light_energy = 0.8
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.shadow_enabled = false
	add_child(sun)
	block(self, Vector3(0,-1.2,0), Vector3(30,2,30), Color(0.18,0.45,0.29))
	var island_body := StaticBody3D.new()
	island_body.position = Vector3(0,-1.2,0)
	var island_shape := CollisionShape3D.new()
	var island_box := BoxShape3D.new()
	island_box.size = Vector3(30,2,30)
	island_shape.shape = island_box
	island_body.add_child(island_shape)
	add_child(island_body)
	block(self, Vector3(0,-2.5,0), Vector3(23,1,23), Color(0.29,0.32,0.4))
	block(self, Vector3(0,-3.3,0), Vector3(15,1,15), Color(0.18,0.21,0.3))
	for i in range(7):
		block(self, Vector3(0,-0.05,7.0-float(i)*2.25), Vector3(3,0.28,1.7), Color(0.45,0.49,0.56))
	for i in range(12):
		var a := TAU*float(i)/12.0
		block(self, Vector3(cos(a)*11,0.1,sin(a)*11), Vector3(0.8,2.0+float(i%3)*0.4,0.8), Color(0.32,0.39,0.48))
	for i in range(TOTAL):
		var a := TAU*float(i)/float(TOTAL)
		var crystal := Node3D.new()
		crystal.name = "Crystal_%d" % i
		crystal.position = Vector3(cos(a)*7,0.5,sin(a)*7)
		crystal.set_meta("crystal",true)
		add_child(crystal)
		var shard := MeshInstance3D.new()
		var prism := PrismMesh.new()
		prism.size = Vector3(0.8,1.5,0.8)
		shard.mesh = prism
		shard.material_override = mat(Color(0.12,0.88,1.0),0.35,true)
		crystal.add_child(shard)
	for i in range(14):
		var a := TAU*float(i)/14.0
		var p := Vector3(cos(a)*10,0.3,sin(a)*10)
		block(self,p+Vector3(0,0.8,0),Vector3(0.35,1.6,0.35),Color(0.3,0.2,0.13))
		var crown := block(self,p+Vector3(0,2,0),Vector3(1.5,1.5,1.5),Color(0.13,0.43+float(i%3)*0.07,0.31))
		crown.rotation.y = a
	for i in range(5):
		var x := -23.0+float(i)*11.5
		var z := -27.0-float(i%2)*8.0
		block(self,Vector3(x,-1,z),Vector3(7,1,7),Color(0.22,0.38,0.42))
		block(self,Vector3(x,-2,z),Vector3(4.5,1.2,4.5),Color(0.25,0.28,0.38))
	player = CharacterBody3D.new()
	player.position = Vector3(0,1.4,9)
	add_child(player)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.8
	collision.shape = capsule
	player.add_child(collision)
	camera = Camera3D.new()
	camera.position.y = 0.58
	player.add_child(camera)
	camera.current = true

func make_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)
	counter = Label.new()
	counter.position = Vector2(24,20)
	counter.add_theme_font_size_override("font_size",26)
	counter.add_theme_color_override("font_color",Color(0.7,0.96,1))
	counter.text = "AETHER • ОСКОЛКИ НЕБА\nКристаллы: 0 / 8"
	root.add_child(counter)
	message = Label.new()
	message.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	message.position = Vector2(-250,-75)
	message.size = Vector2(500,45)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size",19)
	message.text = "Собери все кристаллы древнего острова"
	root.add_child(message)
	var pad := ColorRect.new()
	pad.position = Vector2(30,-195)
	pad.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	pad.size = Vector2(165,165)
	pad.color = Color(0.15,0.25,0.38,0.48)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(pad)
	var ptxt := Label.new()
	ptxt.text = "MOVE"
	ptxt.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ptxt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ptxt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ptxt.add_theme_color_override("font_color",Color(0.8,0.9,1))
	ptxt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.add_child(ptxt)
	var jump := Button.new()
	jump.text = "JUMP"
	jump.position = Vector2(-145,-150)
	jump.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	jump.size = Vector2(115,90)
	jump.pressed.connect(func(): jump_now = true)
	root.add_child(jump)
	var take := Button.new()
	take.text = "TAKE"
	take.position = Vector2(-270,-70)
	take.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	take.size = Vector2(115,65)
	take.pressed.connect(collect_nearby)
	root.add_child(take)

	var menu_ui := Control.new()
	menu_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(menu_ui)

	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.025, 0.05, 0.11, 0.985)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	menu_ui.add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_ui.add_child(center)

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
	stack.add_theme_constant_override("separation", 18)
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
	play_style.set_corner_radius_all(16)
	play_style.content_margin_top = 12
	play_style.content_margin_bottom = 12
	play.add_theme_stylebox_override("normal", play_style)
	var hover_style := play_style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color(0.48, 0.91, 1.0)
	play.add_theme_stylebox_override("hover", hover_style)
	play.add_theme_stylebox_override("pressed", hover_style)
	play.pressed.connect(func():
		game_started = true
		menu_ui.queue_free()
	)
	stack.add_child(play)

	var hints := Label.new()
	hints.text = "Управление: левая сторона — движение\nправая — обзор • JUMP — прыжок • TAKE — взять"
	hints.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hints.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hints.add_theme_font_size_override("font_size", 13)
	hints.add_theme_color_override("font_color", Color(0.61, 0.73, 0.85))
	stack.add_child(hints)

func _input(e: InputEvent) -> void:
	if not game_started:
		return
	if e is InputEventScreenTouch:
		if e.pressed:
			if e.position.x < get_viewport().get_visible_rect().size.x*0.4 and joy_id == -1:
				joy_id = e.index
				joy_start = e.position
			elif look_id == -1:
				look_id = e.index
				look_last = e.position
		else:
			if e.index == joy_id:
				joy_id = -1
				joy = Vector2.ZERO
			if e.index == look_id:
				look_id = -1
	if e is InputEventScreenDrag:
		if e.index == joy_id:
			joy = ((e.position-joy_start)/65.0).limit_length(1.0)
		elif e.index == look_id:
			var d: Vector2 = e.position-look_last
			yaw -= d.x*0.006
			pitch = clampf(pitch-d.y*0.004,-1.0,0.7)
			look_last = e.position
	if e is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		yaw -= e.relative.x*0.004
		pitch = clampf(pitch-e.relative.y*0.004,-1.0,0.7)

func _physics_process(delta: float) -> void:
	if not game_started:
		return
	if not is_instance_valid(player):
		return
	var v := joy
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): v.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): v.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): v.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): v.x += 1
	v = v.limit_length(1.0)
	var dir := Vector3(sin(yaw)*v.y+cos(yaw)*v.x,0,cos(yaw)*v.y-sin(yaw)*v.x)
	player.velocity.x = dir.x*SPEED if dir.length()>0.01 else move_toward(player.velocity.x,0,SPEED*4*delta)
	player.velocity.z = dir.z*SPEED if dir.length()>0.01 else move_toward(player.velocity.z,0,SPEED*4*delta)
	if not player.is_on_floor():
		player.velocity.y -= 18.0*delta
	elif jump_now or Input.is_key_pressed(KEY_SPACE):
		player.velocity.y = 7.5
	jump_now = false
	player.rotation.y = yaw
	camera.rotation.x = pitch
	player.move_and_slide()
	for n in get_children():
		if n.has_meta("crystal"):
			n.rotation.y += delta*0.7
			n.position.y = 0.5+sin(Time.get_ticks_msec()*0.002+n.position.x)*0.18
	if player.position.y < -10:
		player.position = Vector3(0,2,9)
		player.velocity = Vector3.ZERO

func collect_nearby() -> void:
	var nearest: Node3D
	var best := 3.0
	for n in get_children():
		if n.has_meta("crystal"):
			var d := player.global_position.distance_to(n.global_position)
			if d < best:
				best = d
				nearest = n
	if nearest:
		nearest.queue_free()
		found += 1
		counter.text = "AETHER • ОСКОЛКИ НЕБА\nКристаллы: %d / %d" % [found,TOTAL]
		message.text = "Все осколки собраны!" if found >= TOTAL else "Кристалл найден — осталось: %d" % (TOTAL-found)
	else:
		message.text = "Подойди ближе к голубому кристаллу"
