# My GitHub Copilot Skills Setup Guide (Godot 4+ Game Dev)

A practical setup for Godot 4+ development and documentation.

## Installation Flags
- **`-g`** — Global installation (available across all projects)
- **`-y`** — Auto-accept prompts during installation

---

## 1) Core Skill Discovery

### [Find Skills](https://github.com/vercel-labs/skills/tree/main/skills/find-skills)
Discover and install new agent skills from your editor.

```bash
npx skills add https://github.com/vercel-labs/skills --skill find-skills -g -y
```

**Use when:** You need a skill for a specific task (testing, docs, workflow, refactor, etc.).

---

## 2) Godot 4+ Development Skills

### [Godot Master](https://github.com/thedivergentai/gd-agentic-skills)
```bash
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-master -g -y
```

### [Godot Best Practices](https://github.com/jwynia/agent-skills)
```bash
npx skills add https://github.com/jwynia/agent-skills --skill godot-best-practices -g -y
```

### [Godot Testing Patterns](https://github.com/thedivergentai/gd-agentic-skills)
```bash
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-testing-patterns -g -y
```

### [Godot Composition Patterns](https://github.com/thedivergentai/gd-agentic-skills)
```bash
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-composition -g -y
```

### [Godot Project Templates](https://github.com/thedivergentai/gd-agentic-skills)
```bash
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-project-templates -g -y
```

---

## 3) Documentation & README

### [Create README](https://github.com/github/awesome-copilot/tree/main/README.md)
Generate and maintain `README.md` with good structure and clarity.

```bash
npx skills add https://github.com/github/awesome-copilot --skill create-readme -g -y
```

**Use for:**
- New project documentation
- Setup/install instructions
- Feature and roadmap sections
- Consistent formatting

---

## 4) 3D Platformer Specific Skills

These skills are selected specifically for a **Godot 4 3D platformer** (CharacterBody3D, Jolt physics, 3rd-person camera, level design, animation trees, etc.).

---

### [Godot Master](https://github.com/thedivergentai/gd-agentic-skills) — 3D Platformer Mode

The `godot-master` skill is the most important one for your project. Once installed, prompt it with 3D platformer context to get precise, relevant code.

```bash
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-master -g -y
```

**Example prompts to use after installing:**

```
@godot-master Create a CharacterBody3D 3D platformer controller with coyote time, jump buffering, and variable jump height using Godot 4 and Jolt physics.
```

```
@godot-master Set up an AnimationTree with a BlendSpace2D for idle/walk/run/jump/fall states on a 3D platformer character.
```

```
@godot-master Build a 3rd-person spring-arm camera for a 3D platformer that avoids clipping into walls and has smoothed rotation.
```

```
@godot-master Implement a coyote time + jump buffer system for a CharacterBody3D that uses move_and_slide().
```

---

### [Godot Composition Patterns](https://github.com/thedivergentai/gd-agentic-skills)

Keeps your 3D platformer code modular — separate movement, camera, state machine, and ability logic into composable components instead of one huge player script.

```bash
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-composition -g -y
```

**Use for:**
- Splitting jump, dash, wall-run into individual `Component` nodes
- Reusable ability scripts attached as children of the player
- Clean separation between input handling and physics logic

**Example prompt:**

```
@godot-composition Refactor my 3D platformer player script into separate movement, jump, and dash components using composition in Godot 4.
```

---

### [Godot Project Templates](https://github.com/thedivergentai/gd-agentic-skills)

Generates a ready-to-expand 3D platformer scene structure — player, level, enemies, collectibles, and autoloads — so you don't start from a blank folder.

```bash
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-project-templates -g -y
```

**Use for:**
- Scaffolding `entities/player/`, `entities/enemies/`, `scenes/levels/`
- Setting up a `GameManager` autoload for game state
- Creating a base `Level.tscn` with environment, lighting, and spawn points

**Example prompt:**

```
@godot-project-templates Generate a 3D platformer project scaffold with a player scene, a base level scene, a collectible item, and a GameManager autoload.
```

---

### [Godot Best Practices](https://github.com/jwynia/agent-skills)

Applies Godot 4 GDScript best practices to your platformer code — signals over direct calls, typed variables, `@export` configuration, and clean scene trees.

```bash
npx skills add https://github.com/jwynia/agent-skills --skill godot-best-practices -g -y
```

**Use for:**
- Auditing player/enemy scripts for anti-patterns
- Converting `get_node()` paths to `@onready` typed vars
- Ensuring physics code runs in `_physics_process()`, not `_process()`

**Example prompt:**

```
@godot-best-practices Review my CharacterBody3D player script and fix any anti-patterns for Godot 4 typed GDScript.
```

---

### [Godot Testing Patterns](https://github.com/thedivergentai/gd-agentic-skills)

Adds unit and integration tests for your platformer logic — ground detection, jump state transitions, collectible pickup, enemy patrol — using GUT or gdUnit4.

```bash
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-testing-patterns -g -y
```

**Use for:**
- Testing that `is_on_floor()` state transitions are correct
- Writing tests for collectible scoring logic
- Validating jump/fall FSM state machine transitions

**Example prompt:**

```
@godot-testing-patterns Write GUT tests for a 3D platformer state machine that covers idle, running, jumping, and falling states.
```

---

### Skill Chaining Example (3D Platformer Full Setup)

Use multiple skills together in a single session:

```
1. @godot-project-templates  → scaffold scenes/entities/autoloads
2. @godot-master             → generate CharacterBody3D controller + AnimationTree
3. @godot-composition        → split player script into component nodes
4. @godot-best-practices     → audit and clean up all scripts
5. @godot-testing-patterns   → add tests for FSM and physics logic
```

---

## 5) Full Install — Core Skills (Copy/Paste)

```bash
# Discovery
npx skills add https://github.com/vercel-labs/skills --skill find-skills -g -y

# Godot (general)
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-master -g -y
npx skills add https://github.com/jwynia/agent-skills --skill godot-best-practices -g -y
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-testing-patterns -g -y
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-composition -g -y
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-project-templates -g -y

# Docs
npx skills add https://github.com/github/awesome-copilot --skill create-readme -g -y
```

---

## 6) Skill Management

```bash
# List installed skills
npx skills list

# Remove skill
npx skills remove <skill-name> -g

# Update skills
npx skills update -g
```

---

## 7) Micro Skills — Core Gameplay Systems

These are focused, single-purpose skills for specific Godot 4 systems. Install only what you need.

### [Godot Ability System](https://github.com/thedivergentai/gd-agentic-skills)
Build modular character abilities: dash, double jump, wall run, glide, grapple hook.

```bash
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-ability-system -g -y
```

**Example prompt:**
```
@godot-ability-system Add a double jump and air dash ability to my CharacterBody3D that integrates with my existing state machine.
```

---

### [Godot State Machine Advanced](https://github.com/thedivergentai/gd-agentic-skills)
Advanced hierarchical and pushdown FSMs for player and enemy AI.

```bash
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-state-machine-advanced -g -y
```

**Example prompt:**
```
@godot-state-machine-advanced Build a hierarchical state machine for my FPS player with idle, move, sprint, crouch, jump, fall, and slide states.
```

---

### [Godot Camera Systems](https://github.com/thedivergentai/gd-agentic-skills)
3rd-person spring arm cameras, 1st-person look, camera shake, and cinematic transitions.

```bash
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-camera-systems -g -y
```

**Example prompt:**
```
@godot-camera-systems Add camera shake on landing and on taking damage to my FPS camera rig.
```

---

### [Godot Input Handling](https://github.com/thedivergentai/gd-agentic-skills)
Input remapping, buffered input, multi-device support (keyboard, gamepad, touch).

```bash
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-input-handling -g -y
```

**Example prompt:**
```
@godot-input-handling Add runtime key remapping and gamepad support to my Godot 4 FPS project with persistent settings.
```

---

### [Godot Audio Systems](https://github.com/thedivergentai/gd-agentic-skills)
Spatial audio, music transitions, dynamic SFX pools, and footstep systems.

```bash
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-audio-systems -g -y
```

**Example prompt:**
```
@godot-audio-systems Create a pooled AudioStreamPlayer3D footstep system that plays different sounds based on the surface material my player is standing on.
```

---

### [Godot Save Load Systems](https://github.com/thedivergentai/gd-agentic-skills)
Save/load game state with JSON or binary serialization, multiple save slots, autoload integration.

```bash
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-save-load-systems -g -y
```

**Example prompt:**
```
@godot-save-load-systems Implement a save/load system for my 3D platformer that persists player position, collected items, and settings across sessions.
```

---

### [Godot Scene Management](https://github.com/thedivergentai/gd-agentic-skills)
Scene transitions, async loading, loading screens, and scene pooling.

```bash
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-scene-management -g -y
```

**Example prompt:**
```
@godot-scene-management Add an async scene loader with a fade-to-black transition and a loading progress bar between levels.
```

---

### [Godot Signal Architecture](https://github.com/thedivergentai/gd-agentic-skills)
Event bus patterns, typed signals, decoupled signal routing across autoloads.

```bash
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-signal-architecture -g -y
```

**Example prompt:**
```
@godot-signal-architecture Refactor my player health and enemy death code to use a global EventBus autoload with typed signals.
```

---

### [Godot Autoload Architecture](https://github.com/thedivergentai/gd-agentic-skills)
Singleton autoload patterns for GameManager, AudioManager, SaveManager, and more.

```bash
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-autoload-architecture -g -y
```

**Example prompt:**
```
@godot-autoload-architecture Set up a GameManager autoload that tracks game state (playing, paused, game over) and broadcasts state changes via signals.
```

---

### [Godot Combat System](https://github.com/thedivergentai/gd-agentic-skills)
Hitboxes, hurtboxes, damage types, invincibility frames, and knockback.

```bash
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-combat-system -g -y
```

**Example prompt:**
```
@godot-combat-system Add a melee attack to my CharacterBody3D with a hitbox Area3D, damage numbers, and 0.5s invincibility frames on hit.
```

---

### [Godot Navigation Pathfinding](https://github.com/thedivergentai/gd-agentic-skills)
NavigationAgent3D, NavMesh baking, dynamic obstacles, and patrol/chase AI.

```bash
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-navigation-pathfinding -g -y
```

**Example prompt:**
```
@godot-navigation-pathfinding Create an enemy that patrols waypoints and switches to chasing the player when within 10 units using NavigationAgent3D.
```

---

### [Godot Raycasting Queries](https://github.com/thedivergentai/gd-agentic-skills)
Raycasts and ShapeCasts for weapons, interaction, line-of-sight checks, and ground detection.

```bash
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-raycasting-queries -g -y
```

**Example prompt:**
```
@godot-raycasting-queries Implement a hitscan weapon using a raycast from the camera center that detects enemies and environment, with debug visualisation.
```

---

## 8) Micro Skills — Visual, FX & Performance

### [Godot 3D Lighting](https://github.com/thedivergentai/gd-agentic-skills)
DirectionalLight3D, OmniLight3D, SpotLight3D, shadow settings, and baked lightmaps.

```bash
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-3d-lighting -g -y
```

---

### [Godot 3D Materials](https://github.com/thedivergentai/gd-agentic-skills)
PBR StandardMaterial3D, ORMMaterial3D, texture atlases, and material overrides.

```bash
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-3d-materials -g -y
```

---

### [Godot Particles](https://github.com/thedivergentai/gd-agentic-skills)
GPUParticles3D, particle sub-emitters, impact FX, and footstep dust.

```bash
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-particles -g -y
```

**Example prompt:**
```
@godot-particles Create a landing dust GPUParticles3D effect that triggers when my player hits the ground after a jump.
```

---

### [Godot Shaders Basics](https://github.com/thedivergentai/gd-agentic-skills)
Shader Language fundamentals: vertex, fragment, and canvas_item shaders for Godot 4.

```bash
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-shaders-basics -g -y
```

---

### [Godot Tweening](https://github.com/thedivergentai/gd-agentic-skills)
Tween and create_tween() patterns for UI animations, camera lerp, and property interpolation.

```bash
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-tweening -g -y
```

**Example prompt:**
```
@godot-tweening Animate my HUD health bar with a smooth tween that delays the red background bar so it drains after the green bar.
```

---

### [Godot Performance Optimization](https://github.com/thedivergentai/gd-agentic-skills)
Profiling, draw call reduction, LODs, occlusion culling, and GDScript micro-optimization.

```bash
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-performance-optimization -g -y
```

**Example prompt:**
```
@godot-performance-optimization Profile my 3D level and suggest specific optimizations to reduce draw calls and improve frame time.
```

---

### [Godot Debugging & Profiling](https://github.com/thedivergentai/gd-agentic-skills)
Debugger, remote inspector, custom debug overlays, and `print_debug` patterns.

```bash
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-debugging-profiling -g -y
```

---

## 9) Micro Skills — Advanced & Specialized

### [Godot GDScript Mastery](https://github.com/thedivergentai/gd-agentic-skills)
Typed GDScript, lambdas, coroutines, annotations, and static functions.

```bash
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-gdscript-mastery -g -y
```

**Example prompt:**
```
@godot-gdscript-mastery Rewrite my player script with full static typing, @export annotations, and typed signals throughout.
```

---

### [Godot Physics 3D](https://github.com/thedivergentai/gd-agentic-skills)
Jolt physics, RigidBody3D, collision layers/masks, joints, and physics queries.

```bash
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-physics-3d -g -y
```

---

### [Godot Animation Tree Mastery](https://github.com/thedivergentai/gd-agentic-skills)
AnimationTree, BlendSpace1D/2D, AnimationStateMachine, and root motion.

```bash
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-animation-tree-mastery -g -y
```

**Example prompt:**
```
@godot-animation-tree-mastery Set up a full AnimationTree with a BlendSpace2D for locomotion and an AnimationStateMachine for jump/fall/land transitions on my FPS character.
```

---

### [Godot Resource & Data Patterns](https://github.com/thedivergentai/gd-agentic-skills)
Custom Resource classes for item data, enemy stats, level configs, and data-driven design.

```bash
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-resource-data-patterns -g -y
```

**Example prompt:**
```
@godot-resource-data-patterns Design a data-driven enemy system using custom Resource classes for stats, loot tables, and behavior configs.
```

---

### [Godot Procedural Generation](https://github.com/thedivergentai/gd-agentic-skills)
Procedural level generation, noise-based terrain, random room/dungeon builders.

```bash
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-procedural-generation -g -y
```

---

### [Godot Project Foundations](https://github.com/thedivergentai/gd-agentic-skills)
Project structure, autoload graph, input map, rendering settings, and plugin configuration.

```bash
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-project-foundations -g -y
```

---

### [Godot Genre — Platformer](https://github.com/thedivergentai/gd-agentic-skills)
Platformer-specific patterns: coyote time, jump buffering, ledge grab, wall jump, moving platforms.

```bash
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-genre-platformer -g -y
```

**Example prompt:**
```
@godot-genre-platformer Add ledge grab detection and pull-up animation to my 3D platformer CharacterBody3D.
```

---

### [Godot MCP Setup](https://github.com/thedivergentai/gd-agentic-skills)
Configure the Godot MCP (Model Context Protocol) server to let AI agents read/write your Godot project.

```bash
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-mcp-setup -g -y
```

---

### [Godot MCP Scene Builder](https://github.com/thedivergentai/gd-agentic-skills)
Build and edit Godot scenes programmatically via the MCP tool server.

```bash
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-mcp-scene-builder -g -y
```

---

### [Godot Asset Generator](https://github.com/jwynia/agent-skills)
Generate placeholder and production-ready assets (sprites, textures, icons) via AI prompts.

```bash
npx skills add https://github.com/jwynia/agent-skills --skill godot-asset-generator -g -y
```

---

## 10) New AI Agent Skills

These are general-purpose AI agent skills from `github/awesome-copilot` — **not Godot-specific** but highly useful for game dev workflows.

### [Game Engine](https://github.com/github/awesome-copilot)
Broad game engine architecture knowledge: ECS, scene graphs, physics, rendering pipelines.

```bash
npx skills add https://github.com/github/awesome-copilot --skill game-engine -g -y
```

---

### [Create Implementation Plan](https://github.com/github/awesome-copilot)
Break down a feature request into a detailed, step-by-step implementation plan.

```bash
npx skills add https://github.com/github/awesome-copilot --skill create-implementation-plan -g -y
```

**Example prompt:**
```
@create-implementation-plan Create a step-by-step implementation plan for adding a full inventory and equipment system to my Godot 4 3D platformer.
```

---

### [Create Specification](https://github.com/github/awesome-copilot)
Write a structured feature specification from a rough idea or user story.

```bash
npx skills add https://github.com/github/awesome-copilot --skill create-specification -g -y
```

---

### [Conventional Commit](https://github.com/github/awesome-copilot)
Format git commit messages following the Conventional Commits standard.

```bash
npx skills add https://github.com/github/awesome-copilot --skill conventional-commit -g -y
```

---

### [Git Commit](https://github.com/github/awesome-copilot)
Generate clear, descriptive git commit messages from your staged changes.

```bash
npx skills add https://github.com/github/awesome-copilot --skill git-commit -g -y
```

---

### [Refactor](https://github.com/github/awesome-copilot)
Identify and apply refactoring opportunities: extract method, reduce complexity, improve naming.

```bash
npx skills add https://github.com/github/awesome-copilot --skill refactor -g -y
```

**Example prompt:**
```
@refactor My player.gd is 800 lines. Identify refactoring opportunities and split it into smaller, focused scripts.
```

---

### [Security Review](https://github.com/github/awesome-copilot)
Review code for common security vulnerabilities and insecure patterns.

```bash
npx skills add https://github.com/github/awesome-copilot --skill security-review -g -y
```

---

### [Create Technical Spike](https://github.com/github/awesome-copilot)
Plan a time-boxed technical investigation to reduce uncertainty before implementation.

```bash
npx skills add https://github.com/github/awesome-copilot --skill create-technical-spike -g -y
```

---

### [Documentation Writer](https://github.com/github/awesome-copilot)
Generate inline code documentation, API docs, and wiki pages.

```bash
npx skills add https://github.com/github/awesome-copilot --skill documentation-writer -g -y
```

---

### [MCP Security Audit](https://github.com/github/awesome-copilot)
Audit MCP server configurations and tool definitions for security risks.

```bash
npx skills add https://github.com/github/awesome-copilot --skill mcp-security-audit -g -y
```

---

### [Agentic Eval](https://github.com/github/awesome-copilot)
Evaluate and score the quality of AI agent outputs against defined criteria.

```bash
npx skills add https://github.com/github/awesome-copilot --skill agentic-eval -g -y
```

---

## 11) Full Install — New Micro & Agent Skills (Copy/Paste)

```bash
# Micro Skills — Core Gameplay Systems
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-ability-system -g -y
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-state-machine-advanced -g -y
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-camera-systems -g -y
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-input-handling -g -y
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-audio-systems -g -y
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-save-load-systems -g -y
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-scene-management -g -y
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-signal-architecture -g -y
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-autoload-architecture -g -y
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-combat-system -g -y
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-navigation-pathfinding -g -y
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-raycasting-queries -g -y

# Micro Skills — Visual, FX & Performance
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-3d-lighting -g -y
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-3d-materials -g -y
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-particles -g -y
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-shaders-basics -g -y
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-tweening -g -y
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-performance-optimization -g -y
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-debugging-profiling -g -y

# Micro Skills — Advanced & Specialized
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-gdscript-mastery -g -y
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-physics-3d -g -y
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-animation-tree-mastery -g -y
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-resource-data-patterns -g -y
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-procedural-generation -g -y
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-project-foundations -g -y
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-genre-platformer -g -y
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-mcp-setup -g -y
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-mcp-scene-builder -g -y
npx skills add https://github.com/jwynia/agent-skills --skill godot-asset-generator -g -y

# New AI Agent Skills
npx skills add https://github.com/github/awesome-copilot --skill game-engine -g -y
npx skills add https://github.com/github/awesome-copilot --skill create-implementation-plan -g -y
npx skills add https://github.com/github/awesome-copilot --skill create-specification -g -y
npx skills add https://github.com/github/awesome-copilot --skill conventional-commit -g -y
npx skills add https://github.com/github/awesome-copilot --skill git-commit -g -y
npx skills add https://github.com/github/awesome-copilot --skill refactor -g -y
npx skills add https://github.com/github/awesome-copilot --skill security-review -g -y
npx skills add https://github.com/github/awesome-copilot --skill create-technical-spike -g -y
npx skills add https://github.com/github/awesome-copilot --skill documentation-writer -g -y
npx skills add https://github.com/github/awesome-copilot --skill mcp-security-audit -g -y
npx skills add https://github.com/github/awesome-copilot --skill agentic-eval -g -y
```
