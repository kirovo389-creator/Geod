# Как поддерживать карту

Постоянные объекты уровня находятся в двух сценах Godot, а не создаются циклами в GDScript.

## Карта
Открой scenes/world/house_environment.tscn. В ней находятся StaticBody3D и MeshInstance3D. Чтобы передвинуть стол, стену, парковку, окно, фургон, седан или NPC, выдели узел и меняй Transform/ресурс Mesh в Inspector. Коллайдеры архитектуры находятся дочерними CollisionShape3D.

Материалы:
- Mat_Wood, Mat_Plaster, Mat_Concrete и Mat_Grass используют shaders/rough_surface.gdshader.
- Параметры base_color, roughness, noise_scale, wear_strength и grain_strength доступны в ShaderMaterial.
- MSAA регулируется в project.godot; не повышай его выше 2x без проверки производительности на Android.

## Интерактивные объекты
Открой scenes/world/house_interactables.tscn. Каждый target должен быть в группе interactable и иметь metadata:
- target_id — уникальный ID без пробелов.
- title — подсказка интерфейса.
- action — поддерживаемый контракт: clean, door, pick_small, carry_large или trunk.

Для физических вещей нужны RigidBody3D, CollisionShape3D, масса и PhysicsMaterial. Коллайдер должен повторять приблизительную форму предмета, не быть огромным кубом.

Чтобы добавить ценность:
1. Создай RigidBody3D, модельные MeshInstance3D и CollisionShape3D в house_interactables.tscn.
2. Установи metadata target_id, title, action.
3. Добавь ID в ITEM_CATALOG в scripts/core/game_state.gd с title, kind, value и weight.
4. Добавь тест для рюкзака/сбора в tests/game_state_test.gd и запусти CI.

## Логика
Не добавляй новые стены и мебель в scripts/world/house_level.gd. Этот скрипт только связывает сцены, свет, физику, синхронизацию и события. Видимые подсказки берутся из metadata, поэтому их текст можно менять прямо в сцене, а ID обязан совпадать с GameState.
