# Notices and attributions

Libretype is MIT licensed. It is a fork, and it borrows from other projects. This file records
exactly what came from where, so that the provenance stays auditable as the codebase diverges.

## KeyType — the fork base

- Project: [KeyType](https://github.com/johnbean393/KeyType)
- License: MIT, Copyright (c) 2026 Xi Nai Lai
- Relationship: **Libretype is a fork of KeyType.** The overwhelming majority of this repository's
  code, history, architecture, and documentation originates upstream, and Libretype's git history
  begins with KeyType's 170 commits rather than replacing them.
- Upstream is tracked as the `upstream` git remote. Libretype's strategy is to **add** packages and
  extend the module graph rather than rewrite it, specifically so that upstream improvements keep
  merging cleanly.

KeyType's MIT copyright notice is retained in `LICENSE` alongside Libretype's.

## TabType — ported context handling

- Project: [TabType](https://github.com/nilava/TabType)
- License: MIT, Copyright (c) 2026 TabType contributors
- Relationship: **One-time port, not a tracked dependency.** Specific files were adapted for
  accessibility-tree transcript extraction, document-aware prompt framing, text-mirroring overlay
  placement, and phrase memory. TabType's engine layer is MLX-based and was not ported.
- Every ported file carries a header naming TabType as its origin and preserving its MIT notice.
  The port inventory lives in `docs/research/2026-08-30-fork-architecture-anchors.md` (RN-4).

## Cotabby — architecture reference only

- Project: [Cotabby](https://github.com/FuJacob/cotabby)
- License: **AGPL-3.0**
- Relationship: **No code from Cotabby is present in Libretype, and none will be added.** Cotabby
  was read to understand how a multi-engine suggestion router is structured. That reading informed
  Libretype's own independently written engine seam. The design conclusion is documented in
  `docs/research/2026-08-30-fork-architecture-anchors.md` (RN-2).
- AGPL-3.0 is incompatible with Libretype's MIT licensing. This boundary is deliberate and must
  hold: reading an AGPL project for architectural ideas is fine, copying its code is not.

Note that Cotabby's inference wrapper, `CotabbyInference`, is separately MIT licensed. Libretype
does not use it, because llama.cpp's official xcframework is consumed directly.

## llama.cpp

- Project: [llama.cpp](https://github.com/ggml-org/llama.cpp)
- License: MIT
- Relationship: consumed as a prebuilt, checksum-pinned `xcframework` binary target. Libretype
  wraps only the C API surface (`llama.h`).

## Models

Model weights are downloaded at runtime and are never redistributed with Libretype. Each model
carries its own license, which users accept when they choose to download it.
