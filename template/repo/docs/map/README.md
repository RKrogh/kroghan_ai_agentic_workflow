# System map

The canonical description of what the system is. `docs/adr/` says why; this says what.

Rule: a PR that changes structure updates the matching file here in the same PR. A diagram
that lies is worse than none.

| File | Covers | Update when |
|---|---|---|
| `01-context.md` | The system and the outside systems it talks to | A new external service |
| `02-deployment.md` | Containers, hosts, routes | Deploy topology changes, a new top-level route |
| `03-modules.md` | Projects, modules, dependencies, background jobs | A module, reference or hosted service is added or removed |
| `04-domain.md` | Entities, tables, endpoints | Entities, migrations, endpoints |
| `05-flows.md` | Key flows as sequence diagrams | A key flow changes |
| `06-states.md` | Status fields and transition rules | A state or transition changes |
| `07-adr-index.md` | One row per ADR | An ADR is added, amended or superseded |

Each file ends with a Sources section pointing at the real files. Use real type, table and
route names so diagrams stay greppable. If you use Mermaid, render it in CI so a broken
diagram fails the build.
