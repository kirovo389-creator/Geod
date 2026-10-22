extends Node3D

const WORLD_SCENE := preload("res://scenes/world/house_level.tscn")
const UI_SCENE := preload("res://scenes/ui/game_ui.tscn")

var world: Node3D
var ui: CanvasLayer
var player: CharacterBody3D
var current_dialogue: Array[Dictionary] = []
var dialogue_index := 0
var dialogue_final: Callable
var dialogue_busy := false


func _ready() -> void:
	Engine.max_fps = 60
	world = WORLD_SCENE.instantiate()
	world.name = "HouseLevel"
	add_child(world)
	ui = UI_SCENE.instantiate()
	add_child(ui)
	player = world.get_local_player()

	ui.start_requested.connect(_on_start_requested)
	ui.dialogue_advance.connect(_advance_dialogue)
	ui.dialogue_skipped.connect(_skip_dialogue)
	ui.use_pressed.connect(player.perform_primary_action)
	ui.phone_call_requested.connect(_call_customer)
	ui.sprint_changed.connect(func(held: bool): player.sprinting = held)
	ui.drop_pressed.connect(_drop_carried_item)
	ui.pause_pressed.connect(_pause_game)
	ui.resume_pressed.connect(_resume_game)
	ui.return_to_menu.connect(_return_to_menu)
	ui.settings_changed.connect(_on_setting_changed)
	ui.modal_changed.connect(_on_modal_changed)

	player.phone_requested.connect(_toggle_phone)
	player.pause_requested.connect(_pause_game)
	player.drop_requested.connect(_drop_carried_item)
	NetworkManager.status_changed.connect(ui.set_network_status)
	NetworkManager.session_ended.connect(func(reason: String): ui.show_toast(reason))
	GameState.state_changed.connect(_on_state_changed)
	GameState.phase_changed.connect(_on_phase_changed)
	GameState.toast_requested.connect(ui.show_toast)

	ui.set_network_status(NetworkManager.status_text)
	ui.show_menu(GameState.completed_missions > 0)
	player.set_control_enabled(false)
	_apply_graphics_quality(str(SaveManager.settings.get("graphics_quality", "Medium")))


func _on_start_requested(mode: String, address: String) -> void:
	if mode == "join":
		var join_error := NetworkManager.join_host(address)
		if join_error == OK:
			ui.set_network_status("Подключение… Проверь, что оба телефона в одной Wi-Fi сети.")
		return

	if mode == "host":
		var host_error := NetworkManager.create_host()
		if host_error != OK:
			ui.show_toast("Не удалось создать LAN-комнату. Проверь сеть.")
			return
	else:
		NetworkManager.close_session()

	if world.has_method("reset_world"):
		world.reset_world()
	GameState.start_new_mission()


func _on_phase_changed(old_phase: int, new_phase: int) -> void:
	match new_phase:
		GameState.Phase.MENU:
			player.set_control_enabled(false)
			ui.show_menu(GameState.completed_missions > 0)
		GameState.Phase.INTRO:
			ui.begin_game()
			player.set_control_enabled(false)
			_run_dialogue([
				{"speaker": "ТЫ • НОВЫЙ СОТРУДНИК", "text": "Первый рабочий день. Фургон старый, швабра новая, а телефон уже звонит. Ну что, поехали."},
				{"speaker": "МИХАИЛ • ЗАКАЗЧИК", "text": "Здравствуйте! Это Михаил. Я заказал уборку дома. Нужно собрать мусор, отмыть пятно возле дивана и привести кухню в порядок."},
				{"speaker": "ТЫ", "text": "Понял. Сначала выполню весь чек-лист. Подскажите, как зайти?"},
				{"speaker": "МИХАИЛ", "text": "Входная дверь прямо перед тобой. Когда закончишь, оставь всё аккуратно — мне придётся ненадолго уехать."},
				{"speaker": "ТЫ • ПОДСКАЗКА", "text": "Слева внизу — движение, свайп справа — обзор. Посмотри на дверь и нажми «Использовать», чтобы открыть её. Затем выполняй отмеченные задачи."}
			], Callable(self, "_finish_intro"))
		GameState.Phase.CLEANING:
			ui.begin_game()
			player.set_control_enabled(true)
			ui.show_toast("Начни с двери, затем выполни все 5 задач уборки.")
		GameState.Phase.CLIENT_LEAVING:
			player.set_control_enabled(false)
			_run_dialogue([
				{"speaker": "МИХАИЛ", "text": "Выглядит гораздо лучше. Спасибо! Мне срочно нужно в город, я оставлю ключи у входа."},
				{"speaker": "ТЫ", "text": "Хорошо, хорошей дороги."},
				{"speaker": "МИХАИЛ • УХОДИТ", "text": "Дверь за собой прикройте. И, пожалуйста, не оставляйте крупные вещи посреди комнаты."}
			], Callable(self, "_start_departure"))
		GameState.Phase.LOOTING:
			ui.begin_game()
			player.set_control_enabled(true)
			ui.show_toast("Хозяин уехал. Найди небольшие вещи, а крупные отнеси к фургону.")
		GameState.Phase.COMPLETE:
			player.set_control_enabled(false)
			ui.show_result(GameState.last_reward)


func _finish_intro() -> void:
	ui.hide_dialogue()
	if NetworkManager.is_authority():
		GameState.set_phase_authoritative(GameState.Phase.CLEANING)
	else:
		ui.show_toast("Ожидание состояния миссии от хоста…")


func _start_departure() -> void:
	ui.hide_dialogue()
	if world.has_method("play_owner_departure"):
		world.play_owner_departure(Callable(self, "_owner_departure_finished"))
	else:
		_owner_departure_finished()


func _owner_departure_finished() -> void:
	if NetworkManager.is_authority() and GameState.phase == GameState.Phase.CLIENT_LEAVING:
		GameState.set_phase_authoritative(GameState.Phase.LOOTING)


func _run_dialogue(lines: Array[Dictionary], callback: Callable) -> void:
	current_dialogue = lines.duplicate(true)
	dialogue_index = 0
	dialogue_final = callback
	dialogue_busy = true
	_show_dialogue_line()


func _show_dialogue_line() -> void:
	if dialogue_index < 0 or dialogue_index >= current_dialogue.size():
		_finish_dialogue()
		return
	var entry: Dictionary = current_dialogue[dialogue_index]
	ui.show_dialogue(str(entry.get("speaker", "СОБЕСЕДНИК")), str(entry.get("text", "")))


func _advance_dialogue() -> void:
	if not dialogue_busy:
		return
	dialogue_index += 1
	if dialogue_index >= current_dialogue.size():
		_finish_dialogue()
	else:
		_show_dialogue_line()


func _skip_dialogue() -> void:
	if not dialogue_busy:
		return
	dialogue_index = current_dialogue.size()
	_finish_dialogue()


func _finish_dialogue() -> void:
	if not dialogue_busy:
		return
	dialogue_busy = false
	current_dialogue.clear()
	var callback := dialogue_final
	dialogue_final = Callable()
	if callback.is_valid():
		callback.call()


func _call_customer() -> void:
	player.set_control_enabled(false)
	_run_dialogue([
		{"speaker": "МИХАИЛ • ПО ТЕЛЕФОНУ", "text": "Да, слушаю. Я забыл упомянуть: кухня особенно важна. Пожалуйста, не торопись и отмечай каждую задачу после того, как действительно её выполнил."},
		{"speaker": "ТЫ", "text": "Понял. Я проверю оставшиеся пункты и сообщу, когда закончу."}
	], Callable(self, "_finish_phone_call"))


func _finish_phone_call() -> void:
	ui.hide_dialogue()
	player.set_control_enabled(GameState.phase in [GameState.Phase.CLEANING, GameState.Phase.LOOTING])


func _toggle_phone() -> void:
	if GameState.phase not in [GameState.Phase.CLEANING, GameState.Phase.LOOTING]:
		ui.show_toast("Телефон пока недоступен.")
		return
	ui._toggle_phone()
	player.set_control_enabled(not ui.phone_panel.visible)


func _on_modal_changed(open: bool) -> void:
	if not dialogue_busy and GameState.phase in [GameState.Phase.CLEANING, GameState.Phase.LOOTING]:
		player.set_control_enabled(not open)


func _drop_carried_item() -> void:
	var item_id := GameState.carried_item_for(NetworkManager.local_actor_id())
	if item_id.is_empty():
		ui.show_toast("Ты ничего крупного не несёшь.")
		return
	NetworkManager.request_game_action("drop", item_id)


func _pause_game() -> void:
	if GameState.phase in [GameState.Phase.MENU, GameState.Phase.COMPLETE]:
		return
	player.set_control_enabled(false)
	ui.show_pause()


func _resume_game() -> void:
	player.set_control_enabled(GameState.phase in [GameState.Phase.CLEANING, GameState.Phase.LOOTING])


func _return_to_menu() -> void:
	SaveManager.save_progress({"money": GameState.money, "completed_missions": GameState.completed_missions})
	NetworkManager.close_session()
	GameState.set_phase_authoritative(GameState.Phase.MENU)
	ui.show_menu(GameState.completed_missions > 0)
	player.set_control_enabled(false)


func _on_setting_changed(key: String, value: Variant) -> void:
	SaveManager.update_setting(key, value)
	if key == "camera_sensitivity":
		player.set_sensitivity(float(value))
	elif key == "master_volume":
		var bus := AudioServer.get_bus_index("Master")
		if bus >= 0:
			AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(float(value), 0.0001)))
	elif key == "graphics_quality":
		_apply_graphics_quality(str(value))


func _apply_graphics_quality(quality: String) -> void:
	match quality:
		"Low":
			Engine.max_fps = 30
			if is_instance_valid(world):
				world.set_quality_mode("Low")
		"High":
			Engine.max_fps = 60
			if is_instance_valid(world):
				world.set_quality_mode("High")
		_:
			Engine.max_fps = 60
			if is_instance_valid(world):
				world.set_quality_mode("Medium")


func _on_state_changed() -> void:
	ui.refresh_state()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		SaveManager.save_progress({"money": GameState.money, "completed_missions": GameState.completed_missions})
		if GameState.phase in [GameState.Phase.CLEANING, GameState.Phase.LOOTING]:
			player.set_control_enabled(false)
			ui.show_pause()
