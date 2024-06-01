{
  description = "An installer and configurator for Arch Linux";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;
    rust-overlay = {
      url = github:oxalica/rust-overlay;
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, rust-overlay, ... }:
    let
      systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
      overlays = [ (import rust-overlay) ];
      lib = nixpkgs.lib;
      eachSystem = f: lib.genAttrs systems (system: f rec {
          inherit system;
          pkgs = import nixpkgs { inherit overlays system; };
          rust = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
        });
    in {
      # Packages may include benchmarks, test suites, etc
      packages = eachSystem ({ pkgs, system, rust }: {
        default = (pkgs.makeRustPlatform {
            cargo = rust;
            rustc = rust;
          }).buildRustPackage {
            pname = "archprepare";
            version = "0.1.0";
            src = ./.;
            cargoLock.lockFile = ./Cargo.lock;
          };
      });
      devShells = eachSystem ({ pkgs, system, rust }: {
        default = pkgs.mkShell {
          buildInputs = with pkgs; [ rust ];
        };
      });
    };
}

