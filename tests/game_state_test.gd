extends Node

var failures: Array[String] = []


func _ready() -> void:
	_check("initial phase starts at menu", GameState.phase == GameState.Phase.MENU)
	GameState.start_new_mission()
	_check("new mission enters intro", GameState.phase == GameState.Phase.INTRO)
	GameState.set_phase_authoritative(GameState.Phase.CLEANING)
	_check("clean action available during cleaning", GameState.can_apply_action("clean", "trash_living", 1))

	for chore_id in ["trash_living", "stain_living", "trash_kitchen", "wipe_counter", "dust_bedroom"]:
		_check("clean task applies: " + chore_id, GameState.perform_action("clean", chore_id, 1))
	_check("all chores trigger owner departure phase", GameState.phase == GameState.Phase.CLIENT_LEAVING)
	GameState.set_phase_authoritative(GameState.Phase.LOOTING)
	_check("large item cannot fit backpack action", not GameState.can_apply_action("pick_small", "loot_tv", 1))

	_check("watch goes in backpack", GameState.perform_action("pick_small", "loot_watch", 1))
	_check("tablet goes in backpack", GameState.perform_action("pick_small", "loot_tablet", 1))
	_check("camera goes in backpack", GameState.perform_action("pick_small", "loot_camera", 1))
	_check("vase goes in backpack", GameState.perform_action("pick_small", "loot_vase", 1))
	_check("backpack reaches four slots", GameState.backpack_for(1).size() == GameState.BACKPACK_SLOTS)
	_check("fifth item is rejected when bag is full", not GameState.can_apply_action("pick_small", "loot_wallet", 1))
	_check("capacity error is clear", GameState.action_failure_text("pick_small", "loot_wallet", 1).contains("Рюкзак заполнен"))
	_check("large item can be carried", GameState.perform_action("carry_large", "loot_tv", 1))
	_check("carried item tracked per player", GameState.carried_item_for(1) == "loot_tv")
	_check("large item cannot enter backpack", not GameState.can_apply_action("pick_small", "loot_tv", 1))
	_check("drop clears carry slot", GameState.perform_action("drop", "loot_tv", 1, Vector3(2, 0, 2)))
	var dropped_position: Vector3 = GameState.items["loot_tv"].get("world_position", Vector3.ZERO)
	_check("drop records world position", dropped_position.distance_to(Vector3(2.8, 0.54, 1.3)) < 0.01)
	_check("large item can be picked up again", GameState.perform_action("carry_large", "loot_tv", 1))
	_check("large item loads into trunk", GameState.perform_action("trunk", "car_trunk", 1))
	_check("trunk owns item exactly once", GameState.trunk.count("loot_tv") == 1 and GameState.carried_item_for(1).is_empty())
	_check("trunk can finish sale after loot is recovered", GameState.perform_action("trunk", "car_trunk", 1))
	_check("mission finishes after loading and returning", GameState.phase == GameState.Phase.COMPLETE)
	_check("reward includes bag items and television", GameState.last_reward == GameState.BASE_REWARD + 220 + 180 + 290 + 130 + 620)
	_check("backpack is cleared after payout", GameState.backpack_for(1).is_empty())
	_check("trunk is cleared after payout", GameState.trunk.is_empty())

	if failures.is_empty():
		print("GAME_STATE_TESTS_PASSED")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("GAME_STATE_TESTS_FAILED: %d" % failures.size())
		get_tree().quit(1)


func _check(description: String, condition: bool) -> void:
	if condition:
		print("PASS: " + description)
	else:
		failures.append("FAIL: " + description)
