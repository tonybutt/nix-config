# Global Claude Instructions

## Git Commits

### Commit Message Format

Follow the conventional commits format from my git commit template:

```
<type>(<scope>): <description>
```

- Subject line: max 50 chars, imperative mood ("add" not "added"), capitalize after type, no period at end
- Body (after blank line): wrap at 72 chars, explain WHAT and WHY (not HOW)

**Types:** `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`

**Breaking changes:** Add `!` after type/scope (e.g. `feat!:`) or add `BREAKING CHANGE:` in footer

**Linear references:** `Fixes GRA-123`, `Closes GRA-456`, `Ref GRA-123`

### No Claude Co-Authoring

Never add Claude co-author lines to commits. Do not append `Co-Authored-By: Claude` or any `Co-Authored-By: claude` / `noreply@anthropic.com` trailer to commit messages.
