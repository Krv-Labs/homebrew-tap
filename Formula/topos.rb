class Topos < Formula
  desc "Structural code quality metrics for agent-written programs"
  homepage "https://docs.krv.ai/topos"
  # macOS default; Linux URLs are defined in the on_linux block. A top-level
  # URL must exist so `brew readall --os=all --arch=all` can load the formula
  # on Intel macOS, where no binary ships (guarded by depends_on arch below).
  url "https://github.com/Krv-Labs/topos/releases/download/v0.3.12/topos-macos-arm64"
  version "0.3.12"
  sha256 "b3e49942a5be7793c6ec09fc698240fdc487372362b7d7c728b963368959a8c0"
  license "BSD-3-Clause"

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    depends_on arch: :arm64
  end

  on_linux do
    on_intel do
      url "https://github.com/Krv-Labs/topos/releases/download/v0.3.12/topos-linux-amd64"
      sha256 "50fc60436762c46200c9858f224f5b0815352a9a01d2862e217d829f0053545e"
    end
    on_arm do
      url "https://github.com/Krv-Labs/topos/releases/download/v0.3.12/topos-linux-arm64"
      sha256 "e1ee6eb00aa2e4734c452b550bba932856b828a54856ac229831e67b45301db7"
    end
  end

  def install
    binary = Dir["topos-*"].first
    bin.install binary => "topos"
    (bin/"topos").chmod 0755

    # Homebrew formulae are non-interactive: warn only (no y/N). Formula-level
    # conflict declarations only cover other formulae, not curl/install.sh.
    foreign = foreign_topos_binaries
    return if foreign.empty?

    opoo <<~EOS
      Another Topos binary was found outside Homebrew:
        #{foreign.join("\n  ")}
      PATH order decides which `topos` runs. Prefer one channel:
        brew upgrade topos
      or remove the foreign binary, then rehash your shell.
    EOS
  end

  def caveats
    lines = <<~EOS
      COMPOSABLE metrics require gitnexus:
        pnpm add -g gitnexus  # or: npm install -g gitnexus

      Register the MCP server for coding agents:
        claude mcp add topos topos mcp
    EOS

    foreign = foreign_topos_binaries
    return lines if foreign.empty?

    lines + <<~EOS

      Another Topos binary was found outside Homebrew:
        #{foreign.join("\n  ")}
      Prefer one install channel. Upgrade this install with:
        brew upgrade topos
      Or remove the foreign binary if you intend to use Homebrew's topos.
    EOS
  end

  def foreign_topos_binaries
    candidates = [
      File.expand_path("~/.local/bin/topos"),
      File.expand_path("~/bin/topos"),
    ]
    # Keep only real files that are not inside this Homebrew prefix.
    candidates.select do |path|
      File.exist?(path) && !path.start_with?("#{HOMEBREW_PREFIX}/")
    end
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/topos --version")
    assert_match "evaluate", shell_output("#{bin}/topos --help")
  end
end
