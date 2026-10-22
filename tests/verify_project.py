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
require('run/main_scene="res://scenes/main/main.tscn"' in project, "Main scene path is incorrect.")
require("window/handheld/orientation=0" in project, "Mobile orientation must remain landscape (Godot 4.5 enum value 0).")
require("window/size/viewport_width=1280" in project and "window/size/viewport_height=720" in project, "Base viewport must be 1280x720 landscape.")
require('renderer/rendering_method.mobile="gl_compatibility"' in project, "Android Compatibility renderer is not enabled.")
for autoload_path in (
    "scripts/core/save_manager.gd",
    "scripts/core/game_state.gd",
    "scripts/network/network_manager.gd",
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
    '"clean"', '"pick_small"', '"carry_large"', '"drop"', '"trunk"',
    "BACKPACK_SLOTS", "TRUNK_MAX_WEIGHT", "make_snapshot", "apply_snapshot",
):
    require(required in state, f"Game state contract missing: {required}")

network = (ROOT / "scripts/network/network_manager.gd").read_text(encoding="utf-8")
for required in ("ENetMultiplayerPeer", "create_server", "create_client", "server_request_action", "submit_transform", "receive_snapshot"):
    require(required in network, f"Network feature is missing: {required}")

preset = (ROOT / "export_presets.cfg").read_text(encoding="utf-8")
require("permissions/internet=true" in preset, "Android export must include Internet permission for LAN UDP.")
require('package/name="How to Suck"' in preset, "Android package name must match project title.")
require('export_path="build/HowToSuck.apk"' in preset, "Android export path must point to HowToSuck.apk.")

if errors:
    print("PROJECT CONTRACT CHECK FAILED")
    for error in errors:
        print(" -", error)
    sys.exit(1)
print("Project contract checks passed.")
