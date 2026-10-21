<!-- gitnexus:start -->
<!-- gitnexus:keep -->

# GitNexus — Code Intelligence

Indexed as **nix-config** — use the GitNexus MCP tools to understand code, assess impact, and navigate safely.

> Index stale? Run `gitnexus analyze` from the project root — the binary is Nix-installed via home-manager (`modules/hm/ai/gitnexus`, on PATH at `~/.nix-profile/bin/gitnexus`). Do not use `npx`/`pnpm dlx`/`bunx`/`node .gitnexus/run.cjs`.
>
> This block is hand-maintained (`gitnexus:keep`): `analyze` only refreshes the "Indexed as" line. Port template changes by hand when bumping gitnexus.

## Always Do

- **MUST run impact analysis before editing any symbol.** Use `impact({target: "symbolName", direction: "upstream"})` (MCP) or `gitnexus impact "symbolName" --direction upstream --repo .` (CLI fallback) and report the blast radius (direct callers, affected processes, risk level) to the user.
- **MUST run graph change analysis before committing.** Use `detect_changes({scope: "all"})` (MCP) or `gitnexus detect-changes --scope all --repo .` (CLI fallback). `partial: true` or `truncated: true` is not a clean check — a zero means unseen, not unaffected; re-run it. For regression review, compare against the default branch: `detect_changes({scope: "compare", base_ref: "main"})`.
- **MUST warn the user** if impact analysis returns HIGH or CRITICAL risk before proceeding with edits. Never use `riskSharedAxes` to waive a HIGH/CRITICAL `risk`.
- **MUST treat `risk: UNKNOWN` as unresolved, not as low.** An empty caller set can mean the callers aren't resolvable by the index (Nix attrset/option access, dynamic dispatch, cross-language calls) — `impact` pairs `UNKNOWN` with a `riskNote` saying so. Confirm with a text search before treating the symbol as safe to change or delete.
- **Graph first for read-only questions.** Use `query({search_query: "concept"})` for concepts/flows, `context({name: "symbolName"})` for a named symbol's callers, callees, and flows, or `impact` for blast radius. Fall back to text search only for empty/`UNKNOWN` results or literals.
- For security review, `explain({target: "fileOrSymbol"})` lists taint findings (source→sink flows; needs `analyze --pdg`).

## Never Do

- NEVER edit a function, class, or method without first running `impact` on it.
- NEVER ignore HIGH or CRITICAL risk warnings from impact analysis, and never read `UNKNOWN` as an all-clear.
- NEVER rename symbols with find-and-replace — use `rename` which understands the call graph.
- NEVER commit changes without running `detect_changes()` to check affected scope.

## Resources

| Resource                                    | Use for                                  |
| ------------------------------------------- | ---------------------------------------- |
| `gitnexus://repo/nix-config/context`        | Codebase overview, check index freshness |
| `gitnexus://repo/nix-config/clusters`       | All functional areas                     |
| `gitnexus://repo/nix-config/processes`      | All execution flows                      |
| `gitnexus://repo/nix-config/process/{name}` | Step-by-step execution trace             |

## CLI

| Task                                         | Read this skill file                                         |
| -------------------------------------------- | ------------------------------------------------------------ |
| Understand architecture / "How does X work?" | `.claude/skills/gitnexus-exploring/SKILL.md`                 |
| Blast radius / "What breaks if I change X?"  | `.claude/skills/gitnexus-impact-analysis/SKILL.md`           |
| Trace bugs / "Why is X failing?"             | `.claude/skills/gitnexus-debugging/SKILL.md`                 |
| Rename / extract / split / refactor          | `.claude/skills/gitnexus-refactoring/SKILL.md`               |
| Tools, resources, schema reference           | `.claude/skills/gitnexus-guide/SKILL.md`                     |
| Index, status, clean, wiki CLI commands      | `.claude/skills/gitnexus-cli/SKILL.md`                       |
| Control/data dependence, "what guards X?"    | `~/.claude/skills/gitnexus-pdg-query/SKILL.md` (global)      |
| Taint / source→sink findings from `explain`  | `~/.claude/skills/gitnexus-taint-analysis/SKILL.md` (global) |

<!-- gitnexus:end -->
