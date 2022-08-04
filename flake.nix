{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    haskellNix.url = "github:input-output-hk/haskell.nix";
    nixpkgs.follows = "haskellNix/nixpkgs-unstable";
  };

  # haskell.nix binary cache
  nixConfig = {
    extra-substituters = "https://cache.iog.io";
    extra-trusted-public-keys = "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ=";
  };

  outputs = inputs@{ self, nixpkgs, flake-utils, haskellNix, ... }:
  flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
  let
    compiler-version = "8107";
    compiler-nix-name = "ghc${compiler-version}";
    index-state = "2022-08-04T00:00:00Z";

    overlays = [
      haskellNix.overlay
      (self: super: {
        discord-emoji-dl = self.haskell-nix.cabalProject' {
          src = self.haskell-nix.haskellLib.cleanSourceWith {
            name = "discord-emoji-dl-source";
            src = ./.;
          };
          inherit compiler-nix-name index-state;
          materialized = ./nix/materialized/discord-emoji-dl;
        };
      })
    ];

    pkgs = import nixpkgs {
      inherit system overlays;
      inherit (haskellNix) config;
    };
    flake = pkgs.discord-emoji-dl.flake {};

  in flake // {
    defaultPackage = flake.packages."discord-emoji-dl:exe:discord-emoji-dl";
    devShell = pkgs.discord-emoji-dl.shellFor {
      tools.hoogle = {
        version = "5.0.18.3";
        index-state = "2022-08-04T00:00:00Z";
        materialized = ./nix/materialized/hoogle;
      };
      nativeBuildInputs = with pkgs; [
        cabal-install
        hpack
      ];
      exactDeps = true;
    };
  });
}
