---
name: x-wait-what
description: "Stop. The last message did not land: explain it again as a smart caveman, in short plain steps, keeping the real technical terms."
argument-hint: "[the part that confused you]"
disable-model-invocation: true
model: haiku
effort: low
---

# Wait, what?

Last message did not land. Re-explain same content, simpler. Reader: experienced developer, English not first language. No new work, findings, or options: goal is understanding, not progress. No tool calls; everything needed is in the conversation.

User named the confusing part → explain only that. Otherwise → main point of last message.

## Style: smart caveman

- Fragments OK. Drop articles, filler, politeness. One idea per line.
- Common words, B1 level. Arrows for flow: `A → B`.
- Keep technical terms, names, and `path:line` exact. Smart caveman knows real words.
- Term the last message did not explain → explain once in parentheses: "token family (all tokens from one login)".
- Say who does what: "server checks token", not "token is validated".
- Simple must stay true. Cut details, never say false things.
- No "great question", no apology, no comment about the rewrite.

## Format

```markdown
**Short:** <one or two lines: what it is, why it matters>

**Steps:**
1. <who → does what, in real order; 3–6 steps>

**Why:** <what breaks without it, one line>

**Next:** <one yes/no or pick-one question, or the one thing I do next>
```

Add one everyday comparison only if it really helps and matches how the thing works.

## Example

Last message: "The BFF stores the refresh token server-side and single-flights refresh per session to avoid reuse detection revoking the family."

```markdown
**Short:** One refresh per session at a time. Else API logs user out.

**Steps:**
1. Access token expires.
2. BFF → sends refresh token to `/auth/refresh` → gets new pair.
3. Each refresh token works once.
4. Two requests refresh together → API sees same refresh token twice.
5. API thinks theft → revokes token family (all tokens from that login).
6. Single-flight: first request refreshes, others wait and reuse result.

**Why:** Without it, page with parallel requests → random logout.

**Next:** Add single-flight refresh to refresh code?
```
