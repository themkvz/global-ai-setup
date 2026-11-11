---
name: x-ask-skill
description: "Not sure which skill fits? Read the current session, match it against the shared ~/.ai skills (and other installed skills if they fit better), and recommend one with the exact command to run it."
argument-hint: "[problem, optional]"
disable-model-invocation: true
allowed-tools: Bash(head *) Read(~/.ai/skills/**)
effort: low
---

# Ask Skill

Pick the skill that best fits what the user is doing right now. Recommend only; never run the picked skill until the user says yes.

## 1. Understand the situation

The input is the session, not a task name. Read the recent conversation: what was asked, what was done, what files and tools are involved, where the work stands (planning, building, debugging, reviewing, shipping, reporting). If the user typed text after the command, treat it as the problem they want solved and weigh it over older history. With an empty session and no text, ask one short question about what they are trying to do.

## 2. Collect the skills

Shared skills are the user's own setup and come first. Read their frontmatter:

```bash
head -n 20 ~/.ai/skills/*/SKILL.md
```

Descriptions can span several lines (`description: >`), so read up to the second `---`; if a file's output has no second `---`, Read that file. Skip `x-ask-skill` itself. The installed name is the frontmatter `name` (`x-<dir>`).

Note `disable-model-invocation: true`: those skills are manual-only, are missing from the agent's own skill list, and are the ones the user most likely forgot. Note `argument-hint` for the command line.

Other installed skills (plugins, `anthropic-skills:*`, `expo:*`, built-ins) come from the skill list already in your context. Consider them only when no shared skill fits well, or when one is clearly better for this situation.

## 3. Choose

Match on what the skill does against where the work stands, not on shared keywords. A skill that reports on finished work fits after building, not before. Prefer the narrowest skill that covers the need. If nothing fits better than doing the work directly, say so: a forced pick wastes the user's time.

## 4. Answer

Keep it short. Use this shape:

```markdown
**Pick:** `x-<name>`: <one line why it fits this session>
**Run:** `/x-<name> <arguments filled from context>`
**Alt:** `<name>`: <when to choose it instead>
**Run it?**
```

- **Run:** fill the arguments from the session (issue key, URL, path) when known; otherwise keep the `argument-hint` placeholder. For a skill without `disable-model-invocation`, add "(also triggers on its own)".
- **Alt:** at most one line; omit when there is no real alternative. A non-shared skill goes here unless it clearly beats every shared one.
- Nothing fits: replace Pick/Run with `**No skill needed:** <one line why>` and offer to do the work directly.
