---
name: frontend
description: Applies distinctive frontend design principles (typography, color, motion, layout) to avoid generic AI aesthetics. Use when building or improving UI, creating landing pages, styling components, or working on any visual frontend task. Also use when the user says "make it look good", "improve the design", or "style this".
---

You tend to converge toward generic, "on distribution" outputs. In frontend
design, this creates what users call the "AI slop" aesthetic. Avoid this: make
creative, distinctive frontends that surprise and delight.

## Workflow

1. **Understand the context** before writing any CSS or markup. What's the
   product? Who uses it? What mood should the UI convey? A financial dashboard
   feels different from a creative portfolio.

2. **Make deliberate aesthetic choices** — pick a direction and commit to it:
   - Choose a font pairing (heading + body) that has personality
   - Define a color palette with 1 dominant color and 1-2 sharp accents
   - Decide on light vs dark theme based on context (not habit)
   - Set the overall mood: minimal, bold, warm, technical, playful, etc.

3. **Build with progressive enhancement** — the page works without JavaScript.
   Stimulus.js enhances interactions when available. Semantic HTML first, then
   style.

4. **Prioritize accessibility** — semantic HTML elements, proper labels, ARIA
   attributes when needed, keyboard navigation, sufficient contrast ratios.

## Design principles

**Typography**: Choose fonts that are beautiful and distinctive. Avoid generic
fonts like Arial, Inter, Roboto, and system fonts. Vary your choices across
projects — if you've been reaching for Space Grotesk, try something else.

**Color & Theme**: Commit to a cohesive aesthetic. Use CSS variables for
consistency. A dominant color with sharp accents outperforms a timid,
evenly-distributed palette. Draw from IDE themes, cultural aesthetics, and
the product's domain for inspiration. Avoid purple gradients on white.

**Motion**: Focus on high-impact moments — one well-orchestrated page load with
staggered reveals (animation-delay) creates more delight than scattered
micro-interactions. Prioritize CSS-only solutions. Use the Motion library for
React when available.

**Backgrounds**: Create atmosphere and depth rather than defaulting to solid
colors. Layer CSS gradients, use geometric patterns, or add contextual effects
that reinforce the overall aesthetic.

**Layout**: Break out of predictable grid patterns. Consider asymmetry, generous
whitespace, and unexpected element placement. The layout should feel intentional,
not templated.

## What to avoid

- Overused font families (Inter, Roboto, Arial, Space Grotesk, system defaults)
- Clichéd color schemes (purple gradients, blue-and-white SaaS look)
- Predictable layouts and component patterns
- Cookie-cutter design that lacks context-specific character
- Converging on the same choices across different projects
