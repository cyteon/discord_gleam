{pkgs ? import <nixpkgs> {}}:
pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    gleam
    erlang_28
    beam28Packages.rebar3
  ];
}
