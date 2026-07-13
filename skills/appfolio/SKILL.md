---
name: appfolio
description: Use when integrating AppFolio - pulling AppFolio custom reports or the AppFolio Reporting/Data API (units, residents, occupancy, rent roll, the "fish" export) and loading them into SQL Server. Owner work tool (1st Lake property data). COMPARING an AppFolio export against another dataset cell-by-cell is reconciliation and lives in the work repo's project-scoped fish-compare skill - do not reimplement it here.
---

# appfolio

General AppFolio integration: authenticate, pull a custom report, validate, load. AppFolio is
an external untrusted source: validate before the DB, keep report names / column maps in the
project lane, secrets as `op://` refs. Compose **etl-pipeline-build** for the load.
Conventions: [`tool/appfolio`](../../rules/modules/tool/appfolio.md),
[`coding/input-validation`](../../rules/modules/coding/input-validation.md),
[`global/secrets-as-references`](../../rules/global/secrets-as-references.md).

## Scope boundary (important)

- **This skill** = getting AppFolio data OUT and INTO SQL Server reliably.
- **Reconciliation** (diffing a Baseline "fish" export against a `units_/residents_/occupancy_`
  Test file cell-by-cell) = the **fish-compare** skill, project-scoped in the 1st Lake work
  repo (not in schnapp-os). Point there; never duplicate that logic.

## API shape (Reporting / Data API)

- AppFolio custom reports are exposed at a per-database endpoint, typically
  `https://<client>.appfolio.com/api/v2/reports/<report_name>.json`, HTTP Basic auth with an
  **API client id + secret** (both `op://` refs).
- A report is parameterized (date range, property group, paginated). Responses are JSON
  (or CSV); column order and presence can drift between runs.
- Common report families: `unit_*`, `resident_*`, `occupancy_*`, rent roll, the consolidated
  "fish" export used as the reconciliation Baseline.

## Pull a paginated custom report

```python
import os, requests
from requests.auth import HTTPBasicAuth

AUTH = HTTPBasicAuth(os.environ["APPFOLIO_CLIENT_ID"],       # op:// at runtime
                     os.environ["APPFOLIO_CLIENT_SECRET"])

def pull_report(client: str, report: str, params: dict) -> list[dict]:
    url = f"https://{client}.appfolio.com/api/v2/reports/{report}.json"
    rows, page = [], None
    while True:
        q = dict(params, **({"page": page} if page else {}))
        r = requests.get(url, params=q, auth=AUTH, timeout=60)
        r.raise_for_status()                       # fail loud
        body = r.json()
        rows.extend(body.get("results", body if isinstance(body, list) else []))
        page = body.get("next_page") if isinstance(body, dict) else None
        if not page:
            break
    return rows
```

## Guardrails

- **Column drift**: never index report rows by position; map by header name and validate the
  expected columns exist before loading (input-validation). A renamed/missing column should
  reject the batch, not silently shift data.
- **Untrusted external data**: validate types and row counts at the boundary; AppFolio is a
  vendor system, not a trusted internal source.
- **Report names / property groups are config** → project lane, not hardcoded.
- **Don't rebuild fish-compare**: any "does Test match Baseline" need routes to that skill.
