# Flow Upload Pack

Use this folder when Gemini Omni / Google Flow will not accept `handoff.html`.

## Uploadable References

- `style-board.png` - primary visual style reference. Use this first.
- `wordmark-night.png` - title/wordmark reference for the final resolve only.
- `handoff-overview.png` - human/agent context screenshot of the concept and storyboard. Do not use this as the main visual reference if the model tends to copy visible text.

## Paste Files

- `flow-agent-instructions.txt` - paste this into the Flow agent before asking it to plan or generate.
- `omni-one-shot-prompt.txt` - paste this when trying one continuous intro generation.
- `omni-shot-by-shot-prompts.txt` - paste individual sections when generating clips separately.

## Recommended Flow Order

1. Upload `style-board.png`.
2. Paste `flow-agent-instructions.txt`.
3. Ask the agent to propose the edit plan, not generate yet.
4. If the plan is good, try `omni-one-shot-prompt.txt`.
5. If the one-shot drifts, fall back to the individual prompts in `omni-shot-by-shot-prompts.txt`.
6. Use `wordmark-night.png` only when generating or matching the final title plate.
