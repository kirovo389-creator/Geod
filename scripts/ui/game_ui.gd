extends CanvasLayer

signal start_requested(mode: String, address: String)
signal dialogue_advance
signal dialogue_skipped
signal use_pressed
signal phone_call_requested
signal sprint_changed(held: bool)
signal drop_pressed
signal pause_pressed
signal resume_pressed
signal return_to_menu
signal settings_changed(key: String, value: Variant)
signal modal_changed(open: bool)

var menu_layer: Control
var hud_layer: Control
var dialogue_panel: PanelContainer
var dialogue_speaker: Label
var dialogue_text: Label
var phone_panel: PanelContainer
var phone_title: Label
var phone_content: Label
var phone_call_button: Button
var pause_panel: PanelContainer
var result_panel: PanelContainer
var result_text: Label
var settings_panel: PanelContainer
var status_label: Label
var objective_label: Label
var task_label: Label
var money_label: Label
var focus_label: Label
var use_button: Button
var drop_button: Button
var toast_label: Label
var toast_timer: Timer
var address_input: LineEdit
var focus_info: Dictionary = {}
var pause_return_to_menu := false


func _ready() -> void:
	add_to_group("game_ui")
	_build_menu()
	_build_hud()
	_build_dialogue()
	_build_phone()
	_build_pause()
	_build_result()
	_build_settings()
	show_menu(false)
	refresh_state()


func _style_panel(panel: PanelContainer, background: Color, border: Color, radius := 18) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0.0, 0.02, 0.08, 0.48)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 4)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 19
	style.content_margin_bottom = 19
	panel.add_theme_stylebox_override("panel", style)


func _button(text: String, accent: Color, font_size := 17) -> Button:
	var result := Button.new()
	result.text = text
	result.custom_minimum_size = Vector2(0, 46)
	result.focus_mode = Control.FOCUS_NONE
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", Color(0.92, 0.97, 1.0))
	result.add_theme_color_override("font_hover_color", Color.WHITE)
	result.add_theme_color_override("font_pressed_color", Color(0.025, 0.055, 0.075))
	var normal := StyleBoxFlat.new()
	normal.bg_color = accent.darkened(0.78)
	normal.border_color = accent
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(12)
	normal.shadow_color = Color(0.0, 0.02, 0.08, 0.35)
	normal.shadow_size = 4
	normal.shadow_offset = Vector2(0, 2)
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	result.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = accent.darkened(0.45)
	hover.shadow_size = 7
	result.add_theme_stylebox_override("hover", hover)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = accent
	pressed.shadow_size = 1
	pressed.shadow_offset = Vector2(0, 1)
	result.add_theme_stylebox_override("pressed", pressed)
	return result


func _panel_overlay(parent: Control, alpha: float) -> ColorRect:
	var overlay := ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.012, 0.022, 0.043, alpha)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(overlay)
	return overlay


func _build_menu() -> void:
	menu_layer = Control.new()
	menu_layer.name = "MainMenu"
	menu_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(menu_layer)
	_panel_overlay(menu_layer, 0.66)

	var frame := HBoxContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.offset_left = 40
	frame.offset_top = 26
	frame.offset_right = -40
	frame.offset_bottom = -26
	frame.add_theme_constant_override("separation", 22)
	menu_layer.add_child(frame)

	var left_panel := PanelContainer.new()
	left_panel.custom_minimum_size = Vector2(465, 0)
	left_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_style_panel(left_panel, Color(0.035, 0.060, 0.09, 0.97), Color(0.20, 0.75, 0.86, 0.8), 22)
	frame.add_child(left_panel)

	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 11)
	left_panel.add_child(stack)

	var eyebrow := Label.new()
	eyebrow.text = "ИНДИ-СИМУЛЯТОР • КООПЕРАТИВ"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.add_theme_font_size_override("font_size", 12)
	eyebrow.add_theme_color_override("font_color", Color(0.44, 0.83, 0.91))
	stack.add_child(eyebrow)

	var logo := Label.new()
	logo.text = "HOW TO SUCK"
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.add_theme_font_size_override("font_size", 38)
	logo.add_theme_color_override("font_color", Color(0.87, 0.96, 1.0))
	stack.add_child(logo)

	var subtitle := Label.new()
	subtitle.text = "УБОРКА — ЭТО ТОЛЬКО НАЧАЛО"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 17)
	subtitle.add_theme_color_override("font_color", Color(0.53, 0.87, 0.95))
	stack.add_child(subtitle)

	var story := Label.new()
	story.text = "Первый заказ: частный дом. Выполни чек-лист, дождись отъезда хозяина и реши, что делать дальше."
	story.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story.add_theme_font_size_override("font_size", 15)
	story.add_theme_color_override("font_color", Color(0.71, 0.78, 0.84))
	story.custom_minimum_size = Vector2(360, 52)
	stack.add_child(story)

	var solo := _button("НОВАЯ ИГРА", Color(0.25, 0.83, 0.92), 19)
	solo.custom_minimum_size = Vector2(0, 54)
	solo.pressed.connect(func(): start_requested.emit("solo", ""))
	stack.add_child(solo)

	var host := _button("ИГРАТЬ ВДВОЁМ • СОЗДАТЬ КОМНАТУ", Color(0.52, 0.66, 0.99), 16)
	host.custom_minimum_size = Vector2(0, 50)
	host.pressed.connect(func(): start_requested.emit("host", ""))
	stack.add_child(host)

	var join_row := HBoxContainer.new()
	join_row.add_theme_constant_override("separation", 8)
	stack.add_child(join_row)
	address_input = LineEdit.new()
	address_input.placeholder_text = "IP хоста, например 192.168.1.20"
	address_input.text = "192.168.1.20"
	address_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	address_input.custom_minimum_size = Vector2(0, 44)
	address_input.add_theme_font_size_override("font_size", 14)
	join_row.add_child(address_input)
	var join := _button("ПОДКЛЮЧИТЬСЯ", Color(0.39, 0.77, 0.58), 14)
	join.custom_minimum_size = Vector2(150, 44)
	join.pressed.connect(func(): start_requested.emit("join", address_input.text))
	join_row.add_child(join)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 9)
	stack.add_child(actions)
	var settings := _button("НАСТРОЙКИ", Color(0.35, 0.45, 0.58), 14)
	settings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings.pressed.connect(open_settings)
	actions.add_child(settings)
	var quit := _button("ЗАКРЫТЬ", Color(0.42, 0.32, 0.37), 14)
	quit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quit.pressed.connect(func(): get_tree().quit())
	actions.add_child(quit)

	status_label = Label.new()
	status_label.text = "Одиночная игра • LAN: порт 24777/UDP"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 12)
	status_label.add_theme_color_override("font_color", Color(0.58, 0.73, 0.80))
	stack.add_child(status_label)

	var right_panel := PanelContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_style_panel(right_panel, Color(0.03, 0.07, 0.10, 0.54), Color(0.31, 0.59, 0.66, 0.48), 22)
	frame.add_child(right_panel)
	var scene_stack := VBoxContainer.new()
	scene_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	scene_stack.add_theme_constant_override("separation", 13)
	right_panel.add_child(scene_stack)

	var scene_title := Label.new()
	scene_title.text = "01  /  ПЕРВЫЙ ОБЪЕКТ"
	scene_title.add_theme_font_size_override("font_size", 18)
	scene_title.add_theme_color_override("font_color", Color(0.48, 0.88, 0.94))
	scene_stack.add_child(scene_title)
	var scene_main := Label.new()
	scene_main.text = "ЧАСТНЫЙ ДОМ"
	scene_main.add_theme_font_size_override("font_size", 32)
	scene_main.add_theme_color_override("font_color", Color(0.94, 0.97, 1.0))
	scene_stack.add_child(scene_main)
	var line := ColorRect.new()
	line.custom_minimum_size = Vector2(90, 2)
	line.color = Color(0.20, 0.78, 0.88)
	scene_stack.add_child(line)
	var feature := Label.new()
	feature.text = "ПЯТЬ ЗАДАЧ ПО УБОРКЕ\nИНВЕНТАРЬ И ПРЕДМЕТЫ\nМАШИНА С БАГАЖНИКОМ\nЛОКАЛЬНЫЙ КООПЕРАТИВ"
	feature.add_theme_font_size_override("font_size", 17)
	feature.add_theme_color_override("font_color", Color(0.80, 0.87, 0.91))
	feature.add_theme_constant_override("line_spacing", 10)
	scene_stack.add_child(feature)
	var quote := Label.new()
	quote.text = "«Главное — ничего не сломайте. И пожалуйста, не трогайте телевизор»."
	quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quote.add_theme_font_size_override("font_size", 16)
	quote.add_theme_color_override("font_color", Color(0.79, 0.85, 0.87))
	scene_stack.add_child(quote)
	var small_note := Label.new()
	small_note.text = "Виртуальные предметы, вымышленная история.\nСенсорное управление • горизонтальный режим"
	small_note.add_theme_font_size_override("font_size", 12)
	small_note.add_theme_color_override("font_color", Color(0.56, 0.67, 0.74))
	scene_stack.add_child(small_note)


func _build_hud() -> void:
	hud_layer = Control.new()
	hud_layer.name = "GameplayHUD"
	hud_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud_layer.visible = false
	add_child(hud_layer)

	var top_left := PanelContainer.new()
	top_left.anchor_left = 0.0
	top_left.anchor_top = 0.0
	top_left.anchor_right = 0.0
	top_left.anchor_bottom = 0.0
	top_left.offset_left = 20
	top_left.offset_top = 18
	top_left.offset_right = 385
	top_left.offset_bottom = 142
	_style_panel(top_left, Color(0.015, 0.035, 0.055, 0.78), Color(0.20, 0.70, 0.82, 0.55), 14)
	hud_layer.add_child(top_left)
	var left_stack := VBoxContainer.new()
	left_stack.add_theme_constant_override("separation", 4)
	top_left.add_child(left_stack)
	var title := Label.new()
	title.text = "ЗАКАЗ №001  •  ЧАСТНЫЙ ДОМ"
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color(0.58, 0.90, 0.96))
	left_stack.add_child(title)
	objective_label = Label.new()
	objective_label.text = "Убери все помещения"
	objective_label.add_theme_font_size_override("font_size", 17)
	objective_label.add_theme_color_override("font_color", Color(0.95, 0.97, 0.98))
	left_stack.add_child(objective_label)
	task_label = Label.new()
	task_label.text = "Уборка: 0 / 5"
	task_label.add_theme_font_size_override("font_size", 14)
	task_label.add_theme_color_override("font_color", Color(0.76, 0.86, 0.89))
	left_stack.add_child(task_label)
	money_label = Label.new()
	money_label.text = "Баланс: $0"
	money_label.add_theme_font_size_override("font_size", 13)
	money_label.add_theme_color_override("font_color", Color(0.52, 0.84, 0.64))
	left_stack.add_child(money_label)

	var pause := _button("Ⅱ", Color(0.25, 0.35, 0.44), 21)
	pause.anchor_left = 1.0
	pause.anchor_right = 1.0
	pause.anchor_top = 0.0
	pause.anchor_bottom = 0.0
	pause.offset_left = -78
	pause.offset_top = 20
	pause.offset_right = -20
	pause.offset_bottom = 78
	pause.pressed.connect(func(): pause_pressed.emit())
	hud_layer.add_child(pause)

	var crosshair := Label.new()
	crosshair.text = "+"
	crosshair.anchor_left = 0.5
	crosshair.anchor_right = 0.5
	crosshair.anchor_top = 0.5
	crosshair.anchor_bottom = 0.5
	crosshair.offset_left = -12
	crosshair.offset_top = -19
	crosshair.offset_right = 12
	crosshair.offset_bottom = 19
	crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crosshair.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	crosshair.add_theme_font_size_override("font_size", 26)
	crosshair.add_theme_color_override("font_color", Color(0.85, 0.97, 1.0, 0.78))
	hud_layer.add_child(crosshair)

	focus_label = Label.new()
	focus_label.anchor_left = 0.5
	focus_label.anchor_right = 0.5
	focus_label.anchor_top = 1.0
	focus_label.anchor_bottom = 1.0
	focus_label.offset_left = -270
	focus_label.offset_top = -174
	focus_label.offset_right = 270
	focus_label.offset_bottom = -142
	focus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	focus_label.add_theme_font_size_override("font_size", 16)
	focus_label.add_theme_color_override("font_color", Color(0.86, 0.96, 1.0))
	focus_label.text = "Осмотрись и найди первую задачу"
	hud_layer.add_child(focus_label)

	var joystick := Panel.new()
	joystick.anchor_left = 0.0
	joystick.anchor_right = 0.0
	joystick.anchor_top = 1.0
	joystick.anchor_bottom = 1.0
	joystick.offset_left = 38
	joystick.offset_top = -198
	joystick.offset_right = 198
	joystick.offset_bottom = -38
	joystick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var joystick_style := StyleBoxFlat.new()
	joystick_style.bg_color = Color(0.06, 0.13, 0.19, 0.42)
	joystick_style.border_color = Color(0.36, 0.75, 0.83, 0.55)
	joystick_style.set_border_width_all(2)
	joystick_style.set_corner_radius_all(82)
	joystick.add_theme_stylebox_override("panel", joystick_style)
	hud_layer.add_child(joystick)
	var joystick_text := Label.new()
	joystick_text.text = "ДВИЖЕНИЕ"
	joystick_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	joystick_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	joystick_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	joystick_text.add_theme_font_size_override("font_size", 12)
	joystick_text.add_theme_color_override("font_color", Color(0.72, 0.90, 0.95, 0.8))
	joystick_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joystick.add_child(joystick_text)

	var controls := HBoxContainer.new()
	controls.anchor_left = 1.0
	controls.anchor_right = 1.0
	controls.anchor_top = 1.0
	controls.anchor_bottom = 1.0
	controls.offset_left = -615
	controls.offset_top = -112
	controls.offset_right = -20
	controls.offset_bottom = -20
	controls.add_theme_constant_override("separation", 8)
	hud_layer.add_child(controls)

	use_button = _button("ИСПОЛЬЗОВАТЬ", Color(0.19, 0.78, 0.88), 14)
	use_button.custom_minimum_size = Vector2(154, 88)
	use_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	use_button.pressed.connect(func(): use_pressed.emit())
	controls.add_child(use_button)

	var sprint := _button("БЕГ", Color(0.57, 0.45, 0.91), 15)
	sprint.custom_minimum_size = Vector2(92, 88)
	sprint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sprint.button_down.connect(func(): sprint_changed.emit(true))
	sprint.button_up.connect(func(): sprint_changed.emit(false))
	controls.add_child(sprint)

	drop_button = _button("БРОСИТЬ", Color(0.76, 0.55, 0.28), 13)
	drop_button.custom_minimum_size = Vector2(98, 88)
	drop_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	drop_button.pressed.connect(func(): drop_pressed.emit())
	controls.add_child(drop_button)

	var inventory := _button("РЮКЗАК", Color(0.28, 0.55, 0.61), 13)
	inventory.custom_minimum_size = Vector2(92, 88)
	inventory.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory.pressed.connect(_open_inventory)
	controls.add_child(inventory)

	var phone := _button("ТЕЛЕФОН", Color(0.32, 0.43, 0.56), 13)
	phone.custom_minimum_size = Vector2(92, 88)
	phone.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	phone.pressed.connect(_toggle_phone)
	controls.add_child(phone)

	var progress_bg := ProgressBar.new()
	progress_bg.anchor_left = 0.0
	progress_bg.anchor_right = 0.0
	progress_bg.anchor_top = 0.0
	progress_bg.anchor_bottom = 0.0
	progress_bg.offset_left = 22
	progress_bg.offset_top = 152
	progress_bg.offset_right = 359
	progress_bg.offset_bottom = 163
	progress_bg.min_value = 0
	progress_bg.max_value = 5
	progress_bg.value = 0
	progress_bg.show_percentage = false
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.04, 0.08, 0.12, 0.70)
	bg_style.set_corner_radius_all(5)
	progress_bg.add_theme_stylebox_override("background", bg_style)
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color(0.25, 0.82, 0.63)
	fill_style.set_corner_radius_all(5)
	progress_bg.add_theme_stylebox_override("fill", fill_style)
	progress_bg.name = "ChoreProgress"
	hud_layer.add_child(progress_bg)

	toast_label = Label.new()
	toast_label.anchor_left = 0.5
	toast_label.anchor_right = 0.5
	toast_label.anchor_top = 0.0
	toast_label.anchor_bottom = 0.0
	toast_label.offset_left = -310
	toast_label.offset_top = 184
	toast_label.offset_right = 310
	toast_label.offset_bottom = 220
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_font_size_override("font_size", 17)
	toast_label.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0))
	toast_label.visible = false
	hud_layer.add_child(toast_label)
	toast_timer = Timer.new()
	toast_timer.one_shot = true
	toast_timer.wait_time = 2.5
	toast_timer.timeout.connect(func(): toast_label.visible = false)
	add_child(toast_timer)


func _build_dialogue() -> void:
	var root := Control.new()
	root.name = "DialogueLayer"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.visible = false
	add_child(root)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.01, 0.018, 0.03, 0.32)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(shade)
	dialogue_panel = PanelContainer.new()
	dialogue_panel.anchor_left = 0.5
	dialogue_panel.anchor_right = 0.5
	dialogue_panel.anchor_top = 1.0
	dialogue_panel.anchor_bottom = 1.0
	dialogue_panel.offset_left = -400
	dialogue_panel.offset_top = -218
	dialogue_panel.offset_right = 400
	dialogue_panel.offset_bottom = -24
	_style_panel(dialogue_panel, Color(0.025, 0.055, 0.08, 0.97), Color(0.21, 0.75, 0.84), 18)
	root.add_child(dialogue_panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	dialogue_panel.add_child(stack)
	dialogue_speaker = Label.new()
	dialogue_speaker.text = "МИХАИЛ • ЗАКАЗЧИК"
	dialogue_speaker.add_theme_font_size_override("font_size", 15)
	dialogue_speaker.add_theme_color_override("font_color", Color(0.47, 0.85, 0.93))
	stack.add_child(dialogue_speaker)
	dialogue_text = Label.new()
	dialogue_text.text = ""
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_text.custom_minimum_size = Vector2(700, 78)
	dialogue_text.add_theme_font_size_override("font_size", 18)
	dialogue_text.add_theme_color_override("font_color", Color(0.94, 0.97, 1.0))
	stack.add_child(dialogue_text)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 10)
	stack.add_child(row)
	var skip := _button("ПРОПУСТИТЬ", Color(0.30, 0.37, 0.46), 12)
	skip.custom_minimum_size = Vector2(150, 42)
	skip.pressed.connect(func(): dialogue_skipped.emit())
	row.add_child(skip)
	var next := _button("ДАЛЬШЕ  ›", Color(0.22, 0.78, 0.88), 14)
	next.custom_minimum_size = Vector2(165, 42)
	next.pressed.connect(func(): dialogue_advance.emit())
	row.add_child(next)


func _build_phone() -> void:
	phone_panel = PanelContainer.new()
	phone_panel.name = "Phone"
	phone_panel.anchor_left = 1.0
	phone_panel.anchor_right = 1.0
	phone_panel.anchor_top = 0.5
	phone_panel.anchor_bottom = 0.5
	phone_panel.offset_left = -430
	phone_panel.offset_top = -280
	phone_panel.offset_right = -22
	phone_panel.offset_bottom = 280
	phone_panel.visible = false
	_style_panel(phone_panel, Color(0.035, 0.07, 0.105, 0.98), Color(0.26, 0.76, 0.84), 24)
	add_child(phone_panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 12)
	phone_panel.add_child(stack)
	var header := HBoxContainer.new()
	stack.add_child(header)
	phone_title = Label.new()
	phone_title.text = "СЛУЖЕБНЫЙ ТЕЛЕФОН"
	phone_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	phone_title.add_theme_font_size_override("font_size", 18)
	phone_title.add_theme_color_override("font_color", Color(0.56, 0.89, 0.95))
	header.add_child(phone_title)
	var close := _button("×", Color(0.34, 0.37, 0.44), 20)
	close.custom_minimum_size = Vector2(42, 40)
	close.pressed.connect(_close_phone)
	header.add_child(close)
	phone_content = Label.new()
	phone_content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	phone_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	phone_content.add_theme_font_size_override("font_size", 15)
	phone_content.add_theme_color_override("font_color", Color(0.84, 0.90, 0.93))
	stack.add_child(phone_content)
	phone_call_button = _button("ПОЗВОНИТЬ ЗАКАЗЧИКУ", Color(0.25, 0.73, 0.57), 14)
	phone_call_button.pressed.connect(func():
		_close_phone()
		phone_call_requested.emit()
	)
	stack.add_child(phone_call_button)
	var hint := Label.new()
	hint.text = "F — открыть/закрыть телефон"
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.51, 0.67, 0.75))
	stack.add_child(hint)


func _build_pause() -> void:
	pause_panel = PanelContainer.new()
	pause_panel.name = "PauseMenu"
	pause_panel.anchor_left = 0.5
	pause_panel.anchor_right = 0.5
	pause_panel.anchor_top = 0.5
	pause_panel.anchor_bottom = 0.5
	pause_panel.offset_left = -220
	pause_panel.offset_top = -185
	pause_panel.offset_right = 220
	pause_panel.offset_bottom = 185
	pause_panel.visible = false
	_style_panel(pause_panel, Color(0.03, 0.06, 0.09, 0.98), Color(0.32, 0.70, 0.82), 20)
	add_child(pause_panel)
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 12)
	pause_panel.add_child(stack)
	var title := Label.new()
	title.text = "ПАУЗА"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.75, 0.93, 1.0))
	stack.add_child(title)
	var resume := _button("ПРОДОЛЖИТЬ", Color(0.22, 0.78, 0.88), 16)
	resume.pressed.connect(func():
		pause_panel.visible = false
		resume_pressed.emit()
	)
	stack.add_child(resume)
	var settings := _button("НАСТРОЙКИ", Color(0.33, 0.43, 0.57), 15)
	settings.pressed.connect(open_settings)
	stack.add_child(settings)
	var save := _button("СОХРАНИТЬ ПРОГРЕСС", Color(0.29, 0.61, 0.49), 14)
	save.pressed.connect(func():
		SaveManager.save_progress({"money": GameState.money, "completed_missions": GameState.completed_missions})
		show_toast("Прогресс сохранён.")
	)
	stack.add_child(save)
	var menu := _button("В ГЛАВНОЕ МЕНЮ", Color(0.46, 0.31, 0.37), 14)
	menu.pressed.connect(func():
		pause_panel.visible = false
		return_to_menu.emit()
	)
	stack.add_child(menu)


func _build_result() -> void:
	result_panel = PanelContainer.new()
	result_panel.name = "MissionResult"
	result_panel.anchor_left = 0.5
	result_panel.anchor_right = 0.5
	result_panel.anchor_top = 0.5
	result_panel.anchor_bottom = 0.5
	result_panel.offset_left = -320
	result_panel.offset_top = -220
	result_panel.offset_right = 320
	result_panel.offset_bottom = 220
	result_panel.visible = false
	_style_panel(result_panel, Color(0.025, 0.065, 0.09, 0.99), Color(0.26, 0.84, 0.67), 24)
	add_child(result_panel)
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 15)
	result_panel.add_child(stack)
	var heading := Label.new()
	heading.text = "СМЕНА ЗАВЕРШЕНА"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 28)
	heading.add_theme_color_override("font_color", Color(0.51, 0.92, 0.77))
	stack.add_child(heading)
	result_text = Label.new()
	result_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_text.add_theme_font_size_override("font_size", 18)
	result_text.add_theme_color_override("font_color", Color(0.89, 0.94, 0.96))
	stack.add_child(result_text)
	var menu := _button("В ГЛАВНОЕ МЕНЮ", Color(0.22, 0.76, 0.85), 16)
	menu.pressed.connect(func():
		result_panel.visible = false
		return_to_menu.emit()
	)
	stack.add_child(menu)


func _build_settings() -> void:
	settings_panel = PanelContainer.new()
	settings_panel.name = "Settings"
	settings_panel.anchor_left = 0.5
	settings_panel.anchor_right = 0.5
	settings_panel.anchor_top = 0.5
	settings_panel.anchor_bottom = 0.5
	settings_panel.offset_left = -280
	settings_panel.offset_top = -220
	settings_panel.offset_right = 280
	settings_panel.offset_bottom = 220
	settings_panel.visible = false
	_style_panel(settings_panel, Color(0.03, 0.06, 0.10, 0.99), Color(0.35, 0.73, 0.83), 22)
	add_child(settings_panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 11)
	settings_panel.add_child(stack)
	var title := Label.new()
	title.text = "НАСТРОЙКИ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", Color(0.72, 0.94, 1.0))
	stack.add_child(title)

	var sens_label := Label.new()
	sens_label.text = "Чувствительность камеры"
	sens_label.add_theme_color_override("font_color", Color(0.85, 0.90, 0.94))
	stack.add_child(sens_label)
	var sens := HSlider.new()
	sens.min_value = 0.0015
	sens.max_value = 0.010
	sens.step = 0.0005
	sens.value = float(SaveManager.settings.get("camera_sensitivity", 0.004))
	sens.value_changed.connect(func(value: float): settings_changed.emit("camera_sensitivity", value))
	stack.add_child(sens)

	var volume_label := Label.new()
	volume_label.text = "Общая громкость"
	volume_label.add_theme_color_override("font_color", Color(0.85, 0.90, 0.94))
	stack.add_child(volume_label)
	var volume := HSlider.new()
	volume.min_value = 0.0
	volume.max_value = 1.0
	volume.step = 0.05
	volume.value = float(SaveManager.settings.get("master_volume", 0.8))
	volume.value_changed.connect(func(value: float): settings_changed.emit("master_volume", value))
	stack.add_child(volume)

	var quality_label := Label.new()
	quality_label.text = "Качество графики"
	quality_label.add_theme_color_override("font_color", Color(0.85, 0.90, 0.94))
	stack.add_child(quality_label)
	var quality := OptionButton.new()
	quality.add_item("Низкое", 0)
	quality.add_item("Среднее", 1)
	quality.add_item("Высокое", 2)
	var quality_index := ["Low", "Medium", "High"].find(str(SaveManager.settings.get("graphics_quality", "Medium")))
	quality.select(maxi(0, quality_index))
	quality.item_selected.connect(func(index: int):
		var values := ["Low", "Medium", "High"]
		settings_changed.emit("graphics_quality", values[index])
	)
	stack.add_child(quality)

	var back := _button("ГОТОВО", Color(0.24, 0.78, 0.87), 15)
	back.pressed.connect(func(): settings_panel.visible = false)
	stack.add_child(back)


func show_menu(has_save: bool) -> void:
	menu_layer.visible = true
	hud_layer.visible = false
	phone_panel.visible = false
	dialogue_panel.get_parent().visible = false
	pause_panel.visible = false
	result_panel.visible = false
	if has_save:
		status_label.text = "%s • Баланс: $%d • Пройдено смен: %d" % [NetworkManager.status_text, GameState.money, GameState.completed_missions]
	else:
		status_label.text = NetworkManager.status_text


func begin_game() -> void:
	menu_layer.visible = false
	hud_layer.visible = true
	dialogue_panel.get_parent().visible = false
	phone_panel.visible = false
	pause_panel.visible = false
	result_panel.visible = false
	refresh_state()


func show_dialogue(speaker: String, text: String) -> void:
	var layer := dialogue_panel.get_parent() as Control
	layer.visible = true
	dialogue_panel.visible = true
	dialogue_speaker.text = speaker
	dialogue_text.text = text
	hud_layer.visible = true
	menu_layer.visible = false
	phone_panel.visible = false
	pause_panel.visible = false


func hide_dialogue() -> void:
	dialogue_panel.get_parent().visible = false


func set_focus(info: Dictionary) -> void:
	focus_info = info.duplicate(true)
	if info.is_empty():
		focus_label.text = "Осмотрись и найди отмеченные задачи"
		use_button.text = "ИСПОЛЬЗОВАТЬ"
		return
	var target_title := str(info.get("title", "Объект"))
	var action := str(info.get("action", ""))
	var hint := "ИСПОЛЬЗОВАТЬ"
	match action:
		"clean":
			hint = "УБРАТЬ"
		"pick_small":
			hint = "В РЮКЗАК"
		"carry_large":
			hint = "ВЗЯТЬ ОБЕИМИ РУКАМИ"
		"trunk":
			hint = "ЗАГРУЗИТЬ / ЗАВЕРШИТЬ"
			if GameState.carried_item_for(NetworkManager.local_actor_id()) == "":
				hint = "ЗАГРУЗИТЬ / ЗАВЕРШИТЬ"
		"door":
			hint = "ОТКРЫТЬ / ЗАКРЫТЬ"
	focus_label.text = target_title + "  •  " + hint
	use_button.text = hint


func refresh_state() -> void:
	if not is_instance_valid(objective_label):
		return
	task_label.text = "Уборка: %d / %d" % [GameState.chores.size() - GameState.remaining_chores(), GameState.chores.size()]
	money_label.text = "Баланс: $%d" % GameState.money
	var progress := hud_layer.get_node_or_null("ChoreProgress") as ProgressBar
	if progress != null:
		progress.value = GameState.chores.size() - GameState.remaining_chores()
	match GameState.phase:
		GameState.Phase.CLEANING:
			objective_label.text = "Основной этап: уборка"
		GameState.Phase.CLIENT_LEAVING:
			objective_label.text = "Заказчик уезжает…"
		GameState.Phase.LOOTING:
			objective_label.text = "Вернись к машине с находками"
		GameState.Phase.COMPLETE:
			objective_label.text = "Смена завершена"
		_:
			objective_label.text = "Первый заказ: частный дом"
	if is_instance_valid(drop_button):
		drop_button.disabled = GameState.carried_item_for(NetworkManager.local_actor_id()) == ""
	_update_phone_content()


func _toggle_phone() -> void:
	phone_panel.visible = not phone_panel.visible
	phone_title.text = "СЛУЖЕБНЫЙ ТЕЛЕФОН"
	modal_changed.emit(phone_panel.visible)
	_update_phone_content()


func _close_phone() -> void:
	phone_panel.visible = false
	phone_title.text = "СЛУЖЕБНЫЙ ТЕЛЕФОН"
	phone_call_button.visible = GameState.phase == GameState.Phase.CLEANING
	modal_changed.emit(false)


func _open_inventory() -> void:
	phone_panel.visible = true
	phone_title.text = "РЮКЗАК"
	phone_call_button.visible = false
	modal_changed.emit(true)
	_update_phone_content()


func _update_phone_content() -> void:
	if not is_instance_valid(phone_content):
		return
	if phone_title.text == "РЮКЗАК":
		var bag: Array = GameState.backpack_for(NetworkManager.local_actor_id())
		var lines := PackedStringArray(["ВМЕСТИМОСТЬ: %d / %d предметов" % [bag.size(), GameState.BACKPACK_SLOTS], "Вес: %.1f / %.1f кг" % [GameState.backpack_weight(NetworkManager.local_actor_id()), GameState.BACKPACK_MAX_WEIGHT], ""])
		for item_id in bag:
			var item: Dictionary = GameState.items.get(str(item_id), {})
			lines.append("• %s  —  $%d" % [str(item.get("title", item_id)), int(item.get("value", 0))])
		if bag.is_empty():
			lines.append("Пока пусто. Небольшие предметы можно положить сюда.")
		phone_content.text = "\n".join(lines)
		return
	phone_title.text = "СЛУЖЕБНЫЙ ТЕЛЕФОН"
	phone_call_button.visible = GameState.phase == GameState.Phase.CLEANING
	var lines := PackedStringArray(["КЛИЕНТ: МИХАИЛ", "ЗАКАЗ: УБОРКА ЧАСТНОГО ДОМА", ""])
	for chore in GameState.chores:
		var mark := "✓" if bool(chore.get("done", false)) else "○"
		lines.append("%s  %s" % [mark, str(chore.get("title", ""))])
	lines.append("")
	lines.append("Этап: " + _phase_text(GameState.phase))
	lines.append("Багажник: %d / %d предметов" % [GameState.trunk.size(), GameState.TRUNK_MAX_SLOTS])
	lines.append("Баланс: $%d" % GameState.money)
	phone_content.text = "\n".join(lines)


func _phase_text(phase: int) -> String:
	match phase:
		GameState.Phase.INTRO:
			return "Вступление"
		GameState.Phase.CLEANING:
			return "Уборка"
		GameState.Phase.CLIENT_LEAVING:
			return "Отъезд клиента"
		GameState.Phase.LOOTING:
			return "Сбор предметов и возвращение к машине"
		GameState.Phase.COMPLETE:
			return "Завершено"
		_:
			return "Главное меню"


func show_pause() -> void:
	pause_panel.visible = true
	hud_layer.visible = true
	phone_panel.visible = false


func show_result(reward: int) -> void:
	result_panel.visible = true
	hud_layer.visible = false
	dialogue_panel.get_parent().visible = false
	result_text.text = "Награда за смену: $%d\nОбщий баланс: $%d\nЗавершено заказов: %d\n\nВсе найденные предметы переданы в итоговый расчёт." % [reward, GameState.money, GameState.completed_missions]


func show_toast(text: String) -> void:
	if not is_instance_valid(toast_label):
		return
	toast_label.text = text
	toast_label.visible = true
	toast_timer.start()


func set_network_status(text: String) -> void:
	if is_instance_valid(status_label) and menu_layer.visible:
		status_label.text = text


func open_settings() -> void:
	settings_panel.visible = true


func close_overlays() -> void:
	phone_panel.visible = false
	pause_panel.visible = false
	settings_panel.visible = false
	_pin_dialogue_closed()


func _pin_dialogue_closed() -> void:
	if is_instance_valid(dialogue_panel):
		dialogue_panel.get_parent().visible = false
