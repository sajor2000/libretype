# Name-scan and KD13 evidence notes (2026-08-30)

Supporting citations for the Libretype plan audit write-back and ce-code-review best-judgment pass.

## Trademark / name scan (G4 still owns closing)

- **Query (Tavily, 2026-08-30):** Libretype / libretype macOS autocomplete naming collisions.
- **Result (session):** No high-confidence conflicting shipping product under the exact name in the scanned results; G4 remains open until a fuller clearance (USPTO / domains / App Store) is recorded.
- **Plan use:** Sources line may cite this note; do not treat G4 as closed.

## KD13 Apple-forward claims

KD13's product bet is **user-directed** (session-settled). Forward-looking statements about Apple Intelligence / system autocomplete coverage are labeled **ASSUMPTION** until falsified:

| Claim | Status | Settling experiment |
| --- | --- | --- |
| Apple will serve first-party surfaces well | ASSUMPTION | Observe WWDC / System Settings writing tools releases |
| Apple will not ship user-inspectable personal writing models or arbitrary local model choice | ASSUMPTION | Same; plus App Store / developer docs for Foundation Models limits |
| Terminals / third-party apps remain underserved relative to first-party | ASSUMPTION | Re-test terminal + Electron coverage after each major macOS release |

The durable-edge decision itself does not require those assumptions to be proven before S0/S1; it constrains coverage (R13/R14) to defer-not-drop.

## Co-installed KeyType self-exclusion (settled in review)

Upstream already excludes self via `Bundle.main` and `com.pattonium.keytype` prefix, plus `appName` contains `"KeyType"` (`CompletionController.isKeyTypeTarget`, `ContextCaptureController.isKeyTypeTarget`). Correction still uses exact `com.pattonium.KeyType` only — U3 must align it.

**Decision:** Keep excluding co-installed KeyType (`com.pattonium.keytype` + appName fallback). Add Libretype prefix. Do not capture inside KeyType UI when both apps are installed (feedback / privacy).

## Mirror authenticity (U1)

SwiftPM `binaryTarget` checksum is content integrity. U1 ADR must also record upstream tag + GitHub asset digest (when published) + `swift package compute-checksum` of the mirrored zip; all three agree before pin. Example for `b9402`: GitHub digest `sha256:ac9adcabf4638eced651010ff8280df98b9bb094d2ba882d89823bbd3c63b895` (fetched via `gh api`, 2026-08-30).
