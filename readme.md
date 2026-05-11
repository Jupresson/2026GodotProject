# 2026GodotProject

![Project Icon](icon.png)

A first-person backrooms 3D platformer built in Godot 4.6.2. Navigate eerie, procedurally-inspired environments with precise platforming mechanics and immersive exploration.

## Requirements

- **Godot Engine** 4.6.2
- **Renderer:** Forward Plus
- **Physics:** Jolt Physics enabled

## Getting Started

1. Open this folder in Godot Engine 4.6.2
2. Configure editor settings (see Setup Notes below)
3. Run the project with `F5` or the Play button
4. Main scene: `level_0`

## Controls

| Action | Key |
|--------|-----|
| Move Forward/Back | `W` / `S` |
| Move Left/Right | `A` / `D` |
| Sprint | `Shift` |
| Crouch | `Ctrl` |
| Jump | `Space` |
| Look Around | Mouse |

*Input actions configured in `project.godot`*

## Setup Notes

> [!IMPORTANT]
> **Disable Embedded Window Mode** before running the project for optimal performance and proper script functionality.
>
> Navigate to: **Editor Settings** → **Debug** → **GDScript** → **Disable Embedded Window Mode**

## Project Structure

- **`level_0`** - Main scene
- **Input actions:** `move_left`, `move_right`, `move_forward`, `move_backward`, `action_sprint`, `action_crouch`, `action_jump`

## Features

- First-person perspective with smooth camera controls
- Precision platforming with sprint and crouch mechanics
- Forward Plus rendering for modern 3D visuals
- Jolt Physics for reliable collision and movement