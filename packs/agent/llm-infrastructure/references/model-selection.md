# Staying Current on Models

**The landscape changes monthly. Learn HOW to find current solutions, not memorize specific models.**

## The Failure Mode

**Problem**: Training cutoffs cause agents to recommend deprecated models (GPT-4, Gemini 2.0) months after they're obsolete.

**Solution**: Learn how to find current best models, don't memorize them.

## How to Find Current Models

**Primary Leaderboards** (bookmark these):
- **LMSYS Chatbot Arena** (lmarena.ai) - Human preference rankings, updated continuously
- **Artificial Analysis** (artificialanalysis.ai) - Intelligence, speed, price tracking for 100+ models
- **LiveBench** (livebench.ai) - Contamination-free monthly benchmarks
- **Hugging Face Open LLM Leaderboard** - Best open-source models

**Search Strategy**:
```
✅ GOOD: "AI model leaderboard 2025 coding"
✅ GOOD: "SOTA reasoning models November 2025"
❌ BAD:  "best AI models" (no date context)
❌ BAD:  "GPT-4 vs Claude" (likely outdated)
```

**Always**:
- Include current year in searches
- Check article/benchmark publication dates
- Verify model release dates
- Cross-reference 2-3 sources

## Model Selection Framework

```
1. Define task → Identify relevant benchmark
   (Coding: SWE-bench | Reasoning: GPQA | General: Arena Elo)

2. Check leaderboards → Find top 3-5 models

3. Consider constraints:
   - Budget: tokens/$ ratio
   - Speed: latency requirements
   - Context: window size needed

4. Test empirically → Use OpenRouter to test multiple models

5. Monitor & iterate → Models improve monthly
```

## Red Flags for Outdated Info

- Articles >3 months old without update dates
- Generic claims: "GPT-4 is best for X"
- No model version numbers (dates/build codes)
- Comparisons missing recent releases
- Benchmark scores without test dates

## Use OpenRouter for Flexibility

**Why**: Single API for 400+ models across all providers
- Easy A/B testing between models
- Automatic fallbacks if model unavailable
- Unified cost tracking
- No vendor lock-in

```typescript
// Test multiple models easily
const models = [
  "anthropic/claude-sonnet-4.5",
  "openai/gpt-5",
  "google/gemini-2.5-pro"
];

for (const model of models) {
  const response = await openrouter.chat({
    model,
    messages: yourTestCases
  });
  // Evaluate quality, cost, speed
}
```

**Key Features**:
- `openrouter/auto` - Automatic best model selection
- Fallback chains for reliability
- Real-time pricing data
- `/models` API endpoint for current model list

## Model Selection Decision Tree

```
1. What's the task?
   Coding → Check SWE-bench leaderboard → Test top 3
   Reasoning → Check GPQA leaderboard → Test top 3
   General → Check Arena Elo → Test top 3

2. What's the budget?
   <$50/mo → Gemini Flash, GPT-4o Mini
   $50-500/mo → Mix of mid-tier + premium
   >$500/mo → Premium models + specialized routing

3. What's the speed requirement?
   <200ms → Check Artificial Analysis latency rankings
   <1s → Most models acceptable
   >1s → Batch processing acceptable

4. Test empirically with OpenRouter → Choose best for YOUR use case
```

## Model-Specific Prompting Styles

Different models have different strengths:

| Model Family | Best For | Prompting Style |
|-------------|----------|-----------------|
| **Claude** | Deep reasoning, coding | Rich context + XML tags + critique. Tends toward verbose code. |
| **GPT-4/5** | Structured output, consistency | Clear sections + few-shot examples. Concise and reliable. |
| **Gemini** | Multimodal, research | Research parameters + citations. Add "Be concise" to shorten. |
| **Reasoning (o-series)** | Complex logic, math | Simple, direct instructions. No manual CoT. |
