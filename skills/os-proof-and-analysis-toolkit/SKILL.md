---
name: os-proof-and-analysis-toolkit
description: Use when a claim about schnapp-os needs PROOF instead of trust - "is this token actually malformed", "does that surface really read the rules live", "which of two theories explains this failure", "an audit/subagent says X, do we believe it", "what will this skill cost in context", "which files keep breaking", "does the alert path actually fire", "has this mistake happened before / does it deserve a gate". Eight first-principles analysis recipes (byte forensics, live probes, discriminating experiments, adversarial re-verification, context-cost accounting, git drift archaeology, failure injection, recurrence analysis), each with exact commands and a worked example from this repo's own history.
---

# os-proof-and-analysis-toolkit

Eight recipes for turning "I think" into "I verified", each battle-tested in this repo's history.
The common doctrine is the global rule [rules/global/verify-before-asserting.md](../../rules/global/verify-before-asserting.md):
recalled memory and docs are point-in-time; evidence is current. Pick the recipe that matches the
question, run the commands, cite the output.

Paths are this machine's clones (`/Users/schnapp/code/schnapp-os`, `/Users/schnapp/code/schnapp-vault`);
on another machine substitute its clone paths. "ADR" = an architecture decision record under
`decisions/`; "vault memory" = fact files under `/Users/schnapp/code/schnapp-vault/memory/`.

## When NOT to use

- Symptom-in, diagnosis-out triage for a KNOWN failure mode: [os-debugging-playbook](../os-debugging-playbook/SKILL.md). This skill is for building NEW evidence when no known mode fits.
- "Was this already fought and settled": [os-failure-archaeology](../os-failure-archaeology/SKILL.md).
- System-wide health snapshot: [status](../status/SKILL.md). What is loaded here: [surface-check](../surface-check/SKILL.md).
- How to land the fix once proven: [os-change-control](../os-change-control/SKILL.md).
- Verifying a script or gate end to end before shipping: [os-validation-and-qa](../os-validation-and-qa/SKILL.md).
- Full context-budget audit (this skill only summarizes the measuring step): [context-budget](../context-budget/SKILL.md).

## Recipe index

| # | Recipe | Question it answers | Worked example |
|---|---|---|---|
| 1 | Byte-level artifact verification | Is the stored VALUE what everyone assumes it is? | ADR 0019 |
| 2 | Live-probe over doc-trust | Does the surface/connector actually behave as documented? | 2026-07-07 probe |
| 3 | Discriminating experiment design | Which of two theories is true? | ADR 0034 |
| 4 | Adversarial re-verification | Is a subagent/audit finding real? | handoff 054 |
| 5 | Context-cost accounting | What does this component cost per turn? | context-budget method |
| 6 | Drift archaeology via git | Where does this repo keep breaking? | freshness-gate churn |
| 7 | Failure-injection testing | Does the alert path fire when things break? | simulate=down |
| 8 | Recurrence-based escalation | Does this lesson deserve a gate? | ADR 0026 |

## 1. Byte-level artifact verification

**When:** a stored secret 401s, a config value "looks right" but misbehaves, or any artifact is
consumed verbatim by a machine and rejected. Normal output (logs, `echo`, `op read`) renders
wrapping whitespace and quotes invisibly, so the eye clears a value the API rejects.

**Commands** (never print the full secret; first bytes only):

```bash
# First 4 bytes as hex. A clean token starts with its own chars (73='s'); 20=space, 27='.
op read "op://vault/item/field" | head -c4 | xxd -p
# Byte length vs expected (ADR 0019: 111 raw vs 108 clean exposed the wrap).
op read "op://vault/item/field" | wc -c
# Whole-file forensics for non-secret artifacts (BOM, CRLF, trailing junk):
xxd path/to/file | head -5; tail -c 16 path/to/file | xxd
# Automated gate form (exit 0 clean / 1 malformed / 2 cannot check; prints a category, never bytes):
bash /Users/schnapp/code/schnapp-os/scripts/check-secret-bytes.sh --ref "op://vault/item/field" --min-len 100
```

**Reading results:** leading `20`/`27`/`22` hex = space/quote wrapping; trailing `0a` = newline the
consumer will send. Any of these means the VALUE is the defect: re-store the bare value, do not
rotate, do not blame the tool.

**Worked example:** [decisions/0019](../../decisions/0019-learning-worker-subscription-auth.md).
A valid subscription OAuth token stored as `␣'sk-ant-oat…'` 401'd for days; the CLI version was
blamed and billing was wrongly switched to the metered API. Raw bytes (111 vs 108) ended the
misdiagnosis in minutes. The lesson is institutionalized as `scripts/check-secret-bytes.sh` and
vault memory `malformed-stored-secret-401.md`.

## 2. Live-probe over doc-trust

**When:** deciding anything that depends on how a surface or connector behaves right now:
"does claude.ai read the rules live", "is the write path working", "is that endpoint up". Docs and
memory record what WAS true; a probe records what IS.

**Method:**
1. State the claim as a testable prediction ("a bare claude.ai chat, asked to quote
   `rules/global/working-style.md`, returns the current file content").
2. Run it on the real surface, not a proxy for it. Include the least-configured context you can
   (the 2026-07-07 probe used a bare chat with nothing toggled, a Project, and a fresh Cowork chat).
3. Compare against ground truth you fetched independently (the file at HEAD).
4. Record the result WITH a probe date, in the fact's canonical home, e.g. "probe-confirmed
   2026-07-07" in the vault memory `source:` field. An undated probe result becomes doc-trust for
   the next reader.

**Reading results:** a probe proves the behavior at probe time only. When acting on a
probe-confirmed fact much later, weigh re-probing; the recorded date is what makes that judgment
possible.

**Worked example:** vault memory `surfaces-live-read-default.md` (as of 2026-07-17). Three
contexts probed 2026-07-07 all quoted real file content, proving hookless surfaces read
`rules/global` live through the portal connector. That single probe killed an entire planned
subsystem (the auto-synthesis daemon that would have kept a distilled copy in sync) and reduced the
cross-surface consistency problem to "monitor connector health".

## 3. Discriminating experiment design

**When:** two or more theories explain a symptom and debugging by intuition is looping. Design one
change per run and write the predicted output BEFORE running: if you cannot say what each theory
predicts, the experiment does not discriminate.

**Method:**
1. List the candidate causes.
2. For each pair, find an input whose output DIFFERS between them.
3. Write down the prediction per theory, then run.
4. Include a control: a case where you know the answer, to prove the harness itself works.

ADR 0019's evidence section is the template: control (deliberately invalid token) → 401 proves the
401 is what a bad value looks like; cleaned token → ok isolates the value as the cause; exact
resolution replayed in a launchd-equivalent env → ok rules out the environment. Three runs, one
variable each, cause pinned.

**Worked example (instrumenting when you cannot experiment):**
[decisions/0034](../../decisions/0034-self-identifying-mcp-responses.md). One mac-mcp `shell_exec`
call returned another command's stdout. The origin server was ruled out by code reading (no shared
output state, per-call transport sessions in `mcp.err.log`), which located the fault upstream in the
Cloudflare portal layer: unpatchable, and a one-off, so no reproducing experiment exists. The
response: make every future occurrence self-discriminating. Every response now echoes the caller's
own `command`/`query` plus a server-generated `call_id` and `ts`; an echo mismatch IS the
misdelivery detection, and the `call_id` traces to the real input in the Mac's `mcp.err.log`. When
you cannot run the experiment, build the discriminator into the artifact and let the next
occurrence run it for you. Note the honest residual recorded in the ADR: the edge's real response
deadline was NOT measured (labeled as such), because measuring meant uncapping a live service.

## 4. Adversarial re-verification of subagent and audit claims

**When:** a subagent, parallel audit, review agent, or older doc reports a finding you are about to
act on. Findings are hypotheses, not facts: subagents work from partial context and misread
outputs.

**Method:** before acting on any finding, re-derive it from primary evidence yourself:
- A "service not running" claim: read the raw `launchctl list gui/$(id -u)/<label>` output yourself; a
  listed label with exit status 0 or a live PID is loaded.
- A "config misses X" claim: open the config and grep for X.
- A "file is stale" claim: `git log -1 --format='%ci %h' -- <file>` and compare against the source it tracks.
Act only on findings that survive; record the disproved ones so the next session does not re-chase
them.

**Reading results:** a disproved claim is itself a capture: it usually reveals a misreadable output
or an ambiguous doc worth fixing (fix the class, per
[rules/global/anti-stale.md](../../rules/global/anti-stale.md)).

**Worked example:** [handoffs/054](../../handoffs/054-agentic-os-optimize-pass.md). A four-audit
sweep produced two wrong findings, both discarded only after live verification: "3 LaunchAgents not
loaded" (a misread of `launchctl list`; one agent had a live PID mid-audit) and "infra-health
misses agents" (`EXPECTED_AGENTS` already listed them). Acting on either would have "fixed"
working infrastructure. Same session, the owner-block failure recorded in 054 shows the inverse: an
unverified `gh --body-file` flag and an unverified op item name failed at the owner's terminal
(verify-before-asserting applies to your own claims too).

## 5. Context-cost accounting

**When:** before adding any always-loaded component (global rule, CLAUDE.md line, skill
description, MCP server): the always-on layer is re-sent EVERY turn, so it pays its cost per turn,
not once. Full method: [context-budget](../context-budget/SKILL.md); this recipe is the measuring
step.

**Commands:**

```bash
# Token estimate for prose (words x 1.3):
awk '{w+=NF} END{printf "%d words ~%d tokens\n", w, w*1.3}' /Users/schnapp/code/schnapp-os/rules/global/*.md
# Per-file, to find the heaviest lever:
for f in /Users/schnapp/code/schnapp-os/rules/global/*.md; do awk -v f="$f" '{w+=NF} END{printf "%6d  %s\n", w*1.3, f}' "$f"; done | sort -rn
# Code-heavy files: chars / 4 instead:
wc -c <file>   # divide by 4
```

MCP schema overhead is ~500 tokens per tool (context-budget's heuristic): a 20-tool server costs
~10k tokens before it does anything.

**Reading results:** measured 2026-07-17, `rules/global/*.md` totals ~3.8k tokens always-on.
Admission test for that layer (context-budget): fires on <80% of sessions = belongs in an on-demand
module under `rules/modules/`, not the global lane. Skills are cheap until invoked (only the
frontmatter description loads), so prefer a skill over a global rule for anything procedural.

**Worked example:** the known open item that `working-style.md` is the single heaviest always-load
file (~1.2k tokens); trimming it is an owner call on record, not a defect to fix unprompted (as of
2026-07-17).

## 6. Drift archaeology via git

**When:** deciding where hardening effort goes, whether a component is a chronic offender, or
whether "this keeps breaking" is a feeling or a fact. Git history is the repo's own incident
database.

**Commands** (run from `/Users/schnapp/code/schnapp-os`):

```bash
# Churn: which files change most (top drift candidates):
git log --pretty=format: --name-only --since=2026-06-15 | grep -v '^$' | sort | uniq -c | sort -rn | head -15
# Fix density: how much of recent history is repair work:
git log --since=2026-06-01 --pretty=%s | grep -ciE '^fix'
# Fix-cluster mining: all fixes touching one theme:
git log --oneline --grep='freshness' -i
# How many times one script needed changing:
git log --oneline -- scripts/check-freshness.sh
# Who last touched a fact and when (staleness check for any file):
git log -1 --format='%ci %h %s' -- <path>
```

**Reading results:** high churn on a TRACKER (PROGRESS.md leads every churn list by design) is
healthy; high churn on a GATE or generated doc is a smell. A fix-cluster of 3+ commits on one
component is recurrence evidence: feed it to recipe 8. Distinguish "changed often because it is the
log" from "changed often because it keeps being wrong" by reading the commit subjects.

**Worked example:** `git log --oneline -- scripts/check-freshness.sh` shows 6 commits (as of
2026-07-17), and the grep-cluster on "freshness" spans mawk-vs-BSD-awk portability, a gitignore
false positive, and the git-excluded-worktree false STALE fixed in 410e819. The cluster is why the
briefing calls the freshness gate a known-fragile class: the history said so before anyone did.

## 7. Failure-injection testing

**When:** any alert, dead-man's-switch, or fallback path. An unexercised alarm is the "silent
stop" failure mode this system was built against (docs/framework.md): the SQL backup that was dead
~55 days died silently precisely because nothing ever tested its failure path.

**Pattern:** build a `simulate` input into the monitor so the ALARM PATH can be forced without a
real outage, then actually fire it once after wiring and after any change to the alert plumbing.

```bash
# Force the mac-liveness alarm path (opens the real GitHub issue, marked SIMULATED):
gh workflow run mac-liveness.yml -R SchnappAPI/schnapp-os -f simulate=down
# Same pattern exists in render-health.yml:
gh workflow run render-health.yml -R SchnappAPI/schnapp-os -f simulate=down
# Then confirm the alarm artifact appeared:
gh issue list -R SchnappAPI/schnapp-os --state open --search "[mac-liveness]"
```

**Reading results:** success = the issue opens (email fires) with the SIMULATED marker, and the
next real scheduled run auto-closes it with a "Recovered" comment. Both halves matter: an alarm
that opens but never auto-closes trains the owner to ignore it. Design notes worth copying from
`.github/workflows/mac-liveness.yml`: the simulated body says loudly it is a test, dedup reuses one
open issue instead of spamming, and the watcher runs GitHub-hosted so it is independent of the
thing it watches.

**Worked example:** `mac-liveness.yml` is itself the institutionalized lesson from the 55-day
silent backup death; `simulate=down` is how its issue/email path was proven without taking the Mac
down.

## 8. Recurrence-based escalation analysis

**When:** after any mistake, asking "does this deserve a gate (hook/CI check) or just a note?".
The full policy is [decisions/0026](../../decisions/0026-enforcement-ladder-recurrence-escalation.md);
this recipe is how to run its analysis by hand.

The ladder itself (four rungs, weak to strong) lives in `os-change-control` Doctrine 5 with
ADR 0026 as canon. Two questions decide the rung:

1. **Has the class recurred (>= 2 occurrences)?** First sighting = rung 1-2 only. Count occurrences
   with recipe 6 (fix-cluster mining), the handoffs, and the learning-capture archive. Severity is
   NOT the trigger: 0026's evidence was that frequency, not drama, predicts future cost.
2. **Is the check deterministic?** A mechanical test exists = gate it (CI-first, so hookless
   surfaces cannot route around it). A judgment rule (verify-before-asserting and kin) = never
   gate; a gate that cannot mechanically decide right-from-wrong is theatre that trains
   route-arounds.

The justified-by-THIS-evidence test before building any gate: `os-change-control` Doctrine 5.

**Automation:** the nightly learning worker already runs this analysis deterministically
(`scripts/learning-recurrence.sh` computes class signatures over the capture archive; on a fresh
recurrence it drafts a gate-proposal GitHub issue for owner approval, never auto-landing code).
Check pending proposals before hand-drafting: `gh issue list -R SchnappAPI/schnapp-os --search "learning-loop:"`.

**Worked example:** ADR 0026's own applications. Malformed-secret bytes (>= 4 occurrences,
deterministic) → the `check-secret-bytes.sh` gate. Stale-plugin-pin (>= 3) → no gate; the class was
DELETED by removing plugin packaging (decisions/0024): deleting the class beats gating it.
Tracker-currency and verify-before-asserting → judgment, stay advisory. The natural experiment
behind the whole policy: lessons that became code/hook fixes stopped recurring; lessons that stayed
prose kept recurring.

## Provenance and maintenance

Volatile claims above, with a one-line re-verification each:

| Claim (as of 2026-07-17) | Re-verify |
|---|---|
| `check-secret-bytes.sh` exists with `--ref/--min-len/--expect-prefix` and 0/1/2 exit codes | `bash /Users/schnapp/code/schnapp-os/scripts/check-secret-bytes.sh --help` |
| Live-read probe-confirmed 2026-07-07, recorded with date | `sed -n '1,12p' /Users/schnapp/code/schnapp-vault/memory/surfaces-live-read-default.md` |
| mac-mcp responses carry command echo + `call_id` + `ts`; 90s clamp | read `decisions/0034-self-identifying-mcp-responses.md`; live: send `shell_exec` and inspect the envelope |
| `rules/global/*.md` ~3.8k tokens; working-style ~1.2k | `awk '{w+=NF} END{print w*1.3}' /Users/schnapp/code/schnapp-os/rules/global/*.md` |
| `check-freshness.sh` has 6 commits of repair history | `git -C /Users/schnapp/code/schnapp-os log --oneline -- scripts/check-freshness.sh` |
| `simulate=down` input exists in mac-liveness + render-health | `grep -n simulate /Users/schnapp/code/schnapp-os/.github/workflows/mac-liveness.yml /Users/schnapp/code/schnapp-os/.github/workflows/render-health.yml` |
| `learning-recurrence.sh` drafts owner-approval gate issues, read-only | `sed -n '1,25p' /Users/schnapp/code/schnapp-os/scripts/learning-recurrence.sh` |
| Working-style trim is a deferred owner call | briefing handoff context; confirm with the owner before acting |

Unverified in this authoring pass (labeled, do not treat as fact): none of the `gh workflow run` /
`gh issue list` commands were executed live (they mutate or need network); their syntax matches the
workflows' declared inputs and standard `gh` flags.
