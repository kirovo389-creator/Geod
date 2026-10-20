# DualMind — design specification

## Goal
Create a Geode mod for Geometry Dash Android 2.2081 that attempts to automate cube-mode jumps using two independent forward simulations.

## Target platform
- Geometry Dash: Android 2.2081
- Loader/SDK: Geode version and bindings compatible with that game build
- Repository: https://github.com/kirovo389-creator/Geod

## Proposed behavior
1. A primary simulator predicts the cube's movement under candidate jump timings.
2. A second simulator independently checks candidate timings and collision risk.
3. A controller chooses a candidate that both simulations consider safe and triggers the in-game jump input.
4. If no candidate is safe, the controller waits for the next decision window or reports that the current situation cannot be solved.
5. An optional debug overlay draws the two predicted trajectories and shows the chosen jump timing.
6. Automation can be toggled off and should not interfere with manual play when disabled.

## Initial scope
- First milestone: cube mode, ordinary ground, spikes and simple platforms.
- Later milestones: speed portals, gravity portals, pads/orbs, slopes, moving hazards, other game modes and level-specific edge cases.
- The mod must not claim that every level can be completed. Reliability depends on matching Android 2.2081 physics and supported object types.
- Automated runs should be clearly indicated and should avoid submitting achievements or records if the integration allows that protection.

## Architecture
- TrajectorySimulator: simulates motion for a proposed sequence of inputs.
- CandidatePlanner: evaluates candidate jump times and short action sequences.
- DualVerifier: independently checks collision predictions and rejects unsafe candidates.
- InputController: executes the selected jump at the chosen game frame.
- DebugOverlay: optional two-line trajectory visualization and current decision status.
- Settings: enable/disable automation, overlay, and diagnostic logging.

## Safety and failure handling
- Default to disabled until the player explicitly enables automation.
- Stop automation after a death, scene change, pause, or unsupported gameplay state.
- Prefer no action over a jump when the prediction is uncertain.
- Log the reason when no safe candidate is found.
- Do not promise perfect completion; deterministic frame timing, collision boxes, and unmodelled mechanics can cause failures.

## Verification plan
1. Confirm SDK and binding compatibility with Android 2.2081.
2. Build the smallest loadable Geode package for Android.
3. Verify mod load, settings, overlay toggle, and clean disable behavior.
4. Compare simulated and actual cube positions on controlled test segments.
5. Test simple spike sequences before expanding object support.
6. Produce an Android .geode artifact only after the build succeeds.

## Open technical constraint
The repository was empty at the time this specification was prepared. A buildable implementation requires a compatible Geode SDK/toolchain and Android 2.2081 bindings; these must be verified before declaring a successful build.
