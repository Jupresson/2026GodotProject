# Project Notes (Godot 4.6.x)

This file is a practical checklist for this project setup.
Keep this as the source of truth for integration and troubleshooting.

## Current addons and plugin state

- ScreenSpace Projection is present at addons/screenspace_projection.
- ScreenSpace Projection is scene based and should be instanced, not enabled as an editor plugin.
- Spatial Audio Extended is installed at addons/spatial_audio_extended and is currently enabled in project settings.
- Current enabled editor plugin: res://addons/spatial_audio_extended/plugin.cfg.

## Import and setup notes

- Blender import is currently disabled in project settings (import/blender/enabled=false).
- Main lens setup scene: addons/screenspace_projection/screenspace_projection.tscn.
- Parent world content under ScreenSpaceProjection/ProjectionInput.
- Draw UI outside ProjectionInput so UI is not lens-distorted.
- For best upscale quality, use Forward+ renderer when using FSR2.

## Lens pipeline and effect ordering

Treat projection as a lens stage in the middle of the frame pipeline.

| Before lens (inside ProjectionInput camera) | After lens (on ScreenSpaceProjection camera) |
|---------------------------------------------|-----------------------------------------------|
| SSR                                         | Film grain                                    |
| SSAO                                        | Auto exposure                                 |
| SSGI                                        | Bloom / glow                                  |
| Volumetric fog                              | Color grading / LUT                           |
| Depth of field                              | Tonemapping                                   |
| Motion blur                                 |                                               |
| Upscaling (FSR2)                            |                                               |

Notes:
- Chromatic aberration and vignette in screenspace_projection.gdshader happen inside the lens stage.
- Keep gameplay UI and debug overlays after lens output.

## Shader compatibility note

Known error:
- Unknown identifier in expression: NEED_CHECK
- set_code: Shader compilation failed

Cause:
- Older shader versions used a multiline ACCUM macro in sample_anisotropic.
- Some Godot 4.6.x environments fail macro expansion in that block.

Current fix in this repo:
- screenspace_projection.gdshader now uses explicit accumulation logic instead of multiline macros.

Why it can appear suddenly:
- Engine reinstall or minor update
- GPU driver update
- Shader cache invalidation or full reimport

## Tuning checklist

- Soft center image: increase upscale and use FSR2.
- Edge shimmer/aliasing: raise max_major_radius and max_minor_radius.
- Black corners: increase fill.
- Distorted UI: move UI out of ProjectionInput.

## Upgrade policy (recommended)

- For active production, keep the current stable engine version.
- Test engine upgrades in a duplicated project folder first.
- For Godot 4.7 testing, verify:
  - screenspace_projection.gdshader compiles cleanly
  - lens effect order still matches this README
  - player movement, collisions, and camera feel are unchanged
  - save/load and story progression still work

Only migrate the main branch after the test copy is stable.

## License

- assets folder: CC0
- addons and project code: MIT
