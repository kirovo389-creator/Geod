# DualMind

Experimental Geode mod for Geometry Dash Android 2.2081.

## Current prototype
- Two differently parameterized approximate trajectory lines.
- Optional auto-jump toggle, disabled by default.
- Heuristic auto-jump for ordinary spike objects only.
- Android64 build and release workflow.

## Important limitations
This is an early prototype, **not a complete autonomous level solver**. The drawn paths are approximations and are not a complete collision-accurate physics simulation. Current auto-jump logic only looks for standard spike objects and can fail on speed/gravity portals, pads, orbs, slopes, moving hazards, and other game modes. Keep automation disabled until tested, and use practice mode first.

## Build
The GitHub Actions workflow builds the Android64 .geode package. Tag a release as v* to build and attach the package, or run the workflow manually with a release tag.

Install the resulting .geode in Geode's mods folder on a compatible ARM64 Android installation.
