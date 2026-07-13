---
name: quickbase
description: Use when integrating Quickbase - calling the Quickbase JSON RESTful API (query/insert/update records), handling app IDs / table IDs (DBIDs) / numeric field IDs (FIDs), paginating large result sets, respecting rate limits, or loading Quickbase data into SQL Server. Owner work tool (1st Lake).
---

# quickbase

General Quickbase integration. Quickbase is an external, untrusted data source: validate
before the DB, keep all IDs in the project lane, secrets as `op://` refs. For loading the
pulled data, compose the **etl-pipeline-build** skill. Conventions:
[`tool/quickbase`](../../rules/modules/tool/quickbase.md),
[`coding/input-validation`](../../rules/modules/coding/input-validation.md),
[`global/secrets-as-references`](../../rules/global/secrets-as-references.md).

## API shape (JSON RESTful API v1)

- Base: `https://api.quickbase.com/v1`. Auth header: `Authorization: QB-USER-TOKEN <token>`
  (user token, an `op://` ref) plus `QB-Realm-Hostname: <realm>.quickbase.com`.
- Identifiers are opaque and brittle: **app ID**, **table ID (DBID)**, and numeric
  **field IDs (FIDs)**: `3` is always Record ID#. Map FID→meaning in the project lane,
  never by guessing.
- Records query is a POST to `/records/query` with a JSON body, not a GET with query string.

## Query records (paginated)

```python
import os, requests

HEADERS = {
    "Authorization": f"QB-USER-TOKEN {os.environ['QUICKBASE_USER_TOKEN']}",  # op:// at runtime
    "QB-Realm-Hostname": os.environ["QUICKBASE_REALM"],
    "Content-Type": "application/json",
}

def query_all(table_id: str, select: list[int], where: str = "") -> list[dict]:
    rows, skip = [], 0
    while True:
        body = {"from": table_id, "select": select, "options": {"skip": skip, "top": 1000}}
        if where:
            body["where"] = where            # Quickbase query language, e.g. "{6.GT.0}"
        r = requests.post("https://api.quickbase.com/v1/records/query",
                          json=body, headers=HEADERS, timeout=30)
        r.raise_for_status()                  # fail loud on non-2xx
        data = r.json()
        rows.extend(data["data"])
        if skip + len(data["data"]) >= data["metadata"]["totalRecords"]:
            break
        skip += len(data["data"])
    return rows                               # each cell is {"value": ...} keyed by FID-as-string
```

## Guardrails

- **Rate limits**: ~10 req/s and a per-account daily cap; batch with `top` up to 1000, back
  off on HTTP 429 (honor `Retry-After`).
- **Untrusted shape**: every cell is `{"value": ...}` keyed by the FID string; validate
  presence and type before mapping into typed columns (input-validation).
- **IDs are config, not code**: app/table/field IDs live in the project lane / a config file,
  never hardcoded across modules - they differ per app and change.
- **Writes**: `/records` POST upserts by including FID `3` (Record ID#) to update, omit to
  insert. Treat as the same idempotency discipline as any ETL write.
