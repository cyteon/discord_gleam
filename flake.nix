{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = {nixpkgs, ...}: let
    lib = nixpkgs.lib;
    supportedSystems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    forEachSupportedSystem = f:
      lib.genAttrs supportedSystems (system:
        f {
          pkgs = import nixpkgs {inherit system;};
        });
  in {
    devShells = forEachSupportedSystem ({pkgs}: {
      default = pkgs.mkShell {
        packages = with pkgs; [
          gleam
          erlang_28
          beam28Packages.rebar3
        ];
      };
    });
    apps = forEachSupportedSystem ({pkgs}: let
      runtimeInputs = with pkgs; [
        gleam
        erlang_28
        beam28Packages.rebar3
      ];
    in {
      test = {
        type = "app";
        program = "${(pkgs.writeShellApplication {
          inherit runtimeInputs;
          name = "app";
          text = ''
            ${pkgs.gleam}/bin/gleam test
          '';
        })}/bin/app";
      };
    });
  };
}
