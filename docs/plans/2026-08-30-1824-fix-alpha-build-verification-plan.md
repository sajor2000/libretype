---
title: Libretype Alpha Build Verification - Plan
type: fix
date: 2026-08-30
artifact_contract: ce-unified-plan/v1
artifact_readiness: implementation-ready
product_contract_source: ce-plan-bootstrap
execution: code
---

# Libretype Alpha Build Verification - Plan

## Goal Capsule

- Objective: Contributors can build Libretype and run the intended development app, with trustworthy evidence of what is ready for the next sprint.
- Means: Repair the existing Xcode/CI entry points and exercise the inherited verification tools (KTD1).
- Authority: This bounded continuation advances the S0/S1 work in `docs/plans/2026-08-30-0434-feat-libretype-mac-autocomplete-plan.md`; it does not replace that product contract.
- Execution profile: Complete U1-U3 in sequence. Limit each build-repair cycle to three attempts per distinct failure. Stop on unavailable dependencies or a product decision that cannot be safely inferred.
- Tail: Review the branch before publication. No merge, app release, visibility change, permission grant, or large model download is included.

---

## Product Contract

### Summary

Correct the inherited Xcode development-app launch target, prevent CI builds from installing a desktop app, and verify the existing native build and automated safety fixtures.

### Problem Frame

The foundation, identity changes, and brand assets are present at `7fb2732`, but the shared Xcode scheme still launches KeyType Dev while the installer produces Libretype Dev.
The CI app build also inherits a post-build install hook without setting its existing bypass.
Neither committed smoke instructions nor a successful compile prove interactive autocomplete behavior or a model-quality baseline.

### Requirements

**Build and run**

- R1. Xcode Run must target the Libretype development app produced by the existing installer, retaining the internal KeyType target and scheme names.
- R2. CI and noninteractive verification builds must suppress the development-app installation hook and not replace any app under Applications.
- R3. The current native macOS application must compile with the pinned framework, and existing identity and secure-field tests must be run with failures reported.

**Evidence and sprint progression**

- R4. Record build, package-test, interactive-smoke, and model-baseline outcomes separately; missing permissions or model files must never become passing evidence.
- R5. Preserve the original sprint gates, privacy rules, local default engine, and upstream integration boundaries. No new suggestion or remote-engine behavior is included.

### Acceptance Examples

- AE1. Covers R1: after the existing development installer succeeds, the shared scheme points Run at the same Libretype Dev app identity and location.
- AE2. Covers R2: a verification or CI build sets the existing skip flag, and the installer is not invoked.
- AE3. Covers R4: with no local GGUF/profile, model baseline is blocked or skipped with a concrete prerequisite; compile and fixture results remain independently reportable.

### Scope Boundaries

This sprint owns the scheme, CI build guard, directly necessary build repairs, contributor instructions, and a concise verification record.
The original plan remains authoritative for MIT licensing, local privacy, the existing module graph, no container migration, and the later context and engine work.

#### Deferred to Follow-Up Work

- S1: run a release-build smoke with an available GGUF/profile, then record per-model quality, precision, wrong-show, suppression, and latency metrics before model selection and quality thresholds.
- S2-S6: retain the original ordering and gates for transcript context, document framing, personalization, remote engine, and coverage.
- S7: name clearance, signing/notarization, and public distribution. The repository is already public although the original plan's KTD8 says private until G4; do not alter visibility or silently mark G4 closed.
- Interactive Accessibility-granted smoke requires a suitable user session and user-granted permissions. No reading of private typing or prediction logs to manufacture evidence.

---

## Planning Contract

### Key Technical Decisions

- KTD1. Patch the existing shared scheme and use its existing install-suppression mechanism. This preserves upstream identifiers and avoids introducing another build system. Sources: `KeyType.xcodeproj/xcshareddata/xcschemes/KeyType.xcscheme`, `Scripts/build-dev-app.sh`, `Scripts/install-dev-app-from-build.sh`.
- KTD2. Use native macOS Xcode and SwiftPM verification for R3. The requested CE simulator skill targets iOS and requires unavailable XcodeBuildMCP; no simulator result will be claimed.
- KTD3. Keep source changes confined to proven blockers encountered while verifying R1-R3. Model downloads, tuning, schema changes, and app installation are separate work.
- KTD4. Keep evidence in `docs/research/2026-08-30-alpha-build-verification.md`; raw build logs remain in ignored `.build/`. Record timestamps, revision, toolchain, command, exit outcome, and explicit skipped checks.

### Assumptions

- The first useful sprint is closing build/run verification rather than adding context features before an executable baseline exists.
- Three repair attempts per distinct failure is the bounded execution limit; new failure evidence may begin a new cycle, but repeated unchanged environmental failure stops the run.
- Publishing code through the requested LFG workflow does not authorize a binary release or resolve name clearance. Existing explicit repository commit restrictions remain in force.

### Risks and Dependencies

Xcode's scheme post-action installs and replaces an app, so every diagnostic build must carry the bypass.
The current host has Xcode 26.4.1; CI chooses Xcode 16. Package and application compatibility must be observed rather than assumed.
No Libretype Models directory is present on this host, so a quality baseline cannot yet be demonstrated.
GitHub read access works publicly; authenticated push/PR access remains unverified.

---

## Implementation Units

### U1. Align Xcode Run and suppress CI installation

- **Goal:** Fulfill R1 and R2 without renaming upstream targets.
- **Requirements:** R1, R2; AE1, AE2; original plan R21/R22.
- **Dependencies:** None.
- **Files:** `KeyType.xcodeproj/xcshareddata/xcschemes/KeyType.xcscheme`, `.github/workflows/ci.yml`.
- **Approach:** Correct the stale development-app launch path and post-action label. Apply the existing install-skip flag to the CI app-build step per KTD1.
- **Test expectation:** No new unit test for static configuration; inspect XML/YAML structure, compare the scheme path with installer defaults, and exercise an unsigned build with installation disabled.
- **Verification:** Scheme resolves Libretype Dev; CI passes the bypass; target/scheme/entitlements identifiers are preserved.

### U2. Establish a native build and safety-fixture result

- **Goal:** Fulfill R3 on the available Mac.
- **Requirements:** R2, R3, R4; original plan U5/AE4 automated portion.
- **Dependencies:** U1.
- **Files:** Existing `Packages/AutocompleteCore/Tests/AutocompleteCoreTests/HostAppIdentityTests.swift`, `Packages/ConstrainedGeneration/Tests/ConstrainedGenerationTests/Filtering/CandidateFilterTests.swift`, `Packages/KeyTypeBench/Tests/KeyTypeBenchTests/`; directly owning source/test files only if a reproducible build blocker requires a minimal repair.
- **Approach:** Build the KeyType macOS scheme unsigned with the install hook disabled. Run identity, secure-field suppression, and benchmark package tests. Diagnose any actual failure before changing code; re-run affected checks after a repair.
- **Execution note:** Configuration-first work: use the native build and existing tests as the initial proof rather than writing tests that mirror static text.
- **Test scenarios:**
  1. Production/dev and co-installed KeyType identities remain excluded; unrelated helper identifiers do not match.
  2. Secure fields receive a suppression result in existing candidate-filter tests.
  3. Benchmark fixtures load and score without requiring a real GGUF for their stub-based cases.
  4. Dependency, SDK, or compile failure remains a failure until a successful rerun replaces it.
- **Verification:** Build artifact path and actual test summaries recorded; no app installation or permission mutation occurred.

### U3. Publish a reproducible sprint handoff

- **Goal:** Fulfill R4 and R5 and identify the next executable sprint.
- **Requirements:** R4, R5; AE3; original plan U5-U7.
- **Dependencies:** U2.
- **Files:** `CONTRIBUTING.md`, `docs/research/2026-08-30-alpha-build-verification.md`.
- **Approach:** Document a native macOS build-only command with the bypass and signing behavior. Record evidence per KTD4, the model prerequisite, the existing U5 manual checklist, and the S1 baseline acceptance gate. Do not change the original product decisions.
- **Test expectation:** Documentation-only; confirm commands match successful checks and every PASS has evidence.
- **Verification:** Another contributor can repeat the build without an Applications write; no unmeasured quality claim or implied end-to-end completion appears.

---

## Verification Contract

- Parse the shared `.xcscheme` XML and confirm Run and installer development-app defaults agree.
- Native build: `xcodebuild` with workspace `KeyType.xcworkspace`, scheme `KeyType`, destination `platform=macOS`, dedicated ignored derived data, `KEYTYPE_SKIP_DEV_APP_INSTALL=1`, and signing disabled. Confirm a real `KeyType.app` product exists.
- Identity: `swift test --package-path Packages/AutocompleteCore --filter HostAppIdentityTests`.
- Secure fields: `swift test --package-path Packages/ConstrainedGeneration --filter CandidateFilterTests/testSecureFieldExcluded`.
- Harness: `swift test --package-path Packages/KeyTypeBench`.
- Run `git diff --check`; review all changed files against R1-R5.
- Interactive U5 and release model benchmarks are separately marked NOT RUN/BLOCKED until actual evidence exists. These remain prerequisites to overall alpha completion, not conditions to mislabel the bounded configuration sprint.

---

## Definition of Done

U1's configuration correction is reviewed; U2 has a successful native build and passing scoped safety/harness tests; U3 contains reproducible, timestamped evidence and the remaining gates.
Any new compile repair has focused verification.
No abandoned experiments, model binaries, raw private logs, unrelated refactors, installed-app replacement, or changed repository visibility are included.
If native build/test prerequisites remain blocked after the bounded attempts, preserve the partial evidence and stop without claiming this sprint or the full app is complete.
