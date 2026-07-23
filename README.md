# Krv Labs Homebrew Tap

Homebrew formulae for [Krv Labs](https://github.com/Krv-Labs) tools.

## topos

Structural code quality metrics for agent-written programs.
Docs: <https://docs.krv.ai/topos> · Source: <https://github.com/Krv-Labs/topos>

### Install

Recommended (Homebrew 6+: auto-taps and trusts only this formula):

```sh
brew install krv-labs/tap/topos
```

Or tap first, then install. On Homebrew 6+, short-name install needs an
explicit trust step:

```sh
brew tap krv-labs/tap
brew trust --formula krv-labs/tap/topos
brew install topos
```

Do not set `HOMEBREW_NO_REQUIRE_TAP_TRUST` — that escape hatch is discouraged
and slated for removal. See <https://docs.brew.sh/Tap-Trust>.

### Upgrade

```sh
brew upgrade topos
```

### Supported platforms

- macOS arm64 (Apple Silicon)
- Linux amd64
- Linux arm64

Intel macOS is not supported.

## Maintenance

The `topos` formula is auto-updated by the topos release pipeline (opens a PR
on this tap). Do not hand-edit the version or `sha256` lines — they are
overwritten on each release.
