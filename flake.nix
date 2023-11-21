{
  description = "JesusMtnez's Resume";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    jsonresume-nix.url = "github:TaserudConsulting/jsonresume-nix";
    jsonresume-nix.inputs.nixpkgs.follows = "nixpkgs";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      perSystem = {
        pkgs,
        self',
        inputs',
        ...
      }: {
        # Specify formatter package for "nix fmt ." and "nix fmt . -- --check"
        formatter = pkgs.alejandra;

        devShells.default = inputs'.jsonresume-nix.devShells.default;

        packages.builder = inputs'.jsonresume-nix.packages.resumed-macchiato;

        packages.default = pkgs.runCommand "resume" {} ''
          ln -s ${./resume.json} resume.json
          HOME=$(mktemp -d) ${self'.packages.builder}
          mkdir $out
          cp -v resume.html $out/index.html
        '';

        apps.live.program = builtins.toString (pkgs.writeShellScript "entr-reload" ''
          ${self'.packages.builder}

          ${pkgs.lib.getExe pkgs.nodePackages.live-server} \
            --watch=resume.html --open=resume.html --wait=300 &

          printf "\n%s" resume.{toml,nix,json} |
            ${pkgs.lib.getExe pkgs.xe} -s 'test -f "$1" && echo "$1"' |
            ${pkgs.lib.getExe pkgs.entr} -p ${self'.packages.builder}
        '');
      };
    };
}
