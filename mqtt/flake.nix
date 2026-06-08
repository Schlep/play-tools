{
  description = "cd-rip: rip from a cd";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs } @ inputs:
  
  let
    inherit (self) outputs;
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config = {
        allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [
          "mqtt-explorer"
        ];
      };
    };

    # Define references to packages
    cyanrip = pkgs.mqtt-explorer;

  in {
    devShells.${system}.default = pkgs.mkShell {
      # Define the packages available in the development shell
      buildInputs = with pkgs; [
        mqtt-explorer
      ];

      packages = [
      ];

      # Environment variables and commands that should run when entering the shell
      shellHook = ''
        echo "use mqtt-explorer"
      '';

    };

  };
}
