# 2026GodotProject

![Project Icon](icon.png)

A Godot 4.6 first-person prototype project built around a custom controller plugin: **UCharacterBody3D**.

The project currently runs a playable sample scene with:

- FPS-style movement (walk, sprint, crouch, jump, slide)
- Mouse look with clamped vertical rotation
- Head bob while moving
- Runtime graphics/options panel (window mode, resolution, scaling, FSR2, VSync, screen selection)
- FPS debug label
- Bodycam shader integration in the sample scene

## Project Status

> [!NOTE]
> This repository is a foundation/prototype workspace. Folder structure for content (`entities`, `scenes`, `resources`, `audio`, `graphics`, `scripts`) is prepared for expansion.

## Requirements

- Godot Engine 4.6
- Forward Plus renderer
- Windows target configured to use D3D12
- Jolt Physics enabled for 3D physics

## Quick Start

1. Open this folder in Godot.
2. Run the project.
3. The current main scene is `addons/ultimate_character/Sample/SampleScene.tscn`.

## Default Controls

- Move: `W` `A` `S` `D`
- Sprint: `Shift`
- Crouch: `Ctrl`
- Jump: `Space`
- Look: Mouse

Input actions are configured in `project.godot` as:

- `move_left`, `move_right`, `move_forward`, `move_backward`
- `action_sprint`, `action_crouch`, `action_jump`

## Using UCharacterBody3D In Your Own Scene

1. Ensure the plugin is enabled in Project Settings > Plugins.
2. Add a `UCharacterBody3D` node to your scene.
3. Configure exported movement and control settings in the Inspector.
4. Confirm your InputMap action names match the controller settings.

The custom node script is located at `addons/ultimate_character/ucharacterbody3d.gd`.

## UI Systems Included

- `ui/fps_debug.tscn`: Minimal FPS display
- `ui/options_example.tscn`: Graphics/settings menu example
- `ui/Options_Setting.gd`: Resolution, fullscreen, render scale, FSR2 presets, VSync, and screen selection logic

## Workspace Layout

```text
addons/       # Plugins (includes ultimate_character)
audio/        # Ambient, music, and SFX placeholders
autoloads/    # Global singleton scripts (currently empty scaffold)
entities/     # Gameplay entities (scaffold)
graphics/     # Materials, shaders, textures
resources/    # Shared resources (scaffold)
scenes/       # Game scenes (scaffold)
scripts/      # Game scripts (scaffold)
ui/           # Debug and options UI scenes/scripts
```

## Next Recommended Steps

1. Move from plugin sample scene to your own `scenes/` main scene.
2. Add core game entities under `entities/` and supporting logic in `scripts/`.
3. Promote shared managers (audio, save, settings) into `autoloads/` as needed.
4. Expand options persistence (save/load display settings between sessions).

## Credits

The controller implementation is based on the Ultimate First Person Controller tutorial by @Lukky:

- Part 1: https://youtu.be/xIKErMgJ1Yk
- Part 2 (optional free-look extension): https://youtu.be/WF7d21zOD0M
