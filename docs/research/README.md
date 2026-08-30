# Libretype research notes

Every architectural decision in `docs/plans/` must trace to a note here, and every note must
cite a primary source: upstream source code (file + line), an upstream ADR, or vendor
documentation retrieved via MCP.

Rules:

- **No claim without a citation.** If a claim cannot be traced to a file, a line, or a document,
  it is an assumption and must be labelled `ASSUMPTION` with the experiment that would settle it.
- **Cite the clone, not memory.** Reference clones live outside this repo at
  `~/libretype-refs/{cotabby,keytype,tabtype}` so they never enter Libretype's history.
- One file per research theme, prefixed with the date it was written.

| Note | Theme | Status |
| --- | --- | --- |
| `2026-08-30-fork-architecture-anchors.md` | Fork bootstrap, engine seam, remote API surface, port inventory | Active |
| `2026-08-30-plan-review-evidence.md` | KD13 ASSUMPTIONs, co-install exclusion, mirror attestation, name scan | Active |
