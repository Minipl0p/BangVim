# Norme : Conventional Commits (français)

Langue : **français**.

## Format

```
<type>(<portée facultative>): <résumé>

<corps facultatif>
```

## Règles

- `type` parmi : `feat` (fonctionnalité), `fix` (correction), `refactor`, `perf`, `docs`,
  `style` (mise en forme sans effet), `test`, `build`, `ci`, `chore` (maintenance), `revert`.
- `portée` : module ou dossier principal touché, en minuscules (ex. `player`, `ui`, `build`).
- Résumé : impératif présent, minuscule au début, sans point final, 72 caractères maximum.
  Exemple : `feat(inventaire): ajoute le tri par rareté`.
- Corps (seulement si utile) : séparé par une ligne vide, explique le *pourquoi*,
  lignes de 72 caractères maximum, puces `-` autorisées.
- Changement cassant : `!` après le type (`feat!: …`) et une ligne `BREAKING CHANGE: …` en fin de corps.
- Un seul commit = un seul changement logique. Si les modifications mélangent plusieurs sujets,
  choisis le type du changement principal.
