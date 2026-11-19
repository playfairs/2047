{ nixpkgs, systems }:

nixpkgs.lib.genAttrs systems (system:
  let
    pkgs = import nixpkgs { inherit system; };
  in
  pkgs.writeShellApplication {
    name = "swift-format-project";
    runtimeInputs = [ pkgs.swift-format ];
    text = ''
      find Sources Tests -type f -name '*.swift' -print0 \
        | xargs -0 swift-format format --configuration .swift-format --in-place
    '';
  })
