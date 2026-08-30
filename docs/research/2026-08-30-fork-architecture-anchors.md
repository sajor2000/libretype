# Fork architecture anchors

Date: 2026-08-30
Scope: the four upstream facts that constrain Libretype's build order, plus the port inventory.
Method: direct reads of the upstream working tree and reference clones, plus llama.cpp
documentation retrieved through the Context7 MCP server.

Reference clones (outside this repo): `~/libretype-refs/{cotabby,keytype,tabtype}`.

---

## RN-1 — A fresh clone of this repo cannot build

**Finding.** Upstream binds llama.cpp as a **local-path** `binaryTarget`, and that path is
gitignored. Cloning and building therefore fails until the framework is produced by hand.

Evidence:

- `Packages/ModelRuntime/Package.swift:25-28` — the binding itself:

  ```swift
  .binaryTarget(
      name: "llama",
      path: "Vendor/llama.xcframework"
  ),
  ```

- `.gitignore:35-36` — `# Vendored binary frameworks (llama.cpp xcframework lives outside git, see ADR-007)` / `Packages/ModelRuntime/Vendor/`
- **Confirmed empirically on this clone at `21df2cc`:** `Packages/ModelRuntime/Vendor/` does not
  exist. The path the manifest requires is absent, so package resolution cannot succeed.
- `docs/05-decisions.md:274-286` (ADR-007, accepted 2026-05-29, "amended 2026-05-29 to use a
  local-path binding") — rejects (A) third-party SwiftPM wrappers because they force
  `.interoperabilityMode(.Cxx)` to propagate through every consumer of `ModelRuntime`, and
  rejects (C) building llama.cpp from source in-repo as "large ggml/Metal tree, slow + fragile,
  high maintenance". Chooses (B) the official prebuilt xcframework, target build **`b9402`**,
  produced by `build-xcframework.sh`, wrapping only the C surface (`llama.h`) in an isolated
  `LlamaModelRuntime` target.

**The upstream decision (B) is correct and Libretype keeps it. Only the *binding* is wrong for
our goals.** A local-path binding is fine for a solo maintainer and hostile to contributors,
which matters because Libretype's success metric is adoption.

**Anchor: llama.cpp officially supports a checksum-pinned URL binding.**

Source: `github.com/ggml-org/llama.cpp/blob/master/docs/xcframework.md`, via Context7.

```swift
.binaryTarget(
    name: "LlamaFramework",
    url: "https://github.com/ggml-org/llama.cpp/releases/download/b5046/llama-b5046-xcframework.zip",
    checksum: "c19be78b5f00d8d29a25da41042cb7afa094cbf6280a225abe614b03b20029ab"
)
```

The docs state integration "is managed via Swift Package Manager by defining a binary target.
Users can specify the library version by providing the appropriate download URL and the
corresponding checksum for the desired build." `build-xcframework.sh` remains the escape hatch
for a locally patched llama build.

**Prior art.** Cotabby consumes `CotabbyInference` as a SwiftPM dependency pinned to a
checksum-verified binary build, i.e. the same pattern applied one layer up.

**Decision (feeds KD11).** Libretype replaces the local-path binding with a checksum-pinned URL
`binaryTarget`, retaining a documented local-path override for llama.cpp development.
Consequence: `git clone && swift build` works with no manual bootstrap. Cost: pinned builds must
be bumped deliberately, and the checksum must be regenerated on every bump — this is a feature,
not a cost, because it makes the inference binary reproducible.

**Blocks:** S0. Nothing else can be verified until the project builds from a clean clone.

---

## RN-2 — A cloud engine cannot implement the only engine protocol upstream has

**Finding.** Upstream's sole runtime seam is token/logit-level. A remote HTTP API returns text,
never logits, so it cannot satisfy the protocol. The hybrid-backend requirement does not fit
the current module graph.

Evidence — `Packages/ModelRuntime/Sources/ModelRuntime/ModelRuntime.swift:56`:

```swift
public protocol LocalModelRuntime {
    var metadata: ModelMetadata { get }
    var tokenizer: ModelTokenizing { get }
    func prepare(promptTokens: [TokenID]) async throws
    func logitsForNextToken() async throws -> [TokenLogit]
    func decodeNext(tokenID: TokenID) async throws
    func resetKVCache() async
    func shutdown() async
    func anchoredLogits(anchor: [TokenID], suffix: [TokenID]) async throws -> [TokenLogit]
    // + a batched variant expanding a whole beam frontier in one `llama_decode`
}
```

A repo-wide grep for `protocol .*Runtime|protocol .*Engine|protocol .*Suggest` across
`Packages/*/Sources` and the app target returns exactly one match: `LocalModelRuntime`. There is
no higher-level seam to plug a remote engine into.

`docs/05-decisions.md:527-529` confirms the protocol is intentionally narrow: it is "deliberately
**linear** (`prepare` / `decodeNext` / `logitsForNextToken`, one KV cache) and must stay stable so
`StubModelRuntime` keeps working for tests." Multi-branch search was implemented by re-`prepare`ing
rather than by widening the protocol.

**Anchor: Cotabby already solved this at the right altitude.**

`~/libretype-refs/cotabby/Cotabby/Services/Runtime/SuggestionEngineRouter.swift` routes at the
*suggestion* level, not the token level:

```swift
@MainActor
final class SuggestionEngineRouter {
    private let foundationModelEngine: any SuggestionGenerating
    private let llamaEngine: any SuggestionGenerating
    private let openAICompatibleEngine: any SuggestionGenerating
    // ...
    func generateSuggestion(
        for request: SuggestionRequest,
        onPartial: (@MainActor (SuggestionResult) -> Void)?
    ) async throws -> SuggestionResult
}
```

The file's own header states the intent: "Routes generation requests to the currently selected
autocomplete engine. This keeps engine selection in the composition/runtime layer instead of
forcing `SuggestionCoordinator` to know about concrete backend types." Apple Intelligence, local
llama, and an OpenAI-compatible endpoint are peers behind one protocol, with per-engine latency
and quality metrics and a locale-based fallback path.

**Decision (feeds KD12).** Introduce a suggestion-level protocol — request in, result out, with
partial-token streaming — above `LocalModelRuntime`, and route local vs remote there.
`LocalModelRuntime` is left untouched, which satisfies upstream's stability requirement and keeps
`StubModelRuntime` working.

Upstream `AGENTS.md` forbids adding packages "unless a change genuinely doesn't fit the current
graph." This is that case, and this note is the justification.

### RN-2a — The quality asymmetry this creates (an unbudgeted requirement)

Everything in `Packages/ConstrainedGeneration/` operates on logits:
`CorrectionValidationScorer.swift`, `Engine/`, `Filtering/`, `Sampling/`, `Text/`. Logit masking,
admissibility checking, and multi-branch search over `anchoredLogits` are **structurally
unavailable to a remote engine.**

Libretype's first product principle, inherited from upstream `AGENTS.md`, is "**prefer suppression
to a wrong suggestion**". The remote path cannot enforce that at the sampling layer. It therefore
needs an equivalent **text-level** post-filter, or the remote path will violate the app's core
quality promise while advertising itself as the higher-quality option.

This is a requirement the roadmap did not previously carry. It belongs to S5, and it means the
remote engine is **not** a drop-in quality upgrade — it is a different quality profile.

---

## RN-3 — The remote engine must target `/v1/completions`, not `/v1/chat/completions`

**Finding.** Libretype inherits base-model continuation: "the prompt ends exactly at the cursor
(not chat/instruct)" (`AGENTS.md`, product principles). Only a raw-prompt endpoint preserves that.

Anchor — `github.com/ggml-org/llama.cpp/blob/master/tools/server/README.md`, via Context7:

- **`POST /v1/completions`** — "Given an input prompt, returns predicted completions. Supports
  streaming mode and llama.cpp `/completion`-specific features." Body takes `prompt` (string,
  required), `max_tokens`, `model`. This is the correct target: a raw string continuation with a
  token budget and streaming.
- **`POST /v1/chat/completions`** — requires `messages` with roles. Wrapping a cursor prefix in a
  chat turn forces an instruct framing, which is the exact prompt shape upstream's product
  principle rejects.
- **`POST /infill`** — "Takes a prefix and a suffix and returns the predicted completion as a
  stream for code infilling", with `input_prefix`, `input_suffix`, and `input_extra` for
  repo-level context.

`/infill` matters more than it first appears: mid-line completion is fill-in-the-middle shaped,
and upstream already assembles FIM prompts by hand — `ModelRuntime.swift` documents
`tokenizeAllowingSpecial` as parsing "control markers (e.g. `<|fim_prefix|>`) into their single
dedicated vocab tokens rather than literal text. Used only for app-constructed scaffolding such
as fill-in-the-middle assembly."

**Decision (feeds R7).** The remote engine speaks `/v1/completions` as its baseline, since it is
the widest-supported raw-prompt surface (llama-server, llama-cpp-python, vLLM, Ollama all expose
it). `/infill` becomes an optional capability negotiated per endpoint and used for mid-line
requests when available. `/v1/chat/completions` is explicitly out of scope.

**Open.** Hosted frontier APIs are deprecating raw-prompt completions. If the target is a hosted
provider rather than a self-hosted server, the base-model premise breaks and the remote path needs
a different prompt strategy. R7 must resolve *which* endpoints are supported before S5.

---

## RN-4 — Port inventory: what upstream already has vs. what TabType adds

Two of the roadmap's assumptions were wrong, and this is the corrected ledger.

**Upstream already ships (do not port, do not rebuild):**

- 15 SwiftPM packages under `Packages/`, including `MacContextCapture`, `AppCompatibility`,
  `CompletionUI`, `Prompting`, `TokenProfiles`, `ProfileBuilder`, `ModelManagement`,
  `TextInsertion`, `ConstrainedGeneration`, and `KeyTypeBench`.
- **Encrypted personalization**, contrary to the earlier assumption:
  `Packages/Personalization/Sources/Personalization/` contains `PersistentWritingHistoryStore.swift`,
  `KeychainPassphrase.swift`, `ThresholdTuner.swift`, `CompletionTelemetry.swift`,
  `LatencyExport.swift`.
- A benchmark harness (`KeyTypeBench` package, `KeyTypeBench-20260603/`, `KeyTypeBench-20260607/`,
  `docs/09-benchmark-datasets.md`) and release tooling (`Scripts/build-dev-app.sh`,
  `prepareRelease.sh`, `release.sh`, `build-acpf-profile.sh`).
- Maintenance playbooks: `docs/06-quality-playbook.md`, `07-performance.md`,
  `08-app-compatibility.md`.

**TabType port candidates** (`~/libretype-refs/tabtype/Sources/TabType/Core/`, MIT):

| Source file | Destination | Note |
| --- | --- | --- |
| `TranscriptExtractor.swift`, `TranscriptNormalizer.swift` | new context package | The S2 differentiator: AX-tree conversation transcript as context |
| `PromptBuilder.swift` | `Prompting` | `<document_start>` document-aware framing |
| `SuggestionOverlay.swift` | `CompletionUI` | Text-mirroring overlay placement |
| `PhraseMemory.swift` | `Personalization` | Merge into the existing store, do not add a parallel one |
| `AppPolicy.swift` | `AppCompatibility` | Upstream `AGENTS.md`: "add an entry to `AppCompatibility` rather than special-casing elsewhere" |
| `OCRCleaner.swift`, `ScreenContextProvider.swift` | `MacContextCapture` | Opt-in screen path only |

**Do not port:** `Engines/` (MLX), `KeystrokeMonitor.swift`, `TextInserter.swift`,
`ContextReader.swift`, `AccessibilityBridge.swift`, `TypingHistoryStore.swift`,
`GhostAppearanceProbe.swift`, `Statistics.swift`, `Log.swift`. Upstream has equivalents that are
better integrated, and TabType's engine layer is MLX-based where Libretype is llama.cpp-based.

**ASSUMPTION (feeds R3).** TabType's speculative parking and mirroring behaviour is described
against an MLX engine (`SuggestionEngine.swift:38 var speculative: Bool`). Whether those
behaviours survive a port to llama.cpp is unverified. Settle before S3 by porting mirroring alone
and measuring, not by porting the whole file set.

---

## Sources

- Upstream working tree at `21df2cc`: `AGENTS.md`, `.gitignore`, `docs/05-decisions.md`,
  `Packages/ModelRuntime/Sources/ModelRuntime/ModelRuntime.swift`,
  `Packages/{ConstrainedGeneration,Personalization}/Sources/`.
- `~/libretype-refs/cotabby/Cotabby/Services/Runtime/SuggestionEngineRouter.swift` (AGPL-3.0 —
  read as architecture reference only; no code copied).
- `~/libretype-refs/tabtype/Sources/TabType/Core/` (MIT).
- llama.cpp `docs/xcframework.md` and `tools/server/README.md`, retrieved via Context7 MCP
  (`/ggml-org/llama.cpp`).
