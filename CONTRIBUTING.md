# Contributing to Libretype

Libretype is a fork of [KeyType](https://github.com/johnbean393/KeyType). Read
[`AGENTS.md`](AGENTS.md) before your first change — it holds the non-negotiable product principles
and the fork discipline that keeps upstream merges cheap.

## Build bootstrap

Requirements: macOS 14+, a recent Xcode, and Swift 5.10 or newer.

```sh
git clone https://github.com/sajor2000/libretype.git
cd libretype
swift build
```

The fork is mid-rebrand: upstream `KeyType` identifiers, the Xcode workspace name, and the bundle
identifier are still in place and are being renamed in a single isolated commit. Expect both names
in the tree for now.

### The llama.cpp framework

Inference is backed by llama.cpp, consumed as a prebuilt Apple `xcframework` through a Swift Package
Manager binary target.

> **Known blocker, being fixed.** Inherited from upstream, `Packages/ModelRuntime/Package.swift`
> binds the framework from a **gitignored local path** (`Vendor/llama.xcframework`), so a clean
> clone does **not** build until you produce the framework yourself. Libretype is switching this to
> a checksum-pinned URL binding, which llama.cpp officially supports, so that `git clone && swift build`
> just works. Reasoning and sources:
> [`docs/research/2026-08-30-fork-architecture-anchors.md`](docs/research/2026-08-30-fork-architecture-anchors.md)
> (RN-1).

Until that lands, build the framework yourself and drop it at
`Packages/ModelRuntime/Vendor/llama.xcframework`:

```sh
git clone https://github.com/ggml-org/llama.cpp
cd llama.cpp && ./build-xcframework.sh
```

Do not commit the framework — `.gitignore` excludes it deliberately.

Once the URL binding lands, this manual step disappears and building from a local llama.cpp becomes
the opt-in path for llama.cpp development only. Bumping the pinned version will then mean changing
the release tag in the URL and regenerating the checksum with
`swift package compute-checksum <file>.zip`, recorded as an ADR in `docs/05-decisions.md`.

### Models

Model weights are downloaded at runtime into Application Support and are never committed. `.gguf`
files are gitignored.

## Repository layout

| Path | Contents |
| --- | --- |
| `Packages/` | All logic, as local SwiftPM packages. Cross-module types live in `AutocompleteCore`. |
| `docs/00`–`09` | Upstream architecture, prompting, roadmap, decisions, and maintenance playbooks. |
| `docs/plans/` | Libretype requirements and sprint order. |
| `docs/research/` | Evidence for every architectural decision, with citations. |
| `Scripts/` | Dev build, profile generation, and release tooling. |

## Before you open a pull request

1. `swift build` and `swift test` are green for every package you touched.
2. Tests added or updated for the behaviour you changed.
3. **Quality changes carry a benchmark number.** Run the benchmark suite and include the before and
   after. "It feels better" is not a result — see `docs/06-quality-playbook.md`.
4. **Latency changes were measured in a release build.** Debug builds inflate per-token Swift work
   by one to two orders of magnitude — see `docs/07-performance.md`.
5. Non-obvious architectural, dependency, or product choices are recorded as a new ADR in
   `docs/05-decisions.md` (append-only, next sequential number, newest at the bottom).
6. App-specific behaviour went into `AppCompatibility`, not a special case elsewhere.

## Things that will get a pull request rejected

- **AGPL-licensed code.** Cotabby is readable as an architecture reference and is never copyable.
  Any borrowed code must be MIT or equivalently permissive, with attribution added to
  [`NOTICE.md`](NOTICE.md).
- **Renaming or reformatting upstream files** outside a deliberate rebrand commit. It generates
  merge conflicts against upstream forever.
- **Widening `LocalModelRuntime`.** It is deliberately linear and stable because `StubModelRuntime`
  depends on it. New engine capabilities belong at the suggestion-level seam.
- **Making remote inference a silent fallback.** It is opt-in, per-endpoint, and visible.
- **A suggestion that fires when it should have suppressed.** Suppression beats a wrong suggestion,
  on every engine.

## Reporting quality problems

The most useful bug report for this project is a concrete completion that was wrong. Include the app,
the text before the cursor, what was suggested, and what you expected. If you can, attach the
relevant lines from the prediction log in `~/Library/Application Support/<app>/Logs/` — it records
what the model predicted and why the app showed or suppressed it.
