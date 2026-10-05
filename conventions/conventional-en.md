# Convention: Conventional Commits (English)

Language: **English**.

## Format

```
<type>(<optional scope>): <summary>

<optional body>
```

## Rules

- `type` is one of: `feat`, `fix`, `refactor`, `perf`, `docs`, `style`, `test`, `build`, `ci`, `chore`, `revert`.
- `scope`: main module or folder touched, lowercase (e.g. `player`, `ui`, `build`).
- Summary: imperative mood, lowercase start, no trailing period, 72 characters max.
  Example: `feat(inventory): add sorting by rarity`.
- Body (only when useful): after a blank line, explains *why*, 72-character lines, `-` bullets allowed.
- Breaking change: `!` after the type (`feat!: …`) and a `BREAKING CHANGE: …` line at the end of the body.
- One commit = one logical change. If changes mix several topics, use the type of the main change.
