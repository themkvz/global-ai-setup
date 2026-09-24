---
name: x-wait-what
description: "Stop. The last message did not land: explain it again like I am five, with tiny words and an everyday picture, then map it back to the real terms."
argument-hint: "[the part that confused you]"
disable-model-invocation: true
---

# Wait, what?

The last message did not land. Explain the same content again as if to a five-year-old. Do not add new work, new findings, or new options: the goal is understanding, not progress.

If the user named the confusing part, explain only that part. Otherwise explain the main point of the last message.

## Format

1. **The big idea.** One sentence a child would get.
2. **Picture it.** One everyday comparison: toys, a kitchen, the mail, a library, a queue at a shop. Pick one that matches how the thing actually works, and keep it for the whole answer. Switching pictures mid-way confuses more than it helps.
3. **Step by step.** What happens, or what I said, in 3–5 numbered steps, told inside the picture.
4. **Grown-up words.** A short list mapping each part of the picture to the real thing: `mailbox → the Valkey session store`. Keep `path:line` references and exact names here, so the user can act on it. If the picture is wrong in a way that matters, say where it breaks in one line.
5. **What now.** The one thing I will do next, or the one decision needed, as a yes/no or a pick-one question.

## Language

- Short sentences, about 12 words or fewer. One idea each.
- Everyday words. No jargon, acronyms, or code in sections 1–3; they belong in section 4.
- If a technical word cannot be avoided, explain it right away: "a token, which is like a ticket".
- Say who does what: "the server checks your ticket", not "the ticket is validated".
- Simple is not cute. No baby talk, no "great question", no apologies, no comments about the rewrite.
- Simple must still be true. Leave details out, but never say something false to make it easier.

## Example

Last message: "The BFF stores the refresh token server-side and single-flights refresh per session to avoid reuse detection revoking the family."

1. **The big idea.** Only one helper may swap the old ticket for a new one.
2. **Picture it.** Your ticket to the fair works once at the swap booth. Show it twice and the booth thinks it was stolen.
3. **Step by step.**
   1. Your ticket gets old.
   2. A helper takes it to the booth and gets a new one.
   3. If two helpers go at the same time, the booth sees the same ticket twice.
   4. The booth thinks someone stole it, so it cancels all your tickets.
   5. So one helper goes, and the others wait for them.
4. **Grown-up words.** ticket → refresh token · booth → `/auth/refresh` · cancelling all tickets → revoking the token family · one helper at a time → single-flight refresh per session.
5. **What now.** Should I add the one-helper-at-a-time rule to the refresh code?
