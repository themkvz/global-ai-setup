---
name: x-wait-what
description: "Stop. The last message did not land: explain it again in plain, simple words, step by step, keeping the real technical terms."
argument-hint: "[the part that confused you]"
disable-model-invocation: true
---

# Wait, what?

The last message did not land. Explain the same content again in plain, simple words for an experienced developer whose first language is not English. Do not add new work, new findings, or new options: the goal is understanding, not progress.

If the user named the confusing part, explain only that part. Otherwise explain the main point of the last message.

## Format

1. **In short.** One or two plain sentences: what it is and why it matters.
2. **How it works.** 3–6 numbered steps in the real order of events. Say who does what.
3. **Why.** The problem this solves, or what breaks without it. One or two sentences.
4. **What now.** The one thing I will do next, or the one decision needed, as a yes/no or a pick-one question.

Add a comparison to something familiar only if it really helps. Keep it to one line, and it must match how the thing actually works.

## Language

- Plain English at B1 level: common words, short sentences, one idea each.
- Keep technical terms, names, and `path:line` references exact. Do not replace them with vague words.
- Explain a term the first time only if the last message used it without explaining it: "the token family (all tokens made from the same login)".
- Active voice: "the server checks the token", not "the token is validated".
- No baby talk, no "great question", no apologies, no comments about the rewrite.
- Simple must still be true. Leave details out, but never say something false to make it easier.

## Example

Last message: "The BFF stores the refresh token server-side and single-flights refresh per session to avoid reuse detection revoking the family."

1. **In short.** Only one request per session may refresh the token at a time. Otherwise the API logs the user out.
2. **How it works.**
   1. The access token expires.
   2. The BFF sends the refresh token to `/auth/refresh` and gets a new pair.
   3. Each refresh token works only once.
   4. If two requests refresh at the same time, the API sees the same refresh token twice.
   5. The API treats this as theft and revokes the token family (all tokens from that login).
   6. With single-flight, the first request refreshes and the others wait and reuse its result.
3. **Why.** Without it, a page that fires parallel requests can log the user out at random.
4. **What now.** Should I add single-flight refresh to the refresh code?
