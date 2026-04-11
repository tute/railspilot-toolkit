# Analyzer Reference

Detailed criteria for each analysis step. SKILL.md references specific sections here.

## Claim Extraction

Extract ONLY claims that are:
- Verifiable against official records, data, or documents
- Central to the article's news value (not background or filler)
- Specific enough to check (names, dates, numbers, official actions)

DO NOT extract:
- Opinions, rhetoric, or editorial commentary
- Generic background context ("Brazil is the largest country in South America")
- Website UI text, navigation, cookie notices, social share prompts
- Author bylines, publication dates, or metadata
- Vague or hedged statements ("some analysts believe")
- Duplicate or near-duplicate claims (pick the most specific version)

Canonical form rules:
- Rewrite as clear Subject-Verb-Object
- Use proper nouns for entities
- Write dates as ISO 8601 (2025-Q1, 2025-03)
- Write percentages as "X%"
- Remove hedging, attribution, rhetoric
- One sentence, present tense for current facts, past tense for past events

## Claim Assessment

Rules:
- Base assessment ONLY on the provided evidence, not your own knowledge
- Cite specific evidence items by their source URL or title in reasoning
- If evidence is insufficient, say so explicitly
- If sources disagree, note which are more authoritative
- Be conservative: prefer "needs_more_evidence" over weak "supported" or "disputed"

Verdict values: supported, disputed, mixed, needs_more_evidence, not_checkable.
Confidence must be between 0.0 and 0.97.

## Batch Content Analysis

### 1. Source Misrepresentation

Does the article accurately represent its cited sources? Check if the article claims a source says X when it actually says Y. Look for: cherry-picking, exaggeration, context stripping, fabrication, reversal, scope inflation.

For each misrepresentation: article_claim, source_url (if identifiable), verdict (accurate/distorted/fabricated/unverifiable), severity (low/medium/high), explanation.

Score: `misrepresentation_score` (0.0–1.0, where 0 = accurate).

### 2. Temporal Manipulation

Is old data presented as current? Types:
- **stale_data**: referencing old data without dating it
- **timeline_mixing**: juxtaposing events from different periods to imply causation
- **implicit_recency**: present tense for past events
- **selective_timeframe**: choosing dates that exaggerate a trend

Score: `temporal_integrity_score` (0.0–1.0, where 1.0 = good).

### 3. Statistical Deception

Are numbers presented misleadingly? Types: cherry_picked_baseline, relative_absolute_confusion, survivorship_bias, scale_manipulation, denominator_games, missing_base.

For each: type, excerpt, severity, explanation, corrective_context.

Score: `statistical_integrity_score` (0.0–1.0, where 1.0 = good).

### 4. Selective Quotation

Are quotes taken out of context? For each quotation: quoted_text, attributed_to, verdict (faithful/truncated/reversed/fabricated/unverifiable), severity, explanation.

Score: `quotation_integrity_score` (0.0–1.0, where 1.0 = good).

### 5. Authority Laundering

Does the citation chain inflate low-authority sources? Look for chains where blogs/social posts get cited by progressively larger outlets without new evidence.

Score: `laundering_score` (0.0–1.0, where 0 = clean).

## Rhetorical Fallacies

16 fallacy types with definitions:

**bait_and_pivot**: Article states a fact then immediately pivots with "but/however/yet" to an opinion that contradicts the fact. Example: "Crime fell 5% this quarter, but the president still condones violence."

**appeal_to_authority**: Invoking credentials or unnamed experts to override data. Example: "The Fed says inflation is down, but in my 30 years in finance, I know it will bounce back."

**false_cause**: Attributing causation without evidence. Example: "Unemployment dropped, despite the government's disastrous policies."

**strawman**: Misrepresenting a position to attack it. Example: "Supporters of the new law want to destroy small business" when the law is about tax brackets.

**anecdote_over_data**: Single story overriding statistics. Example: "GDP grew 3%, but I talked to Maria who lost her job."

**loaded_language**: Emotionally charged words beyond what facts support. Example: "The regime's GDP figures" instead of "government GDP data."

**false_dilemma**: Only two options when more exist.

**slippery_slope**: One event leads to extreme consequences without evidence.

**ad_hominem**: Attacking the data source rather than the data.

**cherry_picking**: Selectively presenting data that supports a narrative while ignoring contradicting data the article itself mentions.

**equivocation**: Same term with different meanings in different parts, creating false consistency. (Schopenhauer #2)

**odious_categorization**: Dismissing a position by assigning a negative label rather than engaging with substance. Labels like "extremist", "denialist", "radical" without addressing arguments. (Schopenhauer #32)

**twisted_conclusion**: Data points toward conclusion X, but article draws conclusion Y without justification. (Schopenhauer #9)

**paradox_framing**: Framing a claim so rejection appears absurd or immoral, even when counter-arguments exist. (Schopenhauer #13)

**false_admission**: Treating an unproven claim as established fact later in the same article. Initially "alleged", later referenced as confirmed. (Schopenhauer #11)

**faulty_proof_exploitation**: Attacking one weak argument to dismiss an entire position, ignoring stronger arguments. (Schopenhauer #37)

Severity guide:
- **high**: directly contradicts a high-confidence claim to push a false narrative
- **medium**: subtly reframes factual data through rhetorical devices
- **low**: mild framing bias that doesn't fundamentally mislead

`narrative_bias_score` (0.0–1.0): 0 = straight reporting, 1 = entirely rhetorical manipulation.

## Contextual Gaps

Nine omission patterns to look for:

1. **Scope mismatch**: citing studies from one context to justify conclusions about another without acknowledging differences
2. **Missing counter-evidence**: omitting well-known facts that complicate the conclusion
3. **Theoretical vs practical**: presenting theory as directly applicable, ignoring implementation realities
4. **Distributional blindness**: discussing aggregate effects while ignoring who bears costs
5. **Causal chain gaps**: assuming A→C when the real chain A→B→C has B broken in context
6. **Historical amnesia**: predicting outcomes while ignoring that same conditions existed before without the predicted outcome
7. **Reversal framing**: presenting a partial rollback of a negative action as a positive action (a tax was raised then partially cut — reporting only the cut is propaganda by omission)
8. **Benefit pass-through**: claiming a policy benefits consumers without evidence the benefit reaches them (tax cuts on imports don't automatically mean lower retail prices)
9. **Selective attribution**: attributing a positive outcome to a specific actor when external factors may be responsible

`completeness_score` (0.0–1.0):
- 1.0 = addresses all relevant context (rare)
- 0.7+ = minor gaps that don't undermine conclusion
- 0.4–0.7 = significant gaps that weaken argument
- <0.4 = critical context missing that could reverse conclusion

## Emotional Manipulation

Key principle: **emotion is not manipulation**. Manipulation requires emotional appeals that SUBSTITUTE for evidence, not emotional language that ACCOMPANIES evidence.

| Pattern | Manipulation? |
|---------|--------------|
| High emotion + high evidence | No — passionate journalism |
| High emotion + low evidence + deception | Yes — manipulation |
| Low emotion + high evidence | No — dispassionate reporting |
| Low emotion + low evidence | No — lazy reporting |

Only score `manipulation_score` above 0.5 when there's a clear pattern of emotion compensating for missing evidence or amplifying deception.

Scores: `emotional_temperature` (0–1), `evidence_density` (0–1, higher = more evidence-based), `manipulation_score` (0–1).

## Summary

Rating guide:
- **strong**: Well-sourced claims, relevant context addressed, no significant deception. Minor imperfections acceptable.
- **mixed**: Some claims supported but notable gaps or moderate deception signals. Not deliberately misleading but has shortcomings.
- **weak**: Deliberate manipulation detected — major omissions designed to mislead, systematic misrepresentation, coordinated campaign, or multiple high-severity deception signals. Reserve for genuinely problematic articles.
- **insufficient**: Not enough evidence to assess.

DO NOT rate "weak" just because several analyzers found minor issues. A score of 0.2 from five analyzers does not equal one score of 1.0 — it means normal imperfections. Rate "weak" only with clear evidence of intentional manipulation.
