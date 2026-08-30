<h1 align="center">Libretype</h1>

<p align="center">
A free, open-source, on-device autocomplete for every text field on your Mac.
</p>

<p align="center">
  <img alt="Platform: macOS 14+" src="https://img.shields.io/badge/macOS-14%2B-black?style=flat-square&logo=apple&logoColor=white">
  <img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-blue?style=flat-square">
  <img alt="Status: pre-alpha" src="https://img.shields.io/badge/status-pre--alpha-orange?style=flat-square">
</p>

> **Status: pre-alpha, not yet released.** Libretype is a fork of
> [KeyType](https://github.com/johnbean393/KeyType) currently being rebuilt around a single goal:
> suggestion quality. There is no Libretype download yet. If you want a working app today, use
> KeyType — it is excellent, and it is why this project has a head start.

Libretype watches the focused text field in any app, predicts a short continuation at the cursor
using a local LLM, and offers it as ghost text you accept with **Tab**. Nothing leaves your Mac
unless you explicitly connect a remote endpoint.

It is a free, MIT-licensed alternative to the closed-source, subscription-priced *Cotypist*.

## Why this fork exists

KeyType already solved the hard, unglamorous half of this problem: reading the accessibility tree,
placing an overlay accurately, inserting text safely across hundreds of apps, and running llama.cpp
without melting the battery. That plumbing takes months and differentiates nothing.

Libretype spends its effort on the half that users actually judge: **whether the suggestion is
worth pressing Tab for.** Concretely, it optimises suggestion quality even at the cost of latency,
memory, and app coverage — the opposite of the usual trade. The reasoning, the requirements, and
the sprint order live in [`docs/plans/`](docs/plans/).

## What it will do differently

- **Conversation-aware context.** Read the surrounding thread from the accessibility tree, not just
  the current text field, so a reply knows what it is replying to.
- **Document-aware framing.** Distinguish the start of a document from the middle of a sentence.
- **Personalisation that stays local.** Learn your phrasing from an encrypted, on-device writing
  history you can inspect and delete.
- **Optional remote engine.** Point Libretype at your own OpenAI-compatible endpoint when your Mac
  is too slow for a good local model. Off by default, and never a silent fallback.
- **Terminals and every app**, not a curated allowlist.

## Principles

1. **Suppression beats a wrong suggestion.** Showing nothing is a correct answer.
2. **On-device by default.** Remote inference is opt-in, per-endpoint, and visible.
3. **Free, forever, for everyone.** No subscription, no word quota, no paid tier.
4. **Measured, not asserted.** Quality claims ship with benchmark numbers.

## Development

Requirements: macOS 14+, a recent Xcode.

```sh
git clone https://github.com/sajor2000/libretype.git
cd libretype
open KeyType.xcworkspace   # renamed to Libretype during the in-progress rebrand
```

**Read [`CONTRIBUTING.md`](CONTRIBUTING.md) before your first build.** It covers the llama.cpp
framework binding, the module layout, and how to run the benchmark suite. The fork is mid-rebrand,
so upstream `KeyType` names still appear throughout the source tree.

## Supporting the project

Libretype is free and always will be. There is no paid tier and no feature held back for donors.

If it saves you time and you want to say thanks, a one-off **$5** covers a meaningful slice of the
hardware time that quality benchmarking eats.

`TODO(setup)`: add Ko-fi / GitHub Sponsors links once the accounts exist.

Starring the repository helps more than money does — it is how other people find the project.

## Credits

Libretype stands on [KeyType](https://github.com/johnbean393/KeyType) (MIT) and adapts context
handling from [TabType](https://github.com/nilava/TabType) (MIT). Full provenance, including
what was deliberately *not* borrowed and why, is in [`NOTICE.md`](NOTICE.md).

## License

MIT. See [`LICENSE`](LICENSE).
