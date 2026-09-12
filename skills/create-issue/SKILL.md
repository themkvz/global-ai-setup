---
name: create-issue
description: Create one concise issue from the current conversation on Linear, Jira, Azure DevOps, GitHub, GitLab, or another configured tracker, using an available MCP integration or installed CLI.
disable-model-invocation: true
---

# Create Issue

Create one issue from the current conversation. Keep it short and useful.

## Process

1. Use the conversation and relevant project context to identify the problem, requested outcome, and acceptance criteria.
2. Determine the tracker from repository configuration, issue references, git remotes, or the user's request. Do not guess when more than one tracker is plausible.
3. Look for a connected MCP tool for that tracker. If none is available, look for an installed, authenticated CLI and inspect its help before using it. Common examples are:
   - Linear: a connected Linear MCP tool or installed Linear CLI
   - Jira: a connected Jira MCP tool, `acli`, or `jira`
   - Azure DevOps: a connected Azure DevOps MCP tool or `az boards`
   - GitHub: a connected GitHub MCP tool or `gh`
   - GitLab: a connected GitLab MCP tool or `glab`
4. Ask one focused question only when a required value cannot be inferred, such as the tracker, project, team, or issue type.
5. Create the issue directly. If no suitable authenticated tool is available, say which integration or CLI is needed and provide the final title and body ready to paste.
6. Return the created issue's identifier and URL. Do not add a long recap.

Use the project's existing defaults for team, project, issue type, labels, area, and iteration. Do not invent metadata. Do not create duplicates; search first when the tracker supports a quick title search.

## Issue format

**Title:** an action-oriented summary, preferably under 80 characters.

**Body:**

```markdown
## Outcome

<One or two sentences describing the user-visible or operational result.>

## Acceptance criteria

- [ ] <Verifiable result>
- [ ] <Verifiable result>
```

Add a short `## Context` section only when the reason or constraint would otherwise be lost. Avoid implementation plans, code snippets, file lists, conversation transcripts, and speculative details.
