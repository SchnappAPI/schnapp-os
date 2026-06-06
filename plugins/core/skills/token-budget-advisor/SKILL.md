---
name: token-budget-advisor
description: Use when the user wants to control response depth or length up front — "short version", "tldr", "brief answer", "detailed answer", "exhaustive answer", "respond at 50% depth", "how many tokens will this use", "save tokens". Do not trigger when a depth was already set this session, the answer is one line, or "token" means an auth/payment token.
---

# token-budget-advisor

Offer the user a depth choice **before** answering, so they control how much the response
consumes. This skill is about *output* depth on a single answer. For auditing what loaded
components cost, see `context-budget`; for when to compact a long session, see
`strategic-compact`.

## Flow

1. **Estimate input tokens.** Prose: `words × 1.3`. Code-heavy/mixed: `chars / 4`. Use the
   dominant content type; keep it heuristic.
2. **Pick a response-size multiplier** from the prompt's complexity, then cap at the model's
   output limit:

   | Complexity | Multiplier | Example |
   |---|---|---|
   | Simple | 3×–8× | single fact, yes/no |
   | Medium | 8×–20× | "how does X work" |
   | Code + context | 10×–25× | code request |
   | Complex | 15×–40× | multi-part analysis, architecture |
   | Creative | 10×–30× | essays, narrative |

   Window = `input × min` to `input × max`.
3. **Present options** before answering, with the real numbers:

   ```
   Input: ~[N] tokens | Complexity: [level]
   [1] Essential  (25%) → ~[t]  Direct answer, no preamble
   [2] Moderate   (50%) → ~[t]  Answer + context + 1 example
   [3] Detailed   (75%) → ~[t]  Full answer with alternatives
   [4] Exhaustive (100%)→ ~[t]  Everything
   Heuristic estimate, ±15%.
   ```

   Level token = `min + (max − min) × pct` (100% = max).
4. **Answer at the chosen level:**

   | Level | Length | Include / omit |
   |---|---|---|
   | 25% | 2–4 sentences | answer only / no context, examples, nuance |
   | 50% | 1–3 paragraphs | + context + 1 example / no deep analysis |
   | 75% | structured | + examples, pros/cons, alternatives / no extreme edge cases |
   | 100% | unbounded | everything |

## Skip the question

If the user already signals a level, answer at it immediately: "1"/"short"/"tldr" → 25%;
"2"/"balanced" → 50%; "3"/"detailed" → 75%; "4"/"full deep dive" → 100%. A level set earlier
in the session **holds silently** until the user changes it.

Heuristic only, no real tokenizer. Always show the disclaimer.
