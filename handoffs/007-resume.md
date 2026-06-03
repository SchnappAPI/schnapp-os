# Handoff 007 — master resume (supersedes 006). Tracker + all docs current.

Date: 2026-06-03.

## State
- **Parts 0, 1, 2 DONE**; **Part 3** done except 3.4 (verify). **Part 4**: 4.1 done, 4.3 done,
  **4.2 `[~]`** (built + `npm run verify` PASS; deploy owner-gated). **Part 5**: 5.1, 5.2 done;
  5.5 `[~]`; 5.3/5.4 → Part 7; 5.6 → next-session.
- GitHub PAT widened to all repos; Actions secret set on af-invoice-parser + af-query-api.
- README de-staled (no hardcoded status; points to PLAN/PROGRESS + a Map). `keep-tracker-current`
  rule now also covers ALL docs ("Doc currency" in global/anti-stale.md): no doc hardcodes a
  mutable fact, every state-changing commit updates affected docs + pushes immediately.

## Part 4.2 holdup (answer to "what's the hold up; can it be completed?")
Connector is fully built + locally verified. It CANNOT be finished autonomously because:
1. **Deploy needs a cloud Node-host account.** No host CLI is installed on the Mac
   (flyctl/wrangler/railway/render/doctl all absent), and any deploy needs the owner's account
   login (interactive/browser) — I have no host credentials. Deploying on the Mac itself would
   defeat the off-Mac requirement.
2. **claude.ai registration** needs the owner's claude.ai Settings UI + a choice of auth front
   (Cloudflare Access vs OAuth wrapper).
3. **4.4 verify** needs the Mac OFF + claude.ai — owner.

To finish 4.2, owner does (once): install flyctl (`brew install flyctl`), `fly auth login`, then
from `connectors/op-mcp/`: `fly launch --no-deploy --copy-config`,
`fly secrets set OP_SERVICE_ACCOUNT_TOKEN=... CONNECTOR_AUTH_TOKEN=$(openssl rand -hex 32)`,
`fly deploy`, confirm `GET /health`. Then register `https://<app>.fly.dev/mcp` in claude.ai. I can
prep a turnkey deploy script and install flyctl if you want me to go that far.

## Remaining — three buckets
- **Next-session verifies** (need fresh session + the trust dialog accepted): 2.4 global lane loads
  in another repo, 3.4 path-scoped non-leak, 5.6 cross-repo + supersede, live 0.3/1.5/2.2/5.1.
- **Owner-gated**: 4.2 deploy + register → 4.4; decide whether DB_Storage +
  appfolio-marketing-project should get the SA Actions secret (not auto-set).
- **Buildable next, in order**: Part 6 (Obsidian/OneDrive — needs your app config), Part 7
  (hooks need per-hook approval; skills buildable; wires 5.3/5.4 + surface-check), then 8, 9
  (incl. 9.3 CI freshness, 9.5 install checklist), 10 (closes 2.4/3.4/4.4/5.6), 11.

## Working norms (owner)
Direct/terse, no fluff, no em dashes, lead with recommendation. Never guess — verify first.
Strict IN-ORDER completion; do not skip. Self-config (~/.claude, settings.json hooks) and any
distribution of secrets need explicit owner approval — the classifier gates it; present the exact
change and ask. caveman mode active (normal prose for code/commits/security).

## Gotchas
- ~/.claude/CLAUDE.md lives outside the repo; capture its content in the README install checklist (9.5).
- connectors/op-mcp/ node_modules + dist gitignored; `npm install` before `npm run verify`.
- settings.json backup: `~/.claude/settings.json.bak-20260603-144320`.

## Resume prompt (paste into a fresh session)
"Resume claude-kit. Working dir ~/code/claude-kit. Read PLAN.md, PROGRESS.md, and
handoffs/007-resume.md first — the tracker and all docs are current. Continue strict IN-ORDER on
unchecked work: the next buildable parts are 6 (Obsidian/OneDrive backup mirror) then 7 (hooks +
skills + surface-check, which also wires 5.3/5.4). 2.4/3.4/5.6 are next-session verifications
(confirm the global lane + path-scoped rules load now that ~/.claude/CLAUDE.md is wired); 4.2
deploy + 4.4 are owner-gated. Apply keep-tracker-current: every state-changing commit flips the
PLAN box + a PROGRESS line and is pushed immediately; no doc hardcodes a mutable fact. Get explicit
owner approval before any ~/.claude / settings.json hook change or any secret distribution. Act
autonomously; handoff at each part boundary."
