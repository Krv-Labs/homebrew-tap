class Topos < Formula
  desc "Structural code quality metrics for agent-written programs"
  homepage "https://docs.krv.ai/topos"
  version "0.3.12"
  license "BSD-3-Clause"

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    on_arm do
      url "https://github.com/Krv-Labs/topos/releases/download/v0.3.12/topos-macos-arm64"
      sha256 "b3e49942a5be7793c6ec09fc698240fdc487372362b7d7c728b963368959a8c0"
    end
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
  end

  def caveats
    <<~EOS
      COMPOSABLE metrics require gitnexus:
        pnpm add -g gitnexus  # or: npm install -g gitnexus

      Register the MCP server for coding agents:
        claude mcp add topos topos mcp
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/topos --version")
  end
end
