---
module: lang/typescript
paths:
  - "**/*.{ts,tsx,js,jsx,mjs,cjs}"
updated: 2026-06-03
---
# JavaScript / TypeScript naming

| Element | Convention | Example |
|---|---|---|
| Variables, functions | camelCase | gameCount, fetchPlayerProps() |
| Booleans | camelCase with is/has/should/can | isValid, hasOdds |
| Constants (fixed values) | UPPER_SNAKE_CASE | MAX_RETRIES |
| Classes, types, interfaces, enums | PascalCase | OddsLoader, ApiResponse |
| React components | PascalCase | FishPanel |
| React hooks | camelCase with `use` prefix | useFishSync |
| Non-component files | kebab-case | fish-sync.js |
| React component files | PascalCase matching component | FishPanel.jsx |
| Test files | `.test`/`.spec` suffix | fish-sync.test.js |

kebab-case files + PascalCase component files is the dominant React split. If you ever
prefer one scheme everywhere, kebab-case for all files is the simpler fallback. These rules
apply only inside JS/TS files; they must never leak into Python.
