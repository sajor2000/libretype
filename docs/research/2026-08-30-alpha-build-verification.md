# Alpha build verification — 2026-08-30

## Scope and environment

This verifies the bounded [alpha build plan](../plans/2026-08-30-1824-fix-alpha-build-verification-plan.md), not completion of the full product plan.
Base revision: `7fb27321ee1fa8683e3340cf53820b0fbab4107a`; tested with the working-tree scheme, CI, and contributor-documentation changes on `codex/alpha-build-verification`.
Host: Apple silicon, macOS 26.2 (25C56), Xcode 26.4.1 (17E202).
Times below are America/Chicago (UTC−05:00). This is local verification, not a GitHub Actions result or macOS 14 compatibility certification.

## Results

| Check | Result | Evidence |
| --- | --- | --- |
| Scheme XML and development launch path | PASS | `xmllint --noout`; Run points to `/Applications/Libretype Dev.app`, matching `Scripts/install-dev-app-from-build.sh`. |
| CI install bypass | PASS, static only | YAML parsed; app-build step sets `KEYTYPE_SKIP_DEV_APP_INSTALL: "1"`. |
| Native unsigned Debug app build | PASS, 18:34 | `xcodebuild` exited 0 with `BUILD SUCCEEDED`; `KeyType.app` exists under the derived-data product path below. |
| Host identity tests | PASS, 18:27:40 | 6 tests, 0 failures. |
| Secure-field suppression test | PASS, 18:34:19 | 1 test, 0 failures. |
| KeyTypeBench fixture suite | PASS, 18:34:45 | 17 tests, 0 failures; these are harness fixtures, not real-model quality measurements. |
| Live ghost text / Tab acceptance / Accessibility | NOT RUN | Requires a separately installed development app and user-granted permissions; use the existing [U5 checklist](../../CONTRIBUTING.md#alpha-smoke-u5). |
| Release-model baseline | BLOCKED | No GGUF model was available in the Libretype or legacy KeyType Models directories checked on this host. No model was downloaded. |
| CE iOS simulator test | NOT APPLICABLE | This app is native macOS; the simulator skill's XcodeBuildMCP dependency was unavailable. Native Xcode verification above is not a simulator result. |

No development app was installed or replaced. The build log confirms the scheme post-action received `KEYTYPE_SKIP_DEV_APP_INSTALL=1`; the action exits before invoking the installer. No permissions, model pins, repository visibility, or suggestion behavior were changed.

## Reproduction

From the repository root, the successful native build command was:

```sh
KEYTYPE_SKIP_DEV_APP_INSTALL=1 xcodebuild \
  -workspace KeyType.xcworkspace \
  -scheme KeyType \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath .build/DerivedData-alpha-verification \
  -packageAuthorizationProvider netrc \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY= \
  build

swift test --package-path Packages/AutocompleteCore --filter HostAppIdentityTests
swift test --disable-keychain --disable-netrc \
  --package-path Packages/ConstrainedGeneration \
  --filter CandidateFilterTests/testSecureFieldExcluded
swift test --disable-keychain --disable-netrc --package-path Packages/KeyTypeBench
```

Product: `.build/DerivedData-alpha-verification/Build/Products/Debug/KeyType.app`.
Ignored local evidence: `.build/alpha-verification/{identity-tests,secure-field-tests-no-credentials,benchmark-tests-no-credentials,xcode-build-netrc}.log`.
Build logs can include environment values; they are not publication artifacts. This note intentionally records only selected nonsecret summaries.

## Dependency-download observation

The first Xcode build and two dependency-bearing Swift test processes stalled at framework resolution for roughly five to seven minutes and were terminated; they did not pass or produce a compile failure.
An independent public archive transfer returned HTTP 200, downloaded 205,096,220 bytes in 8.64 seconds, and matched the manifest's SHA-256:

`ac9adcabf4638eced651010ff8280df98b9bb094d2ba882d89823bbd3c63b895`

Retrying SwiftPM with both credential stores disabled and Xcode with `-packageAuthorizationProvider netrc` succeeded without changing `Packages/ModelRuntime/Package.swift`.
This isolates an effective workaround, not a proven diagnosis of the original stall. Xcode's netrc provider is not equivalent to disabling all credentials. No credential files or Keychain contents were inspected or changed.

## Warnings and next sprint gates

The successful build is not warning-free: existing app-icon catalog entries reference extensionless filenames, and several existing Swift concurrency warnings remain in completion, telemetry, settings, and update code. These files were unchanged; no warning cleanup was folded into this sprint.

Next: make a release-build model/profile pair available, run the U5 synthetic-text interactive checklist, and collect the original plan's S1/U7 benchmark metrics before quality tuning or S2 context changes. A user-authorized installation and Accessibility grant are separate from this compile-only check.
The original G4 name-clearance gate remains open; a public repository does not establish release clearance. No binary release or merge was performed.
