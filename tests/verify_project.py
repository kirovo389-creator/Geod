#!/usr/bin/env python3
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
errors: list[str] = []

def require(condition: bool, message: str) -> None:
    if not condition:
        errors.append(message)

project = (ROOT / "project.godot").read_text(encoding="utf-8")
require('config/name="How to Suck"' in project, "Application name must be How to Suck.")
require('config/icon="res://assets/ui/app_icon.svg"' in project, "Application icon path is not configured.")
require((ROOT / "assets/ui/app_icon.svg").is_file(), "Application icon SVG is missing.")
require('run/main_scene="res://scenes/main/main.tscn"' in project, "Main scene path is incorrect.")
require("window/handheld/orientation=0" in project, "Mobile orientation must remain landscape (Godot 4.5 enum value 0).")
require("window/size/viewport_width=1280" in project and "window/size/viewport_height=720" in project, "Base viewport must be 1280x720 landscape.")
require('renderer/rendering_method.mobile="gl_compatibility"' in project, "Android Compatibility renderer is not enabled.")
for autoload_path in (
    "scripts/core/save_manager.gd",
    "scripts/core/game_state.gd",
    "scripts/network/network_manager.gd",
    "scripts/core/audio_manager.gd",
):
    require((ROOT / autoload_path).is_file(), f"Missing autoload script: {autoload_path}")

scene_paths = re.findall(r'path="res://([^"]+)"', "\n".join(p.read_text(encoding="utf-8") for p in ROOT.rglob("*.tscn")))
for scene_path in scene_paths:
    require((ROOT / scene_path).is_file(), f"Scene references missing file: {scene_path}")

for relative in (
    "scenes/main/main.tscn",
    "scenes/world/house_level.tscn",
    "scenes/player/player.tscn",
    "scenes/ui/game_ui.tscn",
):
    require((ROOT / relative).is_file(), f"Missing required scene: {relative}")

state = (ROOT / "scripts/core/game_state.gd").read_text(encoding="utf-8")
for required in (
    '"clean"', '"pick_small"', '"carry_large"', '"drop"', '"trunk"', '"loot_wallet"',
    "BACKPACK_SLOTS", "TRUNK_MAX_WEIGHT", "make_snapshot", "apply_snapshot",
):
    require(required in state, f"Game state contract missing: {required}")

player = (ROOT / "scripts/player/player_controller.gd").read_text(encoding="utf-8")
require("func _build_view_hands" in player, "First-person hand meshes are missing.")
require("func _add_hand_digit" in player, "First-person hand finger details are missing.")
require("Vector3(-sin(yaw), 0.0, -cos(yaw))" in player, "Forward movement axis must match camera yaw.")
require("pitch - delta.y" in player and "pitch - event.relative.y" in player, "Vertical camera movement is inverted.")
require("func play_interaction_animation" in player, "Interaction animation is missing.")
require("signal stamina_changed(value: float)" in player, "Stamina HUD signal is missing.")
ui = (ROOT / "scripts/ui/game_ui.gd").read_text(encoding="utf-8")
require("ЭНЕРГИЯ РЫВКА" in ui and "func set_stamina" in ui, "Stamina HUD is not wired.")
audio = (ROOT / "scripts/core/audio_manager.gd").read_text(encoding="utf-8")
require("func play_event" in audio and "AudioStreamWAV" in audio, "Generated interaction audio is missing.")
dirt_shader_path = ROOT / "shaders/dirt_surface.gdshader"
require(dirt_shader_path.is_file(), "Dirt-cleaning shader is missing.")
dirt_shader = dirt_shader_path.read_text(encoding="utf-8")
require("uniform float clean_progress" in dirt_shader and "ALPHA" in dirt_shader, "Dirt shader must support progressive cleaning.")
require("shader_parameter/clean_progress" in (ROOT / "scripts/world/house_level.gd").read_text(encoding="utf-8"), "Cleaning progress is not animated in the world.")
require('"footstep"' in audio and '"footstep_heavy"' in audio, "Movement footstep audio events are missing.")
require("footstep_timer" in player and "AudioManager.play_event" in player, "Footsteps are not connected to player movement.")

network = (ROOT / "scripts/network/network_manager.gd").read_text(encoding="utf-8")
for required in ("ENetMultiplayerPeer", "create_server", "create_client", "server_request_action", "submit_transform", "receive_snapshot", "if last_positions.has(sender)"):
    require(required in network, f"Network feature is missing: {required}")

world = (ROOT / "scripts/world/house_level.gd").read_text(encoding="utf-8")
require("func animate_trunk" in world and "AnimatedTrunkLid" in world, "Animated trunk lid is missing.")


interactables_path = ROOT / "scenes/world/house_interactables.tscn"
environment_path = ROOT / "scenes/world/house_environment.tscn"
require(interactables_path.is_file(), "Editable interactables scene is missing.")
require(environment_path.is_file(), "Editable map scene is missing.")
interactable_scene = interactables_path.read_text(encoding="utf-8")
for object_id in ("door_front", "trash_living", "stain_living", "loot_watch", "loot_tablet", "loot_camera", "loot_vase", "loot_wallet", "loot_tv", "loot_speaker", "car_trunk"):
    require(f'metadata/target_id = "{object_id}"' in interactable_scene, f"Editable interactable missing: {object_id}")
require("RigidBody3D" in interactable_scene and "Mesh_VaseBody" in interactable_scene and "Mesh_CameraLens" in interactable_scene, "Physics props need item-specific meshes.")
environment_scene = environment_path.read_text(encoding="utf-8")
for required in ('name="CleanerVan"', 'name="ClientSedan"', 'name="ClientMikhail"', 'name="AnimatedTrunkLid"'):
    require(required in environment_scene, f"Scene-authored map detail missing: {required}")
require("res://shaders/rough_surface.gdshader" in environment_scene, "Rough material shader is not wired.")
world = (ROOT / "scripts/world/house_level.gd").read_text(encoding="utf-8")
require("func _build_shell" not in world and "func _build_furniture" not in world and "func _build_car" not in world, "Map/vehicle geometry must not be generated by GDScript.")
require("HOUSE_ENVIRONMENT.instantiate()" in world and "HOUSE_INTERACTABLES.instantiate()" in world, "Separate editable map scenes are not loaded.")
require("cargo_visual := source_visual.duplicate()" in world, "Van cargo should display the selected item model.")

preset = (ROOT / "export_presets.cfg").read_text(encoding="utf-8")
require("permissions/internet=true" in preset, "Android export must include Internet permission for LAN UDP.")
require('AudioManager="*res://scripts/core/audio_manager.gd"' in project, "AudioManager autoload is missing.")
require("window/handheld/orientation=0" in project, "Android orientation must be landscape.")
require('package/name="How to Suck"' in preset, "Android package name must match project title.")
require('export_path="build/HowToSuck.apk"' in preset, "Android export path must point to HowToSuck.apk.")

if errors:
    print("PROJECT CONTRACT CHECK FAILED")
    for error in errors:
        print(" -", error)
    sys.exit(1)
print("Project contract checks passed.")
