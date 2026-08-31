# Contributing to Libretype

Libretype is a fork of [KeyType](https://github.com/johnbean393/KeyType). Read
[`AGENTS.md`](AGENTS.md) before your first change — it holds the non-negotiable product principles
and the fork discipline that keeps upstream merges cheap.

## Build bootstrap

Requirements: macOS 14+ for the app, and a recent Xcode with Swift 6 tools for development.
Some packages declare `swift-tools-version: 6.0`; command-line Swift 5.10 is not sufficient.

```sh
git clone https://github.com/sajor2000/libretype.git
cd libretype
swift build --package-path Packages/ModelRuntime
```

The user-visible identity is Libretype (`io.github.sajor2000.libretype`); upstream's internal
`KeyType` target, scheme, workspace, and package identifiers are retained to keep upstream merges
small. There is no root `Package.swift`: select a package explicitly for SwiftPM commands.

### Build the macOS app without installing it

From the repository root:

```sh
KEYTYPE_SKIP_DEV_APP_INSTALL=1 xcodebuild \
  -workspace KeyType.xcworkspace \
  -scheme KeyType \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath .build/DerivedData-alpha-verification \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY= \
  build
```

The compile-check product is `.build/DerivedData-alpha-verification/Build/Products/Debug/KeyType.app`.
The skip flag bypasses the shared scheme's development-app installation hook; this command does
not replace `/Applications/Libretype Dev.app` or grant Accessibility permissions. Signing is
disabled for this compile check, so it does not prove that the app can load its model or run the
interactive smoke test. Use the development installation workflow below for that separate check.
CI sets the same skip flag. Xcode Run targets the installed `/Applications/Libretype Dev.app`.

If a public framework download stalls before reporting progress, retry SwiftPM with
`--disable-keychain --disable-netrc`, or add `-packageAuthorizationProvider netrc` to
`xcodebuild` to avoid Keychain lookup. The Xcode option still permits `.netrc` credentials;
it is not an anonymous-download guarantee. Do not change the pinned URL or checksum.
See [the alpha verification record](docs/research/2026-08-30-alpha-build-verification.md)
for the observed result and remaining runtime gates.

### The llama.cpp framework

Inference is backed by llama.cpp, consumed as a prebuilt Apple `xcframework` through a Swift Package
Manager URL+checksum `binaryTarget` (see ADR-007 / ADR-134). Clean clones resolve the framework
from the Libretype GitHub Releases mirror automatically:

```sh
git clone https://github.com/sajor2000/libretype.git
cd libretype
swift build --package-path Packages/ModelRuntime
```

Do **not** pin `Packages/ModelRuntime/Package.swift` to `github.com/ggml-org/llama.cpp/releases`
(ADR-007 abandoned that CDN). The mirror host and checksum live in that `Package.swift`; bumping
them requires a new ADR and a re-run of the U7 baseline.

**llama.cpp development override only:** place a locally built framework at
`Packages/ModelRuntime/Vendor/llama.xcframework` and temporarily switch the `binaryTarget` back to
`path: "Vendor/llama.xcframework"`. Do not commit the framework or leave a local-path binding on
the default branch — CI rejects that form.

```sh
git clone https://github.com/ggml-org/llama.cpp
cd llama.cpp && ./build-xcframework.sh
# then copy/link the resulting xcframework into Packages/ModelRuntime/Vendor/
```

To regenerate a checksum after mirroring a new zip:

```sh
swift package compute-checksum llama-bNNNN-xcframework.zip
```

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

## Alpha smoke (U5)

U5 proves the rebranded `.dev` build still does ghost text + Tab accept under Libretype identity,
without self-capture (R21, AE4). Full interactive Accessibility smoke is **human / Mac-only** —
this section is the prep checklist so that session is short and falsifiable. Do **not** mark U5
complete until the human checklist passes.

### Build the `.dev` app

```sh
Scripts/build-dev-app.sh
```

Installs `/Applications/Libretype Dev.app` with bundle id `io.github.sajor2000.libretype.dev`
(PRODUCT_NAME remains `KeyType`; display name is Libretype Dev).

### Automatable fixtures (run anytime)

Prod self-exclusion and co-installed KeyType are covered by unit tests — no second clean-machine
prod smoke in S0:

```sh
# Self-exclusion / co-install identity
swift test --package-path Packages/AutocompleteCore --filter HostAppIdentityTests

# AE4: CandidateFilter secure-field suppress (`secureFieldExcluded`)
swift test --package-path Packages/ConstrainedGeneration --filter CandidateFilterTests/testSecureFieldExcluded

# AE4: KeyTypeBench suite (includes secure-field / suppress scoring cases)
swift test --package-path Packages/KeyTypeBench
```

`HostAppIdentity` / `KeyTypeTests` fixtures assert:

- prod `io.github.sajor2000.libretype` and `.dev`
- co-installed `com.pattonium.keytype` / `com.pattonium.KeyType` (and `.dev`)
- unrelated hosts and `*helper` suffix false positives stay out

AE4 automated baseline: the CandidateFilter + KeyTypeBench commands above must stay green
(`secureFieldExcluded` / secure-field suppress cases).
### Human interactive checklist (Mac + Accessibility)

Work as Libretype Dev (`.dev`). Log path:
`~/Library/Application Support/Libretype/Logs/predictions.log` (truncated each launch).

1. Grant Accessibility to Libretype Dev; confirm a model under
   `~/Library/Application Support/Libretype/Models/` (not a KeyType container).
2. In Notes (or similar plain field): ghost text appears; Tab accepts; next-word tail retained.
3. **AE4:** focus a password / secure field — no ghost text; `predictions.log` records
   `secureFieldExcluded` (or equivalent suppress reason), not silent absence.
4. Focus Libretype Dev settings / onboarding — no self-capture (no ghost in own UI).
5. Co-install (if KeyType is still installed): Libretype does not capture inside KeyType windows;
   prefixes keep both identities excluded from each other.

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
