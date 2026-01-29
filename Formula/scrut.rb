class Scrut < Formula
  desc "Simple and powerful test framework for CLI applications"
  homepage "https://facebookincubator.github.io/scrut/"
  version "0.4.2"
  license "MIT"

  # Source tarball for building from source (used with --build-from-source)
  url "https://github.com/facebookincubator/scrut/archive/refs/tags/v#{version}.tar.gz"
  sha256 "b384e1f8beaff8ba1bc449f170cf8eac93a383136771fcbaef3e0320eb0f917a"

  # Pre-built binaries (default installation)
  on_macos do
    if Hardware::CPU.arm?
      resource "binary" do
        url "https://github.com/facebookincubator/scrut/releases/download/v#{version}/scrut-v#{version}-macos-aarch64.tar.gz"
        sha256 "b05bf41457af26c7ed9e0dd6434c876e84b2904539dc7c2ffd9c8527fd4883c1"
      end
    elsif Hardware::CPU.intel?
      resource "binary" do
        url "https://github.com/facebookincubator/scrut/releases/download/v#{version}/scrut-v#{version}-macos-x86_64.tar.gz"
        sha256 "652ee38e11a6e9da7e035d5d95b796c05e338214186a8587b73440ef467dbdcf"
      end
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      resource "binary" do
        url "https://github.com/facebookincubator/scrut/releases/download/v#{version}/scrut-v#{version}-linux-aarch64.tar.gz"
        sha256 "5373cc51f85f9b24847a74412b66c4524e987c5b295799b3a98661e7a9f1e944"
      end
    elsif Hardware::CPU.intel?
      resource "binary" do
        url "https://github.com/facebookincubator/scrut/releases/download/v#{version}/scrut-v#{version}-linux-x86_64.tar.gz"
        sha256 "894b12768b5886b8ad244fd6fad19f334c820f296d9f96befacdff32b90b1e6b"
      end
    end
  end

  # Build from latest git HEAD
  head "https://github.com/facebookincubator/scrut.git", branch: "main"

  # Build dependencies (only used when building from source)
  depends_on "rust" => :build

  def install
    if build.head? || build.build_from_source?
      # Build from source using Cargo
      system "cargo", "install", *std_cargo_args
    else
      # Install pre-built binary
      resource("binary").stage do
        bin.install "scrut"
      end
    end

    generate_completions_from_executable(bin/"scrut", shells: [:bash, :fish, :pwsh, :zsh]) do |shell|
      env_value = { bash: "bash_source", fish: "fish_source", pwsh: "powershell_source", zsh: "zsh_source" }.fetch(shell)
      Utils.safe_popen_read({ "_SCRUT_COMPLETE" => env_value }, bin/"scrut")
    end
  end

  test do
    assert_match "scrut #{version}", shell_output("#{bin}/scrut --version")
  end
end
