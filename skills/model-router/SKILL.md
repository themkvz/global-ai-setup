---
name: model-router
description: Ask Jev (TypeSafe) which available model best fits a task, using the model catalog of the current host (Claude Code, Codex, etc.). Use when the user asks "which model should I use" or "route this to the best model".
disable-model-invocation: true
---

# Model Router

Pick the best available model for a task by asking Jev, scoped to the host you are running in. Needs `TYPESAFE_API_KEY` in the environment; see the `typesafe-ai` skill for background.

## Process

1. **Catalog.** List the models this host can run, from your own context (system prompt, host docs). Never hardcode or guess model names: Jev only ranks the options you give it and does not know what exists. If your context has no catalog, ask the user which models to consider.
2. **Task.** Use the user's request, or ask for a one-line description.
3. **Criteria.** Write one line per model: strengths, relative cost, speed.
4. **Ask Jev.** Build the payload with `jq` so quotes in the task cannot break the JSON:

   ```bash
   jq -n --arg task "<task description>" --argjson criteria '{"<model-id>": "<strengths, cost, speed>"}' '{
     state: $task,
     model: "jev-latest",
     questions: { best_model: {
       type: "choice",
       instructions: "Which model should handle this task?",
       criteria: $criteria
     } }
   }' | curl -s -X POST https://api.typesafe.ai/v1/systemone \
     -H "Authorization: Bearer $TYPESAFE_API_KEY" \
     -H "Content-Type: application/json" \
     -d @-
   ```

5. **Report** the chosen model and its confidence in one line. Below ~0.5 confidence, say so and recommend the host's default general-purpose model instead.
