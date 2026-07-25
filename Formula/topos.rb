class Topos < Formula
  desc "Structural code quality metrics for agent-written programs"
  homepage "https://docs.krv.ai/topos"
  # macOS default; Linux URLs are defined in the on_linux block. A top-level
  # URL must exist so `brew readall --os=all --arch=all` can load the formula
  # on Intel macOS, where no binary ships (guarded by depends_on arch below).
  url "https://github.com/Krv-Labs/topos/releases/download/v0.4.0/topos-macos-arm64"
  version "0.4.0"
  sha256 "c4c9d7a44cd1ae8ebfc2c6dbbaf237e18fbd6707b634e07f02942b22fcbe8e1f"
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
      url "https://github.com/Krv-Labs/topos/releases/download/v0.4.0/topos-linux-amd64"
      sha256 "21d64271e8bb1cc0aafac12213c864ad2b89caa2cbd199250528b7ac7b014505"
    end
    on_arm do
      url "https://github.com/Krv-Labs/topos/releases/download/v0.4.0/topos-linux-arm64"
      sha256 "e40b3abf141b247ad7f6daaaa34ce2673297b07271e85e38e9706dc389f4c6ff"
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
    # matching dylibs beside the binary and re-sign the bundle ad hoc.
    openssl_lib = formula_opt_lib("openssl@3")
    dylibs = %w[libssl.3.dylib libcrypto.3.dylib]

    dylibs.each do |lib|
      cp openssl_lib/lib, bin/lib
      (bin/lib).chmod 0644
    end

    targets = [bin/"topos", *dylibs.map { |lib| bin/lib }]
    targets.each { |target| rewrite_openssl_links(target) }

    dylibs.each do |lib|
      macho = MachO.open(bin/lib)
      macho.change_dylib_id("@executable_path/#{lib}")
      macho.write!
    end

    system "codesign", "--force", "--sign", "-", *targets
  end

  def rewrite_openssl_links(target)
    macho = MachO.open(target)
    macho.linked_dylibs.each do |dep|
      next unless dep.include?("openssl")

      new_name = if dep.include?("libssl")
        "@executable_path/libssl.3.dylib"
      else
        "@executable_path/libcrypto.3.dylib"
      end
      macho.change_install_name(dep, new_name)
    end
    macho.write!
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/topos --version")
    assert_match "evaluate", shell_output("#{bin}/topos --help")
  end
end
