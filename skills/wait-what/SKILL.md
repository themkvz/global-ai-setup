---
name: wait-what
description: "Stop. That last message did not land: re-pitch it in plain, unambiguous language using the project's own terms."
disable-model-invocation: true
---

# Wait, what?

The last message did not land. Do not add new work. Re-pitch the same content so it is understood on the first read.

## Format

Answer in this order, each as a short block:

1. **Where we are.** One or two sentences of context: what was asked, what has been done so far.
2. **What I just said.** The previous message, rewritten by the rules below.
3. **What is next.** The next action, or the exact decision needed from the user.

Keep file and line references (`path:line`). Put commands, code, and error text in fenced code blocks, never in prose.

## Language rules (ASD-STE100 Simplified Technical English)

- One sentence, one idea. Maximum 20 words per sentence.
- Active voice. Present tense. Name the actor: "the loader calls the API", not "the API is called".
- One word, one meaning. Pick one term for each thing and reuse it. No synonyms, no idioms, no metaphors.
- Concrete nouns and verbs. Replace "handle", "deal with", "leverage", "stuff" with what actually happens.
- No nominalizations: "we validate" instead of "we perform validation".
- Lists for parallel items. Prose for a single line of argument.
- Explain a term the first time it appears if it is not in the project's own vocabulary.
- Do not comment on the rewrite itself. Do not apologise.

## Vocabulary

Use the project's ubiquitous language. Look it up in this order and stop at the first source that defines the term:

1. Project instructions: `CLAUDE.md`, `AGENTS.md`, `.github/copilot-instructions.md`, `GEMINI.md` in the repo root or the nearest parent directory.
2. OpenSpec: `openspec/specs/**` for domain terms, `openspec/changes/**` for the change being worked on.
3. Project docs: `README.md`, `docs/`, any glossary or architecture file.
4. Identifiers in the code being discussed: types, table names, route names.

If the repo has none of these, use the names from the code and say that no project vocabulary was found.
