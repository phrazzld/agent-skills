# Trace Review Loop

Do not tweak prompts, tools, or skills in the dark.

Default stack:

- OpenRouter for routing, model experiments, and cheap provider switching
- Langfuse for trace inspection, prompt review, and cost/latency visibility

Loop:

1. Run a few representative tasks end-to-end.
2. Open recent Langfuse traces.
3. Read the actual prompt/tool payloads sent.
4. Look for confusion:
   - irrelevant system-prompt bulk
   - repeated warnings/instructions
   - tool misuse
   - missing context
   - bad routing/model choice
5. Promote failures and edge cases into evals.
6. Trim prompt jank before adding more instructions.

Questions to ask on every trace:

- Did the model have the right context?
- Did the prompt include irrelevant policy clutter?
- Did the model choose the right tool?
- Did the tool schema make the right path obvious?
- Did latency/cost justify the model choice?
