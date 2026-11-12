---
name: x-create-issue
description: Create one concise issue from the current conversation on Linear, Jira, Azure DevOps, GitHub, GitLab, or another configured tracker, using an available MCP integration or installed CLI.
argument-hint: "[focus, tracker, or project]"
disable-model-invocation: true
effort: medium
---

# Create Issue

Create one issue from the current conversation. Keep it short and useful: someone who missed the conversation should understand what is wrong or wanted, and when it is done.

Invoking this skill is the approval to create the issue. Do not ask for a draft review unless a required value is missing.

## Process

1. **Scope.** Text passed with the command narrows the focus or names the tracker/project; it wins over inference. If the conversation holds several unrelated problems and no focus was given, ask which one.
2. **Tracker.** Infer it from, in order: the user's words, project instructions (`CLAUDE.md`, `AGENTS.md`, `CONTRIBUTING.md`), issue keys in the branch name or recent commits (`ENG-123`, `PROJ-45`, `AB#123`), then the git remote host (`github.com`, `gitlab`, `dev.azure.com`). An issue key beats the remote host: many GitHub repos track work in Linear or Jira. Ask only when signals conflict or none exist.
3. **Tool.** Prefer a connected MCP tool for that tracker. Otherwise use an installed, authenticated CLI and check its `--help` before the first call:
   - Linear: Linear MCP or a Linear CLI
   - Jira: Jira/Atlassian MCP, `acli`, or `jira`
   - Azure DevOps: Azure DevOps MCP or `az boards work-item create`
   - GitHub: GitHub MCP or `gh issue create`
   - GitLab: GitLab MCP or `glab issue create`
4. **Duplicates.** Run a quick search for open issues with the key terms. If a clear match exists, return it instead of creating a new one and offer to add a comment with `/x-issue-comment`. Skip this step if the tool has no search.
5. **Defaults.** Take team, project, issue type, labels, area, and iteration from project instructions, issue templates (`.github/ISSUE_TEMPLATE/`, `.gitlab/issue_templates/`), or the tracker's defaults. Omit any field you cannot justify; never invent labels or assign someone unless asked. Ask one focused question only for a value the tracker requires and nothing supplies.
6. **Format.** Use the user's explicit format first, then the applicable tracker or repo issue template. Otherwise inspect 2–3 recent, relevant issues in the same project or team and of the same type, if available. Match the recurring title convention, language, headings and order, detail level, and acceptance criteria style. If examples vary, use the closest issue type. Copy structure only, never facts, status, people, or labels. Use the formats below only when no usable pattern is accessible. Keep required template fields; state unknown facts as unknown, or ask only when required for a valid, actionable issue. Never invent reproduction steps.
7. **Create.** Write in the tracker's native format (Azure DevOps descriptions are HTML; Jira may need wiki markup or ADF depending on the tool). With a CLI, pass the body through a file or heredoc (`--body-file`) so newlines and backticks survive shell quoting. Before creating, check that every statement is supported, the problem and outcome are clear, required fields are present, and limits, negations, numbers, and units are intact.
8. **Report.** Return the identifier, title, and URL in one line. If no suitable authenticated tool exists, name the MCP or CLI needed and print the final title and body ready to paste.

## Writing rules

- Describe the known problem and desired outcome, not a claim that the work is already complete.
- Use short, plain words: "fix", not "implement a solution for". Standard acronyms such as DB, API, and HTTP are fine; do not invent abbreviations such as cfg, impl, or fn. Do not use arrows.
- Cut filler, ceremony, greetings, closers, and emojis. Omit branch, push, delivery, readiness, and workflow status updates.
- Fragments are fine. Omit articles only when the result is readable. Keep words such as not, never, no, only, and except, as well as exact numbers and units.
- Preserve safety instructions, for example: "Back up first. Then run migration: it drops the column."

## Fallback issue format

**Title:** action-oriented, under 80 characters. Features and tasks: imperative (`Add retry to invoice sync`). Bugs: the symptom (`Invoice sync drops items after timeout`).

**Feature or task body:**

```markdown
## Outcome

<One or two sentences on the user-visible or operational result.>

## Acceptance criteria

- [ ] <Verifiable result>
- [ ] <Verifiable result>
```

**Bug body:**

```markdown
## Problem

<What happens, where, and who is affected.>

## Steps to reproduce

1. <Step>

**Expected:** <...>
**Actual:** <...>

## Acceptance criteria

- [ ] <Verifiable result, usually "expected behavior holds" plus a regression check>
```

Drop `Steps to reproduce` when they are unknown rather than guessing.

Add a short `## Context` section only when the reason or constraint would otherwise be lost: a decision already made, a linked issue or PR, an error message line. Leave out implementation plans, file lists, conversation transcripts, and speculation.

Issues are often visible to more people than the conversation was, and public on open-source repos. Never include secrets, tokens, `.env` values, personal data, customer names, or internal hostnames (links to issues and PRs are fine); paraphrase or redact.
