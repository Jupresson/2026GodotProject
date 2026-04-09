# 2026 Godot Project

![Project icon](icon.png)

A Godot 4.6.2 3D prototype focused on stylized lens projection, spatial acoustics, and fast FPS-style iteration.
This README covers how the rendering pipeline is organized, how addons are wired, and what to check when things break.

## Overview

This project combines:

- Lens-style projection with controlled effect ordering via ScreenSpace Projection.
- Extended acoustic behavior in 3D space using Spatial Audio Extended.
- A modular scene and script layout designed for rapid gameplay prototyping.

## Project Structure (Compact)

```text
.
|- addons/
|  |- screenspace_projection/
|  \- spatial_audio_extended/
|- assets/
|- materials/
|- scenes/
|  |- levels/
|  |- ui/
|  \- main.tscn
|- code/
|- scripts/
|  |- base_classes/
|  |- controllers/
|  \- ui/
\- project.godot
```

Key locations:

- Main entry scene and composition: scenes/main.tscn
- Lens setup scene: addons/screenspace_projection/screenspace_projection.tscn
- Gameplay code and controllers: code/ and scripts/controllers/

## Tech and Runtime

- Engine: Godot 4.6.2
- Renderer target: Forward+ (recommended when using FSR2)
- Blender import setting: import/blender/enabled=false

## Addons and Plugin State

- ScreenSpace Projection: addons/screenspace_projection
- ScreenSpace Projection usage: scene-based (instance in scenes, do not enable as an editor plugin)
- Spatial Audio Extended: addons/spatial_audio_extended
- Enabled editor plugin: res://addons/spatial_audio_extended/plugin.cfg

## Core Scene Integration

- Lens setup scene: addons/screenspace_projection/screenspace_projection.tscn
- Parent world content under: ScreenSpaceProjection/ProjectionInput
- Keep gameplay UI and debug overlays outside ProjectionInput to avoid lens distortion

> [!TIP]
> If HUD or debug labels appear warped, they are likely rendered inside ProjectionInput.

## Lens Pipeline Order

Treat ScreenSpace Projection as a lens stage in the middle of your frame pipeline.

| Before lens (inside ProjectionInput camera) | After lens (on ScreenSpaceProjection camera) |
|---------------------------------------------|-----------------------------------------------|
| SSR                                         | Film grain                                    |
| SSAO                                        | Auto exposure                                 |
| SSGI                                        | Bloom / glow                                  |
| Volumetric fog                              | Color grading / LUT                           |
| Depth of field                              | Tonemapping                                   |
| Motion blur                                 |                                               |
| Upscaling (FSR2)                            |                                               |

Additional notes:

- Chromatic aberration and vignette in screenspace_projection.gdshader run inside the lens stage.
- Keep UI composition after lens output.

## Shader Compatibility and Known Error

Observed error:

- Unknown identifier in expression: NEED_CHECK
- set_code: Shader compilation failed

Root cause:

- Older shader revisions used a multiline ACCUM macro in sample_anisotropic.
- Some Godot 4.6.x setups fail macro expansion for this block.

Current repo fix:

- screenspace_projection.gdshader uses explicit accumulation logic instead of multiline macros.

Why this may appear again:

- Engine reinstall or minor update
- GPU driver update
- Shader cache invalidation / full reimport

> [!WARNING]
> If this error returns, compare local shader changes against repository version before editing project rendering settings.

## Visual Tuning Checklist

- Soft center image: increase upscale and use FSR2
- Edge shimmer/aliasing: raise max_major_radius and max_minor_radius
- Black corners: increase fill
- Distorted UI: move UI out of ProjectionInput

## Recommended Upgrade Workflow

For active production:

- Stay on the current stable engine version.
- Test engine upgrades in a duplicated project folder first.

For Godot 4.7 validation, verify all of the following:

- screenspace_projection.gdshader compiles cleanly
- Lens effect ordering still matches this README
- Player movement, collisions, and camera feel are unchanged
- Save/load and story progression remain stable

Migrate the main branch only after the test copy is fully stable.
