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
3. **Tracker and tool.** Infer the tracker from the issue key format, the user's words, project instructions (`CLAUDE.md`, `AGENTS.md`), then the git remote host. Prefer a connected MCP tool; otherwise an installed, authenticated CLI (`acli`/`jira`, `az boards`, `gh issue comment`, `glab issue note`). Check a CLI's `--help` before the first call.
4. **Read the issue.** Fetch its title, description, and acceptance criteria, and skim recent comments. The comment answers this issue: refer to its acceptance criteria, use its terms, and do not repeat what earlier comments already say. Write in the language the issue uses.
5. **Gather the facts.** Start from the conversation. Then fill gaps from the branch: `git log <base>..HEAD --oneline`, `git diff <base>...HEAD --stat`, and the full diff only where the behavior change is unclear. Find the base from the PR, or `main`/`master`. Get the PR link if one exists (`gh pr view --json url`, `glab mr view`). For QA, look at what else uses the changed code: that is where regressions hide.
6. **Write** the comment in the variant's format below, in the tracker's native format (Jira may need wiki markup or ADF depending on the tool; Azure DevOps comments are HTML). With a CLI, pass the body through a file or heredoc so newlines and backticks survive.
7. **Post and report.** Return the comment URL, or the issue URL if the tool gives none, in one line. If no suitable authenticated tool exists, name the MCP or CLI needed and print the comment ready to paste.

## Writing rules (both variants)

- Describe results and behavior, not code. Translate "added null check in `parseInvoice`" into "Invoices with an empty line no longer fail to import."
- Leave out: file names, function and class names, libraries, refactors, how the bug was found, the debugging story, and test counts. Mention a technical detail only when the reader must act on it: a migration, a new env variable or feature flag, a config change, a breaking API change.
- Short sentences, plain words, no filler ("I have successfully implemented..."), no hedging, no emojis.
- State the real status. If something is partial, blocked, or a known limitation, say so in one line. Never claim tested or verified unless it was.
- Never include secrets, tokens, `.env` values, personal data, customer names, or internal hostnames.

## Short format

Aim for 1–4 lines. One sentence is fine when it says everything.

```markdown
<Status word>: <what changed, in product terms, in one or two sentences.>

- <Only crucial extras: a limitation, a decision needed, a follow-up, a required migration or flag.>

PR: <link>
```

Status words: `Done`, `Fixed`, `Partly done`, `Blocked`, `In review`. Drop the bullet list when there is nothing crucial. Drop the PR line when there is no PR.

**Example:**

```markdown
Fixed: CSV export now includes archived orders and keeps the selected date range.

- Exports over 50k rows are still slow; tracked in ENG-412.

PR: https://github.com/acme/shop/pull/881
```

## QA format

Still concise: a tester should finish reading in under a minute. Every step must be something a tester can do in the UI or API without reading the code.

```markdown
**What changed**
- <Behavior change, from the user's point of view.>

**How to test**
1. <Precondition or setup, if any.>
2. <Action.>
   Expected: <observable result>

**Also check** (regression risk)
- <Feature or screen that shares the changed logic, and what to look for.>

**Notes**
- <Only if needed: environment or build, feature flag, test data, user role, migration, known limitation, what is out of scope.>

PR: <link>
```

Cover edge cases the change targets (empty, error, permission, limit cases) as steps or expected results, not as a separate essay. Derive "Also check" from the code that changed and its callers, then name the user-facing features, not the code. Drop `Notes` when empty.

**Example:**

```markdown
**What changed**
- CSV export now includes archived orders.
- The export uses the date range selected in the filter instead of the last 30 days.

**How to test**
1. Open Orders as an admin and set the date range to last quarter.
2. Archive one order in that range, then click Export CSV.
   Expected: the file contains only orders from last quarter, including the archived one.
3. Export with a range that has no orders.
   Expected: the file has only the header row; no error.

**Also check** (regression risk)
- Invoices export: it shares the same export logic. Check that the date range is applied there too.

**Notes**
- Test on staging, build 2.14.0 or later.

PR: https://github.com/acme/shop/pull/881
```
