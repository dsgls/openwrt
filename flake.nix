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
      ];
      hardeningDisable = [ "all" ];
    };
  };
}
