<coding_guidelines>
# Libretype — Always-On Rules

Libretype is a free, open-source, on-device, system-wide autocomplete utility for macOS, and a
**fork of [KeyType](https://github.com/johnbean393/KeyType)** (MIT). The app it inherits is
*built and shipping*: this repository's work is iteration on quality, not initial construction.

Libretype's differentiator is **suggestion quality**, explicitly traded against latency, memory,
and app coverage. Its success metric is adoption — stars, installs, contributors — not revenue.
It is free forever, with no paid tier.

**Read `docs/00-overview.md` first** for how the shipped system actually works. `docs/01`–`03`
describe architecture, prompting, and the token-profile format; `docs/04-roadmap.md` is the
upstream milestone archive; `docs/06`–`08` are the maintenance playbooks (quality, performance,
app compatibility). Libretype's own material lives in `docs/plans/` (requirements and sprint
order) and `docs/research/` (evidence). Log non-obvious decisions in `docs/05-decisions.md`.

## Product principles (non-negotiable, inherited from upstream)
- Narrow the problem: predict a *short* continuation at the cursor, then discard anything not
  immediately insertable.
- **Prefer suppression to a wrong suggestion** — showing nothing beats a bad completion. This
  applies to *every* engine, including remote ones that cannot filter at the logit level.
- Base-model continuation: the prompt ends exactly at the cursor (not chat/instruct).
- On-device & private: writing history and clipboard context are local, user-controllable, and on
  by default; screen/OCR remains opt-in. Remote inference is opt-in and never a silent fallback.

## Fork discipline (Libretype-specific)
- Upstream KeyType is tracked as the `upstream` remote and is **merged, not abandoned**. Every
  change should be shaped to keep those merges cheap.
- **Add, don't modify.** Prefer a new package or a new file over editing an upstream one. When an
  upstream file must change, make the smallest possible edit.
- Renames and reformatting of upstream files are forbidden outside a deliberate, isolated rebrand
  commit. They generate merge conflicts forever and buy nothing.
- TabType is a **one-time port**, not a tracked dependency. Ported files carry a header naming
  TabType and preserving its MIT notice.
- Cotabby is **AGPL-3.0**: readable as an architecture reference, never copyable. No AGPL code
  enters this repository.

## Architecture
- Target: macOS 14+, Swift. Logic lives in local SwiftPM packages under `Packages/`.
  **Extend the existing module graph; do not rewrite it.** Cross-module types go in
  `AutocompleteCore` (keep it free of AppKit/llama deps).
- Keep concrete wiring in the app target's module graph; keep packages decoupled.
- `LocalModelRuntime` is a token/logit-level protocol and is **deliberately linear and stable** —
  `StubModelRuntime` depends on it for tests. Remote engines do not belong behind it; they belong
  behind the higher, suggestion-level seam. See `docs/research/2026-08-30-fork-architecture-anchors.md`.
- Generation must be cancellable (a newer keystroke cancels in-flight work); keep model decode off
  the main actor; AX + overlay code is `@MainActor`.

## Evidence rules
- **No claim without a citation.** Assertions about upstream behaviour, third-party APIs, or model
  quality must cite a file and line, an ADR, or vendor documentation. Untraceable claims are
  labelled `ASSUMPTION` with the experiment that would settle them.
- Quality changes must move a benchmark number. "It feels better" is not a result.
- Record any non-obvious architectural, dependency, or product choice as a new ADR in
  `docs/05-decisions.md` (append-only, next sequential number, newest at the bottom).

## Iteration workflow
- Make the **smallest change behind the existing protocols** that fixes the problem; don't widen
  public APIs or add packages unless a change genuinely doesn't fit the current graph — and when it
  genuinely doesn't, write the research note that proves it first.
- **Quality issues:** reproduce first, then read the prediction log in
  `~/Library/Application Support/<app>/Logs/predictions.log` (truncated each launch) to see what the
  model predicted and why it was shown or suppressed, before changing code.
  See `docs/06-quality-playbook.md`.
- **Latency work:** measure in a **release** build — debug inflates per-token Swift work by 1–2
  orders of magnitude. See `docs/07-performance.md`.
- **App/domain behavior:** add an entry to `AppCompatibility` rather than special-casing elsewhere.
  See `docs/08-app-compatibility.md`.
- For every package you touch: add/update tests and keep `swift build` + `swift test` green.
- **Only create git commits when the human explicitly asks.**
</coding_guidelines>
