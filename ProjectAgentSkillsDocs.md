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

## 5) Full Install (Copy/Paste)

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
