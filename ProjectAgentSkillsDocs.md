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

## 4)

---

## 5) Full Install (Copy/Paste)

```bash
# Discovery
npx skills add https://github.com/vercel-labs/skills --skill find-skills -g -y

# Godot
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
