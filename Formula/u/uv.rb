class Uv < Formula
  desc "Extremely fast Python package installer and resolver, written in Rust"
  homepage "https://github.com/astral-sh/uv"
  url "https://github.com/astral-sh/uv/archive/refs/tags/0.1.3.tar.gz"
  sha256 "6141b16dd8651c6a6ad0beaf75ed98185ef1dc268dfbb8e726a5a6b2272a2a69"
  license any_of: ["Apache-2.0", "MIT"]
  head "https://github.com/astral-sh/uv.git", branch: "main"

  bottle do
    sha256 cellar: :any,                 arm64_sonoma:   "3e8440e045fec97dc0f3bdb53b6e82214790b2e574bae7350d6375df0e96060c"
    sha256 cellar: :any,                 arm64_ventura:  "c2545dcdcd473b30e3734b76804279a21b24505e74f5691089688ef0608aafaa"
    sha256 cellar: :any,                 arm64_monterey: "6b15d1de06b56aed7e21322721de63924ac8bd66c456ab1034da4820791c9cb9"
    sha256 cellar: :any,                 sonoma:         "140801bc55204c0d2117cda8e747b880fdec77558918568e34ba64787ccc1ab8"
    sha256 cellar: :any,                 ventura:        "aa4f097cb67b119937cff28ac325bb22ef57dbeeb0f008e6939e84207e0edc57"
    sha256 cellar: :any,                 monterey:       "7127bd70851cf1526501cb9f4d16febaec4c80641233c71316e1d0dacf098ad9"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "a3030b73f1c6ef458f391dbf55df049dea4a680e9e4a712ec9b1d3218c25d6cc"
  end

  depends_on "pkg-config" => :build
  depends_on "rust" => :build
  depends_on "libgit2"
  depends_on "openssl@3"

  uses_from_macos "python" => :test

  def install
    ENV["LIBGIT2_NO_VENDOR"] = "1"

    # Ensure that the `openssl` crate picks up the intended library.
    ENV["OPENSSL_DIR"] = Formula["openssl@3"].opt_prefix
    ENV["OPENSSL_NO_VENDOR"] = "1"

    system "cargo", "install", "--no-default-features", *std_cargo_args(path: "crates/uv")
  end

  def check_binary_linkage(binary, library)
    binary.dynamically_linked_libraries.any? do |dll|
      next false unless dll.start_with?(HOMEBREW_PREFIX.to_s)

      File.realpath(dll) == File.realpath(library)
    end
  end

  test do
    (testpath/"requirements.in").write <<~EOS
      requests
    EOS

    compiled = shell_output("#{bin}/uv pip compile -q requirements.in")
    assert_match "This file was autogenerated by uv", compiled
    assert_match "# via requests", compiled

    [
      Formula["libgit2"].opt_lib/shared_library("libgit2"),
      Formula["openssl@3"].opt_lib/shared_library("libssl"),
      Formula["openssl@3"].opt_lib/shared_library("libcrypto"),
    ].each do |library|
      assert check_binary_linkage(bin/"uv", library),
             "No linkage with #{library.basename}! Cargo is likely using a vendored version."
    end
  end
end
