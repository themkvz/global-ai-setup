---
name: x-issue-comment
description: Post a short, professional status comment on a Linear, Jira, Azure DevOps, GitHub, GitLab, or other tracker issue about the work done in the current conversation and branch. Default variant is a brief status update; the `qa` variant explains what changed and what the QA team should check.
argument-hint: "[qa] [issue key or URL] [focus]"
disable-model-invocation: true
---

# Issue Comment

Post one comment on an issue about the work done. Invoking this skill is the approval to post. Do not ask for a draft review unless a required value is missing.

Readers are product managers, leads, other developers, and QA. Most of them read the comment in a notification or a list, in a few seconds. A comment is useful only if it says what changed for the product and what, if anything, needs the reader's action. Implementation details belong in the PR, not in the issue.

## Variants

- **Short** (default): a status update. Use it unless the arguments contain `qa` or the user asks for a comment for QA or testers.
- **QA**: a handoff to testing. What changed in behavior, how to check it, and what else could break.

## Process

1. **Scope.** Arguments win over inference. They may contain `qa`, an issue key or URL, and a focus (for example, "only the export fix").
2. **Issue.** Find the issue in this order: the arguments, the conversation, an issue key in the branch name (`ENG-123`, `PROJ-45`, `AB#123`, `123-fix-login`), recent commit messages. If none is found or the signals conflict, ask.
3. **Tracker and tool.** Infer the tracker from, in order: the user's words, project instructions (`CLAUDE.md`, `AGENTS.md`), the issue key format, then the git remote host. An issue key beats the remote host: many GitHub repos track work in Linear or Jira. Prefer a connected MCP tool; otherwise an installed, authenticated CLI (a Linear CLI, `acli`/`jira`, `az boards`, `gh issue comment`, `glab issue note`). Check a CLI's `--help` before the first call. Only add a comment: do not change the issue's status, assignee, or labels.
4. **Read the issue.** Fetch its title, description, and acceptance criteria, and skim recent comments. The comment answers this issue: refer to its acceptance criteria, use its terms, and do not repeat what earlier comments already say. Write in the language the issue uses.
5. **Gather the facts.** Start from the conversation. Then fill gaps from the branch: `git log <base>..HEAD --oneline`, `git diff <base>...HEAD --stat`, and the full diff only where the behavior change is unclear. Find the base from the PR, or `main`/`master`. Get the PR link if one exists (`gh pr view --json url`, `glab mr view`). For QA, look at what else uses the changed code: that is where regressions hide. If the work is uncommitted or not pushed, readers cannot see it yet: say so in the comment.
6. **Write** the comment in the variant's format below, in the tracker's native format (Jira may need wiki markup or ADF depending on the tool; Azure DevOps comments are HTML). With a CLI, pass the body through a file or heredoc so newlines and backticks survive.
7. **Post and report.** In one line, return the issue key and title and the comment URL (or the issue URL if the tool gives none), so a wrongly guessed issue is easy to spot. If no suitable authenticated tool exists, name the MCP or CLI needed and print the comment ready to paste.

## Writing rules (both variants)

- Describe results and behavior, not code. Translate "added null check in `parseInvoice`" into "Invoices with an empty line no longer fail to import."
- Leave out: file names, function and class names, libraries, refactors, how the bug was found, the debugging story, and test counts. Mention a technical detail only when the reader must act on it: a migration, a new env variable or feature flag, a config change, a breaking API change.
- Short sentences, plain words, no filler ("I have successfully implemented..."), no hedging, no emojis.
- State the real status. If something is partial, blocked, or a known limitation, say so in one line. Never claim tested or verified unless it was.
- Never include secrets, tokens, `.env` values, personal data, customer names, or internal hostnames (the PR and issue links are fine).

## Short format

Aim for 1–4 lines. One sentence is fine when it says everything.

```markdown
<Status word>: <what changed, in product terms, in one or two sentences.>

- <Only crucial extras: a limitation, a decision needed, a follow-up, a required migration or flag.>

PR: <link>
```

Status words: `Done`, `Fixed`, `In review`, `In progress`, `Partly done`, `Blocked`. `Done` and `Fixed` mean merged or deployed; with an open PR, use `In review`. Drop the bullet list when there is nothing crucial. Drop the PR line when there is no PR.

**Example:**

```markdown
Fixed: CSV export now includes archived orders and keeps the selected date range.

- Exports over 50k rows are still slow; tracked in ENG-412.

PR: https://github.com/acme/shop/pull/881
```

## QA format

Smart caveman style. Fragments, no articles, no filler, no full sentences. Keep every fact a tester needs: role, data, exact button, exact result. One line per step: `action → expected`. A tester reads it in 20 seconds and can do every step in the UI or API without reading code.

```markdown
**Changed**
- <behavior change, user view>

**Test**
1. <setup, if any>
2. <action> → <expected>

**Also check**
- <feature sharing changed logic> → <what to look for>

**Notes**
- <only if needed: env/build, flag, role, test data, migration, limit, out of scope>

PR: <link>
```

Edge cases the change targets (empty, error, permission, limit) go in as steps, not prose. Derive `Also check` from changed code and its callers, but name features, not code. Drop `Notes` when empty.

**Example:**

```markdown
**Changed**
- CSV export includes archived orders.
- Export uses filter date range, not last 30 days.

**Test**
1. Orders as admin, range = last quarter.
2. Archive one order in range, Export CSV → only last-quarter orders, archived one included.
3. Export empty range → header row only, no error.

**Also check**
- Invoices export (same logic) → date range applied.

**Notes**
- Staging, build 2.14.0+.

PR: https://github.com/acme/shop/pull/881
```
