extends Node

signal state_changed
signal phase_changed(old_phase: int, new_phase: int)
signal toast_requested(text: String)

enum Phase { MENU, INTRO, CLEANING, CLIENT_LEAVING, LOOTING, COMPLETE }

const BACKPACK_SLOTS := 4
const BACKPACK_MAX_WEIGHT := 8.0
const TRUNK_MAX_WEIGHT := 100.0
const TRUNK_MAX_SLOTS := 3
const BASE_REWARD := 350

var phase: int = Phase.MENU
var chores: Array[Dictionary] = []
var items: Dictionary = {}
var backpacks: Dictionary = {}
var carry_by_peer: Dictionary = {}
var trunk: Array[String] = []
var doors: Dictionary = {"door_front": false}
var money: int = 0
var completed_missions: int = 0
var last_reward: int = 0

const ITEM_CATALOG := {
	"loot_watch": {"title": "Наручные часы", "kind": "small", "value": 220, "weight": 0.25},
	"loot_tablet": {"title": "Планшет", "kind": "small", "value": 180, "weight": 0.65},
	"loot_camera": {"title": "Фотоаппарат", "kind": "medium", "value": 290, "weight": 1.8},
	"loot_vase": {"title": "Декоративная ваза", "kind": "medium", "value": 130, "weight": 2.6},
	"loot_wallet": {"title": "Кошелёк с мелочью", "kind": "small", "value": 80, "weight": 0.18},
	"loot_tv": {"title": "Большой телевизор", "kind": "large", "value": 620, "weight": 18.0},
	"loot_speaker": {"title": "Напольная колонка", "kind": "large", "value": 380, "weight": 12.0}
}


func _ready() -> void:
	var progress := SaveManager.load_progress()
	money = int(progress.get("money", 0))
	completed_missions = int(progress.get("completed_missions", 0))


func start_new_mission() -> void:
	chores = [
		{"id": "trash_living", "title": "Собрать мусор в гостиной", "done": false},
		{"id": "stain_living", "title": "Отмыть пятно у дивана", "done": false},
		{"id": "trash_kitchen", "title": "Собрать мусор на кухне", "done": false},
		{"id": "wipe_counter", "title": "Очистить кухонную столешницу", "done": false},
		{"id": "dust_bedroom", "title": "Убрать пыль в спальне", "done": false}
	]
	items.clear()
	for item_id in ITEM_CATALOG:
		items[item_id] = ITEM_CATALOG[item_id].duplicate(true)
		items[item_id]["id"] = item_id
		items[item_id]["state"] = "world"
		items[item_id]["owner_id"] = 0
	backpacks = {"1": []}
	carry_by_peer.clear()
	trunk.clear()
	doors = {"door_front": false}
	last_reward = 0
	_set_phase(Phase.INTRO)
	state_changed.emit()


func _set_phase(next_phase: int) -> void:
	if phase == next_phase:
		state_changed.emit()
		return
	var previous := phase
	phase = next_phase
	state_changed.emit()
	phase_changed.emit(previous, phase)


func set_phase_authoritative(next_phase: int) -> void:
	if NetworkManager.is_authority():
		_set_phase(next_phase)


func is_clean_task_done(task_id: String) -> bool:
	for chore in chores:
		if str(chore.get("id", "")) == task_id:
			return bool(chore.get("done", false))
	return false


func remaining_chores() -> int:
	var remaining := 0
	for chore in chores:
		if not bool(chore.get("done", false)):
			remaining += 1
	return remaining


func backpack_for(actor_id: int) -> Array:
	var key := str(actor_id)
	if not backpacks.has(key):
		backpacks[key] = []
	return backpacks[key]


func carried_item_for(actor_id: int) -> String:
	return str(carry_by_peer.get(str(actor_id), ""))


func item_value(item_id: String) -> int:
	var item: Dictionary = items.get(item_id, {})
	return int(item.get("value", 0))


func backpack_weight(actor_id: int) -> float:
	var weight := 0.0
	for item_id in backpack_for(actor_id):
		weight += float(items.get(str(item_id), {}).get("weight", 0.0))
	return weight


func trunk_weight() -> float:
	var weight := 0.0
	for item_id in trunk:
		weight += float(items.get(item_id, {}).get("weight", 0.0))
	return weight


func has_any_loot() -> bool:
	for actor_key in backpacks:
		if not (backpacks[actor_key] as Array).is_empty():
			return true
	return not trunk.is_empty()


func can_apply_action(action: String, target_id: String, actor_id: int) -> bool:
	match action:
		"clean":
			return phase == Phase.CLEANING and not is_clean_task_done(target_id) and _has_chore(target_id)
		"pick_small":
			if phase != Phase.LOOTING or not items.has(target_id):
				return false
			var item: Dictionary = items[target_id]
			return str(item.get("state", "")) == "world" and str(item.get("kind", "")) in ["small", "medium"] and _backpack_has_room(actor_id, target_id)
		"carry_large":
			if phase != Phase.LOOTING or not items.has(target_id) or carried_item_for(actor_id) != "":
				return false
			var item: Dictionary = items[target_id]
			return str(item.get("state", "")) == "world" and str(item.get("kind", "")) == "large"
		"drop":
			return phase == Phase.LOOTING and carried_item_for(actor_id) == target_id and items.has(target_id)
		"trunk":
			if phase != Phase.LOOTING:
				return false
			if carried_item_for(actor_id) != "":
				var carried: Dictionary = items.get(carried_item_for(actor_id), {})
				return trunk.size() < TRUNK_MAX_SLOTS and trunk_weight() + float(carried.get("weight", 0.0)) <= TRUNK_MAX_WEIGHT
			return has_any_loot()
		"door":
			return phase in [Phase.CLEANING, Phase.LOOTING] and target_id == "door_front"
		_:
			return false


func _has_chore(task_id: String) -> bool:
	for chore in chores:
		if str(chore.get("id", "")) == task_id:
			return true
	return false


func _backpack_has_room(actor_id: int, target_id: String) -> bool:
	var bag := backpack_for(actor_id)
	var item: Dictionary = items.get(target_id, {})
	return bag.size() < BACKPACK_SLOTS and backpack_weight(actor_id) + float(item.get("weight", 0.0)) <= BACKPACK_MAX_WEIGHT


func perform_action(action: String, target_id: String, actor_id: int, actor_position: Vector3 = Vector3.ZERO) -> bool:
	if not can_apply_action(action, target_id, actor_id):
		toast_requested.emit(action_failure_text(action, target_id, actor_id))
		return false

	match action:
		"clean":
			for index in range(chores.size()):
				if str(chores[index].get("id", "")) == target_id:
					chores[index]["done"] = true
					toast_requested.emit("Задача выполнена: " + str(chores[index].get("title", "")))
					break
			if remaining_chores() == 0:
				_set_phase(Phase.CLIENT_LEAVING)
			else:
				state_changed.emit()
		"pick_small":
			var bag := backpack_for(actor_id)
			bag.append(target_id)
			items[target_id]["state"] = "backpack"
			items[target_id]["owner_id"] = actor_id
			toast_requested.emit("В рюкзак: " + str(items[target_id].get("title", target_id)))
			state_changed.emit()
		"carry_large":
			carry_by_peer[str(actor_id)] = target_id
			items[target_id]["state"] = "carried"
			items[target_id]["owner_id"] = actor_id
			toast_requested.emit("Взято: " + str(items[target_id].get("title", target_id)) + ". Донеси до машины.")
			state_changed.emit()
		"drop":
			carry_by_peer.erase(str(actor_id))
			items[target_id]["state"] = "world"
			items[target_id]["owner_id"] = 0
			var drop_height := 0.70 if target_id == "loot_speaker" else 0.54
			items[target_id]["world_position"] = actor_position + Vector3(0.8, drop_height, -0.7)
			toast_requested.emit("Предмет оставлен на полу.")
			state_changed.emit()
		"trunk":
			var carried_id := carried_item_for(actor_id)
			if carried_id != "":
				carry_by_peer.erase(str(actor_id))
				items[carried_id]["state"] = "trunk"
				items[carried_id]["owner_id"] = 0
				trunk.append(carried_id)
				toast_requested.emit("Загружено в багажник: " + str(items[carried_id].get("title", carried_id)))
				state_changed.emit()
			else:
				_finish_mission()
		"door":
			doors[target_id] = not bool(doors.get(target_id, false))
			toast_requested.emit("Дверь открыта." if bool(doors[target_id]) else "Дверь закрыта.")
			state_changed.emit()
	return true


func action_failure_text(action: String, target_id: String, actor_id: int) -> String:
	if action == "pick_small":
		if backpack_for(actor_id).size() >= BACKPACK_SLOTS:
			return "Рюкзак заполнен. Оставь место для других вещей."
		return "Этот предмет нельзя положить в рюкзак или сейчас нельзя его взять."
	if action == "carry_large":
		if carried_item_for(actor_id) != "":
			return "Сначала отнеси текущую вещь к машине или положи её."
		return "Сейчас этот предмет нельзя поднять."
	if action == "trunk":
		if carried_item_for(actor_id) != "" and trunk.size() >= TRUNK_MAX_SLOTS:
			return "В багажнике больше нет места."
		return "Для завершения заказа сначала найди хотя бы одну вещь."
	if action == "clean":
		return "Эту задачу уже выполнили или сейчас уборка недоступна."
	return "Сейчас это действие недоступно."


func _finish_mission() -> void:
	var recovered := 0
	for actor_key in backpacks:
		for item_id in backpacks[actor_key]:
			recovered += item_value(str(item_id))
	for item_id in trunk:
		recovered += item_value(item_id)
	if recovered <= 0:
		toast_requested.emit("Сначала найди ценности и загрузи крупные предметы.")
		return
	last_reward = BASE_REWARD + recovered
	money += last_reward
	completed_missions += 1
	for item_id in items.keys():
		if str(items[item_id].get("state", "")) in ["backpack", "trunk"]:
			items[item_id]["state"] = "sold"
	for actor_key in backpacks.keys():
		backpacks[actor_key] = []
	trunk.clear()
	carry_by_peer.clear()
	SaveManager.save_progress({"money": money, "completed_missions": completed_missions})
	_set_phase(Phase.COMPLETE)


func make_snapshot() -> Dictionary:
	return {
		"phase": phase,
		"chores": chores.duplicate(true),
		"items": items.duplicate(true),
		"backpacks": backpacks.duplicate(true),
		"carry_by_peer": carry_by_peer.duplicate(true),
		"trunk": trunk.duplicate(),
		"doors": doors.duplicate(true),
		"money": money,
		"completed_missions": completed_missions,
		"last_reward": last_reward
	}


func apply_snapshot(snapshot: Dictionary) -> void:
	var previous := phase
	phase = int(snapshot.get("phase", phase))
	var incoming_chores: Variant = snapshot.get("chores", chores)
	if incoming_chores is Array:
		chores.clear()
		for entry in incoming_chores:
			if entry is Dictionary:
				chores.append(entry.duplicate(true))
	var incoming_items: Variant = snapshot.get("items", items)
	if incoming_items is Dictionary:
		items = incoming_items.duplicate(true)
	var incoming_bags: Variant = snapshot.get("backpacks", backpacks)
	if incoming_bags is Dictionary:
		backpacks = incoming_bags.duplicate(true)
	var incoming_carry: Variant = snapshot.get("carry_by_peer", carry_by_peer)
	if incoming_carry is Dictionary:
		carry_by_peer = incoming_carry.duplicate(true)
	var incoming_trunk: Variant = snapshot.get("trunk", trunk)
	if incoming_trunk is Array:
		trunk.clear()
		for entry in incoming_trunk:
			trunk.append(str(entry))
	var incoming_doors: Variant = snapshot.get("doors", doors)
	if incoming_doors is Dictionary:
		doors = incoming_doors.duplicate(true)
	money = int(snapshot.get("money", money))
	completed_missions = int(snapshot.get("completed_missions", completed_missions))
	last_reward = int(snapshot.get("last_reward", last_reward))
	state_changed.emit()
	if previous != phase:
		phase_changed.emit(previous, phase)
