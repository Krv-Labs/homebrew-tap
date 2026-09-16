class Topos < Formula
  desc "Structural code quality metrics for agent-written programs"
  homepage "https://docs.krv.ai/topos"
  # macOS default; Linux URLs are defined in the on_linux block. A top-level
  # URL must exist so `brew readall --os=all --arch=all` can load the formula
  # on Intel macOS, where no binary ships (guarded by depends_on arch below).
  # No explicit `version`: Homebrew scans it from the release tag in the URL
  # (Version::UrlParser for `releases/download/<tag>/`, brew >= 6.0.14). An
  # explicit stanza duplicates that and fails `brew audit` in tap CI.
  url "https://github.com/Krv-Labs/topos/releases/download/v0.6.0/topos-macos-arm64"
  sha256 "7a299233ebc61b6dc4fba1b93c76b05ef793152a4a3f5f608b73747ccf4a1da6"
  license "BSD-3-Clause"

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    depends_on arch: :arm64
    depends_on "openssl@3"
  end

  on_linux do
    on_intel do
      url "https://github.com/Krv-Labs/topos/releases/download/v0.6.0/topos-linux-amd64"
      sha256 "c244e8defa50014992cf04087a5b530d6002dccb27da818af9763f3f3c1ac37e"
    end
    on_arm do
      url "https://github.com/Krv-Labs/topos/releases/download/v0.6.0/topos-linux-arm64"
      sha256 "9c83e93c1079e3d38cfd8824abb28f868fc53f15bae3c7e5872dcdf79956bfba"
    end
  end

  def install
    binary = Dir["topos-*"].first
    bin.install binary => "topos"
    (bin/"topos").chmod 0755
    bundle_openssl_on_macos if OS.mac?

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

  def bundle_openssl_on_macos
    # Release binaries are Developer ID signed but link Homebrew OpenSSL paths
    # from the build runner. macOS rejects that Team ID mix at runtime, so ship
    # matching dylibs in libexec, rewrite load paths, and re-sign ad hoc.
    openssl_lib = formula_opt_lib("openssl@3")
    dylibs = %w[libssl.3.dylib libcrypto.3.dylib]

    libexec.mkpath
    dylibs.each do |lib|
      cp openssl_lib/lib, libexec/lib
      (libexec/lib).chmod 0644
    end

    rewrite_openssl_links(bin/"topos", loader_base: "@loader_path/../libexec")

    dylibs.each do |lib|
      dylib = libexec/lib
      rewrite_openssl_links(dylib, loader_base: "@loader_path")
      macho = MachO.open(dylib)
      macho.change_dylib_id("@loader_path/#{lib}")
      macho.write!
    end

    targets = [bin/"topos", *dylibs.map { |lib| libexec/lib }]
    system "codesign", "--force", "--sign", "-", *targets
  end

  def rewrite_openssl_links(target, loader_base:)
    macho = MachO.open(target)
    macho.linked_dylibs.each do |dep|
      next unless dep.include?("openssl")

      lib_name = dep.include?("libssl") ? "libssl.3.dylib" : "libcrypto.3.dylib"
      macho.change_install_name(dep, "#{loader_base}/#{lib_name}")
    end
    macho.write!
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/topos --version")
    assert_match "evaluate", shell_output("#{bin}/topos --help")
  end
end
