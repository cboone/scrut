class Scrut < Formula
  desc "Simple and powerful test framework for CLI applications"
  homepage "https://facebookincubator.github.io/scrut/"
  url "https://github.com/cboone/scrut.git",
      branch: "main",
      revision: "21a492d06ab5fc59d1b25e2f1a19b5e00ffc8ea6"
  version "0.4.2"
  license "MIT"

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
    generate_completions_from_executable(bin/"scrut", "completions")
  end

  test do
    assert_match "scrut #{version}", shell_output("#{bin}/scrut --version")
  end
end
