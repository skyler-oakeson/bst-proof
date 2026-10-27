{
  description = "ECE 6795 Concurrency  Modeling";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    inputs@{ flake-parts, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      perSystem =
        {
          system,
          ...
        }:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };

          build = with pkgs; [
            dafny
          ];

          dev = with pkgs; [
            dotnet-sdk
            (vscode-with-extensions.override {
              vscodeExtensions = pkgs.vscode-utils.extensionsFromVscodeMarketplace [
                {
                  name = "ide-vscode";
                  publisher = "dafny-lang";
                  version = "3.5.4";
                  sha256 = "sha256-4SgWKpCkcLDgYFDzEkYzUcUEdW/8yKHL5y+h+wi6KQc=";
                }
              ];
            })
          ];

          verify = file: "dafny verify --show-snippets --extract-counterexample ${file}";
        in
        {
          packages.default = pkgs.writeShellApplication {
            name = "main";
            runtimeInputs = build;
            text = verify ./main.dfy;
          };

          devShells.default = pkgs.mkShell {
            packages = build ++ dev;
            "DAFNY_DEV_SERVER_OVERRIDE" = "${pkgs.dafny}/lib/Dafny/DafnyLanguageServer.dll";
            "DOTNET_ROOT" = "${pkgs.dotnet-sdk}/share/dotnet/";
            shellHook = ''
              mkdir -p .vscode
              cat > .vscode/settings.json <<EOF
              {
                "dafny.version": "custom",
                "dafny.cliPath": "${pkgs.dafny}/bin/dafny",
                "dafny.dotnetExecutablePath": "${pkgs.dotnet-sdk}/bin/dotnet"
              }
              EOF
            '';
          };
        };
    };
}
