{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };
  outputs = { self, nixpkgs, ... }: {
    devShells."x86_64-linux".default = let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
      };
    in pkgs.mkShell {
      nativeBuildInputs = with pkgs; [
        git
        pkg-config
        ncurses
        unzip
        (python3.withPackages (ps: [ps.setuptools]))
        cdrtools
        swig
        ccache
      ];
      hardeningDisable = [ "all" ];
      # libc headers are only known to the cc wrapper; CMake's find_path
      # (e.g. libarchive's iconv.h check in tools/cmake) needs them spelled out.
      CMAKE_INCLUDE_PATH = "${pkgs.lib.getDev pkgs.stdenv.cc.libc}/include";
    };
  };
}
