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
        # include/prereq-build.mk; stdenv supplies the rest. Its Perl modules
        # (Data::Dumper, FindBin, Thread::Queue, IPC::Cmd, ...) are all core.
        wget
        perl
        rsync
        which
        util-linux # getopt --long
      ];
      hardeningDisable = [ "all" ];
      # libc headers are only known to the cc wrapper; CMake's find_path
      # (e.g. libarchive's iconv.h check in tools/cmake) needs them spelled out.
      CMAKE_INCLUDE_PATH = "${pkgs.lib.getDev pkgs.stdenv.cc.libc}/include";
      # The binutils setup hook exports AR=ar etc., which meson and autotools
      # honour over gcc-ar. Nix binutils has no LTO plugin, so plain ar writes
      # an empty symbol index for LTO objects (e.g. host apk, built with
      # -Db_lto=true). Set in shellHook so it runs after the setup hooks.
      # rules.mk word-splits $(PATH), so an entry with spaces (WSL's Windows
      # paths) yields relative entries, which `find -execdir` refuses.
      shellHook = ''
        export AR=gcc-ar NM=gcc-nm RANLIB=gcc-ranlib
        PATH=$(printf %s "$PATH" | tr : '\n' | grep -v ' ' | paste -sd:)
      '';
    };
  };
}
