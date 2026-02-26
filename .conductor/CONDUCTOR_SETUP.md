# Conductor Setup Instructions

## File locations

```
repo-root/
├── conductor.json          # Conductor reads this automatically
└── bin/
    ├── setup-conductor     # workspace provisioning script
    └── archive-conductor   # workspace teardown script
```

## Conductor settings

`conductor.json` defines three script hooks that Conductor calls
automatically. **No manual configuration is needed in the Conductor UI**
as long as `conductor.json` is committed to the branch being used.

If you need to set them manually in the UI (**Repository Settings → Scripts**):

- **Setup:** `bin/setup-conductor`
- **Run:** `PORT=${CONDUCTOR_PORT:-3000} bin/rails server`
- **Archive:** `bin/archive-conductor`

## Source-of-truth behavior

- Conductor reads `conductor.json` from the checked-out branch.
- If workspace creation tracks `origin/<branch>`, local-only commits
  are ignored — push first.
- `bin/setup-conductor` must exist in the branch commit Conductor
  checks out.
