---
name: model-router
description: Ask Jev (TypeSafe) which available model best fits the task at hand, using whichever model catalog belongs to the current host (Claude Code, Codex, etc.). Use when unsure which model tier to reach for, or the user asks "which model should I use" / "route this to the best model".
disable-model-invocation: true
---

# Model Router

Pick the best available model for a task by asking Jev (TypeSafe's System One model), scoped
to whichever host you are currently running in. Requires `TYPESAFE_API_KEY` in the
environment — see the `typesafe-ai` skill for background.

## Process

1. **Identify your own host and model catalog from your own context.** Your system prompt
   already lists the models you can be run as (Claude Code's names Claude model IDs, Codex's
   names its own). Use exactly what your current context gives you — do not hardcode or guess
   model names here. If your context exposes no catalog, ask the user which models to consider.
2. **Get the task.** Use the user's request, or ask for a one-line task description if none
   was given.
3. **Ask Jev a `choice` question** over that task:
   - `state`: the task description.
   - `questions.best_model`: `type: "choice"`, `instructions`: "Which model should handle this
     task?", `criteria`: one entry per model in your catalog, each a one-line description of
     that model's strengths, cost, and speed, from what you already know about it.
4. **Call the API:**
   ```bash
   curl -s -X POST https://api.typesafe.ai/v1/systemone \
     -H "Authorization: Bearer $TYPESAFE_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "state": "<task description>",
       "model": "jev-latest",
       "questions": {
         "best_model": {
           "type": "choice",
           "instructions": "Which model should handle this task?",
           "criteria": { "<model-id>": "<one-line strengths/cost/speed>", "...": "..." }
         }
       }
     }'
   ```
5. **Report the result:** the chosen model and its confidence. Below roughly 0.5 confidence,
   say so and default to your host's standard/general-purpose model instead of committing to
   the low-confidence pick.

Never route to a model that does not actually exist in your current host — Jev only judges the
task against the criteria you give it; it has no independent knowledge of what is available.
