# Design

## Why

FG-TIDA has use cases (GitHub Issues), themes (exploratory topics), and one
working group (`wg1-ra-aai`) so far, plus an emerging need for a shared
taxonomy across all three. Today, connecting a use case to a theme, spotting
a recurring standards gap, or answering "how many use cases support WG1"
means reading every issue by hand. This register exists to make those
questions answerable without changing how use cases get submitted.

## Data flow

```
GitHub Issues (source of truth for submissions)
   -> sync_github_issues.py -> use_cases table (raw columns only)

reviewer, via review_use_case.py
   -> writes curated columns + links into the sqlite cache
   -> AND rewrites curation/mappings.yaml (source of truth for curated data,
      committed to git)

curation/mappings.yaml -> load_curation.py -> sqlite cache (curated columns + links)

sqlite cache -> export_register_csv.py -> CSV for meetings
sqlite cache -> generate_dashboard.py -> static HTML -> GitHub Pages
```

GitHub remains where anyone submits a use case. `curation/mappings.yaml` is
where reviewer decisions live durably. The sqlite file itself is a
*rebuildable cache* of those two sources — never a source of truth on its
own, and never committed.

## Raw vs. curated columns

`use_cases` holds both, but they're owned by different scripts:

- Raw (`github_issue_number`, `title`, `body`, `labels`, `state`, `author`,
  `created_at`, `updated_at`): written by `sync_github_issues.py` on every
  run, upserted by `github_issue_number`.
- Curated (`review_status`, `summary`, `review_notes`, `priority`,
  `reviewer`, `reviewed_at`): written by `review_use_case.py` (interactively)
  or `load_curation.py` (rebuilding from `curation/mappings.yaml`). A
  raw re-sync never overwrites these, so reviewer work survives issue edits.

This mirrors the handover doc's requirement that submitters aren't expected
to classify their use case correctly at submission time — that's a separate,
smaller reviewer group's job, done after the fact.

## `curation/mappings.yaml` as the durable curated-data store

The sqlite db is disposable — delete it, re-run `init_db.py` ->
`sync_github_issues.py` -> `load_curation.py`, and you get the same curated
state back, because the actual decisions live in one committed YAML file
keyed by GitHub issue number (not one file per use case — a single file
avoids unbounded file-count growth as the register scales). `review_use_case.py`
rewrites that issue's block in the file on every update; a reviewer commits
it like any other change, so tagging decisions get a PR/git history same as
code. This is also what lets the GitHub Action rebuild the dashboard from a
clean checkout with no server or persistent volume involved.

## Why SQLite now, not Postgres

The original proposal calls for Postgres. For this first version, SQLite
gets the same relational design running with zero setup (`init_db.py`
against a single file — no server to stand up before anyone can try it).
The schema is written to port cleanly:

| SQLite (here)                     | Postgres equivalent          |
|------------------------------------|-------------------------------|
| `INTEGER PRIMARY KEY AUTOINCREMENT`| `SERIAL` / `BIGSERIAL`        |
| `TEXT` timestamps (ISO 8601)       | `TIMESTAMPTZ`                 |
| `labels TEXT` (comma-joined)       | `TEXT[]` or `JSONB`           |

Table/column names, keys, and relationships don't change. Porting is a
follow-up once there's a reason to (concurrent writers, needing the
dashboard to update more than once a day, etc.) — not before.

## Reference data seeding

`schema/002_seed_reference_data.sql` pre-populates `working_groups` with
`wg1-ra-aai` and `themes` with the six themes already listed in the use-case
issue template's "Theme relevance" section, so a reviewer has something to
map against immediately. New themes/WGs beyond these are created on the fly
by `review_use_case.py --add-theme "..."` — the taxonomy is meant to emerge,
not be fixed upfront.

## Deliberately not doing yet

Per the proposal's own "what to avoid initially" list:

- No forced final taxonomy — terms are created ad hoc by reviewers and
  start life as `candidate`.
- No mandatory fields beyond what GitHub's issue template already requires.
- No change to where use cases get submitted (still GitHub Issues).
- No write access from the dashboard — it's a read-only static page
  (`docs/dashboard.md`); tagging still happens through the reviewer CLI.
- No automated similarity/clustering — `related_use_case_links`, and the
  dashboard's "related use cases" groupings, are based on manual reviewer
  judgment (explicit links) or simple shared-attribute queries (same theme/
  taxonomy term/standards gap) — not embeddings or ML.
- No parsing of the issue template's structured checkboxes (sector, actors,
  mandates, risk level, ...) into dedicated columns. `body` is stored
  verbatim; extracting structure is reviewer judgment via the CLI until
  there's enough real submission volume to know which fields are worth
  automating.
