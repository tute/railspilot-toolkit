---
name: fact-checker
description: Investigate a news article URL for factual accuracy, rhetorical manipulation, and media quality. Extracts claims, gathers independent evidence via web search, assesses each claim, and runs media-quality analyzers (misrepresentation, temporal manipulation, statistical deception, selective quotation, rhetorical fallacies, contextual gaps, emotional manipulation). Use when asked to fact-check, investigate, or analyze a news article URL.
---

# Fact-Checker Investigation

Ported from [Frank Investigator](https://github.com/akitaonrails/frank_investigator) — a Rails app that runs a multi-step news fact-checking pipeline. This skill replaces Rails jobs with agent orchestration, Chromium with WebFetch, and DuckDuckGo scraping with WebSearch.

## Pipeline Overview

```
URL → Fetch → Extract Claims → Search Evidence → Assess Claims
  → Content Analysis (5-in-1) → Rhetorical Fallacies
  → Contextual Gaps (+ search) → Emotional Manipulation → Summary
```

## Instructions

When given a news article URL, run the pipeline below **in order**. Each step feeds the next. Write all analysis output in the article's language.

Present a short progress line before each step so the user sees pipeline movement.

### Step 1: Fetch Article

Use `WebFetch` on the URL. Extract:
- **title**: the article headline
- **host**: the domain (e.g. `folha.uol.com.br`)
- **body_text**: the article body (strip nav, ads, cookie notices, boilerplate)
- **published_at**: publication date if visible

If the fetch fails or returns mostly boilerplate, tell the user and stop.

### Step 2: Extract Claims

Analyze the article body and extract **3–8 core factual claims**.

Follow the claim extraction criteria in [analyzers.md](analyzers.md) § Claim Extraction.

For each claim produce:
- `text`: the claim as stated
- `canonical_form`: rewritten as clear Subject-Verb-Object (proper nouns, ISO dates, "X%")
- `importance`: high / medium / low
- `checkability`: checkable / not_checkable / ambiguous

Discard opinions, rhetoric, background filler, vague statements, and duplicates. Fewer precise claims are better than many vague ones.

### Step 3: Gather Evidence

For each **checkable** claim:

1. Generate 2–3 concise search queries (under 10 words each, in the article's language, excluding the original outlet name).
2. Run `WebSearch` for each query.
3. For the top 2–3 results per claim, run `WebFetch` to get the article content.

Collect evidence as: `{ url, title, excerpt (first ~500 chars of body) }`.

### Step 4: Assess Claims

For each claim + its evidence, determine:

| Field | Values |
|-------|--------|
| verdict | supported, disputed, mixed, needs_more_evidence, not_checkable |
| confidence | 0.0 – 0.97 |
| reason_summary | Must cite specific evidence sources by URL or title |

Follow the assessment rules in [analyzers.md](analyzers.md) § Claim Assessment.

Be conservative: prefer `needs_more_evidence` over a weak `supported` or `disputed`.

### Step 5: Batch Content Analysis (5-in-1)

Analyze the full article for these five dimensions in a single pass. Follow the detailed criteria in [analyzers.md](analyzers.md) § Batch Content Analysis.

1. **Source Misrepresentation** — does the article accurately represent its cited sources?
2. **Temporal Manipulation** — is old data presented as current?
3. **Statistical Deception** — are numbers presented misleadingly?
4. **Selective Quotation** — are quotes taken out of context?
5. **Authority Laundering** — does the citation chain inflate low-authority sources?

**Calibration**: not every article has problems. Return empty findings and high integrity scores when no issues exist. Minor editorial choices are NOT deception.

### Step 6: Rhetorical Fallacy Analysis

Detect logical fallacies from this set: bait_and_pivot, appeal_to_authority, false_cause, strawman, anecdote_over_data, loaded_language, false_dilemma, slippery_slope, ad_hominem, cherry_picking, equivocation, odious_categorization, twisted_conclusion, paradox_framing, false_admission, faulty_proof_exploitation.

See [analyzers.md](analyzers.md) § Rhetorical Fallacies for definitions.

Only flag **clear, identifiable** fallacies. Normal journalistic framing is not a fallacy.

### Step 7: Contextual Gap Analysis

Identify what the article **doesn't say** — the omissions that let factually correct claims assemble into a misleading narrative. Look for the 9 omission patterns listed in [analyzers.md](analyzers.md) § Contextual Gaps.

For each gap:
1. State the unaddressed question
2. Explain why it matters
3. Run `WebSearch` with a targeted query to find counter-evidence
4. Report what you found

Rate overall `completeness_score` (0.0–1.0): 1.0 = complete, <0.4 = critical context missing.

### Step 8: Emotional Manipulation Score

Assess whether emotional appeals **substitute** for evidence or **accompany** it.

- High emotion + high evidence = passionate journalism (low manipulation)
- High emotion + low evidence + deception signals = manipulation (high score)

Use all prior analyzer scores as inputs. See [analyzers.md](analyzers.md) § Emotional Manipulation.

### Step 9: Executive Summary + Honest Headline

Synthesize all findings into:

1. **Overall quality**: strong / mixed / weak / insufficient (see rating guide in [analyzers.md](analyzers.md) § Summary)
2. **Conclusion**: 2–3 sentence executive summary
3. **Strengths**: bullet list
4. **Weaknesses**: bullet list
5. **Honest headline**: what the headline SHOULD have been — more accurate, no sensationalism, no euphemism. If the original is already fair, keep it unchanged.

## Output Format

Present the final report in this structure:

```markdown
# Investigation: [Article Title]
**Source**: [host] | **Date**: [published_at]
**Original headline**: [title]
**Honest headline**: [honest_headline]
**Overall quality**: [strong|mixed|weak|insufficient]

## Executive Summary
[conclusion]

## Claims Assessment
[Table: claim | verdict | confidence | reason]

## Content Analysis
### Source Misrepresentation — Score: [X]
### Temporal Manipulation — Integrity: [X]
### Statistical Deception — Integrity: [X]
### Selective Quotation — Integrity: [X]
### Authority Laundering — Score: [X]

## Rhetorical Fallacies
[List with type, severity, excerpt, explanation]
**Narrative bias score**: [X]

## Contextual Gaps
[Questions + evidence found]
**Completeness score**: [X]

## Emotional Manipulation
**Temperature**: [X] | **Evidence density**: [X] | **Manipulation score**: [X]
**Dominant emotions**: [list]

## Strengths
- ...

## Weaknesses
- ...
```

## Critical Rules

- **NO HALLUCINATION**: only reference URLs, sources, claims, quotes, and data that are explicitly present in fetched content. Never invent or guess.
- **Calibration over punishment**: most articles have imperfections. Minor issues should not accumulate into a harsh verdict. The question is "does this article deliberately mislead?" not "is it perfect?"
- **Language**: write all analysis in the article's language.
