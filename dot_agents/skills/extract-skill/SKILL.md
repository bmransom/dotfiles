---
name: extract-skill
description: Use when the current session revealed a reusable agent workflow, debugging method, review pattern, or tool process that should become a user or repo skill.
---

# Extract Skill

Distill a reusable skill from the current session only. Do not search historical sessions unless the user explicitly asks.

## Candidate Selection

Use the active conversation and files explicitly provided in this session. Propose 1-3 candidates, each with:

- `name`: lowercase hyphenated skill name.
- `scope`: what the skill helps future agents do.
- `trigger`: when the skill should load.
- `procedure`: the reusable steps learned.
- `exclude`: project-specific facts or one-off details to keep out.
- `eval prompts`: 2-3 prompts that would show whether the skill works.

Ask the user to pick a candidate or provide a different one before drafting.

## Destination Choice

After candidate selection, ask where the skill should live:

- **User skill**: `~/.agents/skills/<name>` via chezmoi source `dot_agents/skills/<name>`. Use for reusable personal workflows across repos and harnesses. Strip project names, local-only paths, and one-off data.
- **Repo skill**: `<repo>/.agents/skills/<name>`. Use for project conventions, local commands, schemas, terminology, or workflows that should travel with the repo. Keep repo-specific details that are part of the reusable workflow.

Record the destination and specificity boundary in the extraction brief.

## Brief

Write `.agent/skill-extractions/<name>/brief.md` with:

```markdown
# <name> Skill Extraction Brief

## Destination
user skill or repo skill, with exact target path

## Candidate
name, purpose, trigger description

## Evidence From This Session
specific decisions, corrections, commands, files, and outcomes

## Reusable Procedure
ordered steps the future skill should teach

## Exclusions
project-specific or one-off details to omit

## Skill Shape
single SKILL.md unless scripts/assets/evals are clearly justified

## Evals
realistic prompts and expected behavior
```

## Drafting Spawn

After the brief is written and printed, spawn a same-harness drafting session:

```bash
~/.agents/skills/extract-skill/scripts/spawn-extractor.sh "<name>" ".agent/skill-extractions/<name>/brief.md"
```

If the harness or tmux cannot be detected, print the command and seed prompt instead.

## Quality Bar

- Description starts with `Use when...` and names trigger conditions, not workflow steps.
- Keep `SKILL.md` concise. Add extra files only for reusable tools, assets, evals, or heavy reference.
- Prefer one excellent example over many generic examples.
- Add eval prompts before considering the skill done.
- Do not include project names in a user skill unless they are clearly marked as non-reusable examples.
