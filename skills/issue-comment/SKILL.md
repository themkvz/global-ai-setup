---
name: x-issue-comment
description: Post a concise, factual comment on a Linear, Jira, Azure DevOps, GitHub, GitLab, or other tracker issue. Use `qa` to include detailed, reproducible checks in the same format.
argument-hint: "[qa] [issue keys or URLs] [preview URL] [focus]"
disable-model-invocation: true
effort: medium
---

# Issue Comment

Post one comment per issue about the work done. Invoking this skill is the approval to post. Do not ask for a draft review unless a required value is missing.

Readers are product managers, leads, other developers, and QA. Most of them read the comment in a notification or a list, in a few seconds. A comment is useful only if it says what changed for the product and what, if anything, needs the reader's action. Implementation details belong in the PR, not in the issue.

## Process

1. **Scope.** Arguments win over inference. They may contain `qa`, one or more issue keys or URLs, a preview or staging URL, and a focus (for example, "only the export fix").
2. **Issue.** Find the issue in this order: the arguments, the conversation, an issue key in the branch name (`ENG-123`, `PROJ-45`, `AB#123`, `123-fix-login`), recent commit messages. If none is found or the signals conflict, ask. For several issues, post one comment on each, about that issue's own part of the work.
3. **Tracker and tool.** Infer the tracker from, in order: the user's words, project instructions (`CLAUDE.md`, `AGENTS.md`), the issue key format, then the git remote host. An issue key beats the remote host: many GitHub repos track work in Linear or Jira. Prefer a connected MCP tool; otherwise an installed, authenticated CLI (a Linear CLI, `acli`/`jira`, `az boards`, `gh issue comment`, `glab issue note`). Check a CLI's `--help` before the first call. Only add a comment: do not change the issue's status, assignee, or labels.
4. **Read the issue.** Fetch its title, description, and acceptance criteria, and skim recent comments. The comment answers this issue: refer to its acceptance criteria, use its terms, and do not repeat what earlier comments already say. Write in the language the issue uses.
5. **Gather the facts.** Start from the conversation. Then fill gaps from the branch: `git log <base>..HEAD --oneline`, `git diff <base>...HEAD --stat`, and the full diff only where the behavior change is unclear. Find the base from the PR, or `main`/`master`. For `qa`, look at what else uses the changed code to identify useful regression checks.
6. **Write** the comment in the format below, in the tracker's native format (Jira may need wiki markup or ADF depending on the tool; Azure DevOps comments are HTML). With a CLI, pass the body through a file or heredoc so newlines and backticks survive.
7. **Post and report.** In one line, return the issue key and title and the comment URL (or the issue URL if the tool gives none), so a wrongly guessed issue is easy to spot. If no suitable authenticated tool exists, name the MCP or CLI needed and print the comment ready to paste.

## Writing rules

- Give clear context and facts about product behavior. Leave out code details unless the reader must act on them, such as a migration, flag, or breaking API change.
- Use short, plain words: "fix", not "implement a solution for". Standard acronyms such as DB, API, and HTTP are fine; do not invent abbreviations such as cfg, impl, or fn. Do not use arrows.
- Cut filler, ceremony, greetings, closers, praise, emojis, and claims such as "successfully completed". Each line must add context, a fact, or a required action.
- Fragments are fine. Omit articles only when the result is readable. Keep words such as not, never, no, only, and except, as well as exact numbers and units.
- Never claim a check passed unless it ran and its result was observed. Label suggested QA steps `To check`.
- Do not include branch, push, delivery, readiness, or workflow status updates. Include links only when they provide useful evidence or a QA environment, in Notes.
- Never include secrets, tokens, `.env` values, personal data, customer names, or internal hostnames (issue links and URLs the user gave are fine).

## Format

Use these labels and order for every comment. Keep each section short.

```markdown
**Context**
<One short sentence naming the affected behavior or problem.>

**Changes**
- <Factual product behavior.>

**Checks**
- <Observed check and result, if useful.>
- To check: <Reproducible action and expected result, if needed.>

**Notes**
- <Actionable limit, prerequisite, or useful evidence or QA environment link, if needed.>
```

Omit Checks when there is no useful evidence or required QA step. The `qa` argument requests detailed, reproducible checks in this same structure: include the role, data, action, and expected result needed to repeat each step. Include targeted edge cases and relevant regression checks when useful.

Omit Notes when there are no actionable limits, prerequisites, or useful links. Preserve safety instructions, for example: "Back up first. Then run migration: it drops the column." Put useful evidence or QA environment links in Notes.

Illustrative example (not a claim about an actual issue):

```markdown
**Context**
CSV export omitted archived orders.

**Changes**
- CSV export includes archived orders in the selected date range.

**Checks**
- To check: Export a range with an archived order. Confirm the CSV includes it.
```

Before posting, check that every statement is supported, the context and behavior are clear, checks are labeled accurately, and limits, negations, numbers, and units are intact.
