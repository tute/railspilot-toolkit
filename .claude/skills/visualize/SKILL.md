---
name: visualize
description: Creates a Mermaid diagram showing data lineage, architecture, or flow. Use when asked to visualize, diagram, or map data flow, show relationships between models, explain how a feature works visually, or understand system architecture. Also use when the user says "draw", "chart", or "show me how X connects to Y".
---

Create a Mermaid diagram that visualizes the requested aspect of the codebase. The
diagram should help the user understand relationships, flows, or architecture at a
glance — something that's hard to see by reading code alone.

## Workflow

1. **Understand the request** — what does the user want to see? Common cases:
   - Data lineage: how data flows through models, services, and controllers
   - Architecture: how components relate (models, services, jobs, controllers)
   - Request flow: how a user action travels through the stack
   - Model relationships: ActiveRecord associations and their cardinality
   - State machines: status transitions for a model

2. **Read the relevant code** — don't guess. Read models, services, controllers,
   and routes to understand the actual relationships. Use Grep and Glob to find
   all relevant files.

3. **Choose the right diagram type**:
   - `erDiagram` — model relationships and associations
   - `flowchart TD` — request flows, data pipelines, decision trees
   - `sequenceDiagram` — multi-step interactions between components
   - `stateDiagram-v2` — status/state transitions
   - `classDiagram` — service object hierarchies and interfaces

4. **Generate the diagram** — output it as a fenced Mermaid code block:
   ```mermaid
   flowchart TD
     A[Controller] --> B[Service]
     B --> C[Model]
   ```

5. **Explain the diagram** — add a brief summary (2-3 sentences) highlighting
   the key insight the diagram reveals. Call out anything surprising or
   noteworthy.

## Style guidelines

- Keep diagrams focused: 5-15 nodes is ideal. Split into multiple diagrams if
  larger.
- Label edges with the method or action that connects nodes.
- Use meaningful node names from the actual codebase (class names, method names).
- Group related nodes with subgraphs when it improves readability.
- For Rails apps, use the convention: Controllers → Services → Models → Database.
