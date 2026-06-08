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
          #""
        ];
      };
    };

    # Define references to packages
    cyanrip = pkgs.cyanrip;

    # Define any shell scripts
    ripscript = pkgs.writeShellApplication {
      name = "rip";
      runtimeInputs = []; #[ pkgs.curl pkgs.jq ]; # Add dependencies here
      text = ''
        mkdir -p rip

        # Rips current CD to FLAC
        #
        echo "Usage: rip.sh [release id] ""[track list]"" [priority]"
        echo "  [release id]   : The ID of the release to rip (optional) or 'n' for no lookup"
        echo "  [track list]   : A comma-separated list of track numbers to rip (optional)"
        echo "  [priority]     : The priority of the rip (default: max)"
        echo ""

        if [[ -n "''${1:-}" ]]; then
            if [[ "''${1,,}" = "n" ]]; then
                RARG=""
                NARG="-N"
            else
                RARG="-R $1"
                NARG=""
            fi
        else
            RARG=""
            NARG=""
        fi
        echo RARG:["$RARG"]
        echo NARG:["$NARG"]

        if [[ -n "''${2:-}" ]]
        then
            FIRSTITEM=$(echo "''$2" | cut -d ',' -f 1)
            echo FIRSTITEM:["$FIRSTITEM"]

            FIRSTVAL=$(printf "_%02d" "''${FIRSTITEM}")

            LARG="-l $2"
            QARG=""
        else
            FIRSTVAL=""
            LARG=""
            QARG="-Q"
        fi
        echo FIRSTVAL:["$FIRSTVAL"]
        echo LARG:["$LARG"]
        echo QARG:["$QARG"]

        if [[ -n "''${3:-}" ]]
        then
            PARG="-P $3"
        else
            PARG="-P max"
        fi
        echo PARG:["$PARG"]

        #shellcheck disable=SC2086
        systemd-inhibit ${cyanrip}/bin/cyanrip -U $QARG -o flac -s 667 $PARG $RARG $NARG $LARG -T simple \
        -L "{album}{if #totaldiscs# > #1# CD|disc|}$FIRSTVAL" \
        -M "{album}{if #releasecomment# > #0# (|releasecomment|)}$FIRSTVAL" \
        -D "rip/{album_artist}/{album}{if #releasecomment# > #0# (|releasecomment|)}{if #totaldiscs# > #1# - |disc|}{if #discname# > #0# |discname|}" \
        -F "{track} {title}"
      '';
    };

  in {
    devShells.${system}.default = pkgs.mkShell {
      # Define the packages available in the development shell
      buildInputs = with pkgs; [
        cyanrip
      ];

      packages = [
        ripscript
      ];

      # Environment variables and commands that should run when entering the shell
      shellHook = ''
        echo "use rip to rip from the cd"
      '';

    };

  };
}
