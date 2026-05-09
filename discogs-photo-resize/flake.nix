{
  description = "A very basic flake";

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
        allowUnfreePreficate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [
          #""
        ];
      };
    };

    # Define references to packages
    magick = pkgs.imagemagick;

    # Define any shell scripts
    cvscript = pkgs.writeShellApplication {
      name = "cv";
      runtimeInputs = []; #[ pkgs.curl pkgs.jq ]; # Add dependencies here
      text = ''
        mkdir -p original
        mkdir -p processed
        # Process all JPG images in the current directory
        for file in *.jpg; do
            # Perform the mogrify operation to a new format (e.g., PNG)
            if ${magick}/bin/magick mogrify -strip -quality 75% -rotate 90 -path ./processed "$file"
            then
              mv "$file" ./original
            fi
        done
      '';
    };

    mcvscript = pkgs.writers.writeFishBin "mcv" ''
      mkdir -p original
      mkdir -p processed
      while true
        if count *.jpg >/dev/null
          #file=(ls -AU *.jpg | head -1)
          set file (ls -AU *.jpg | head -1)
          sleep 1
          if [ -f $file ]
            echo "process $file"
            if ${magick}/bin/magick mogrify -strip -quality 75% -rotate 90 -path ./processed "$file"
              mv "$file" ./original
            end
          end
        end
      end
    '';

  in {
    devShells.${system}.default = pkgs.mkShell {
      # Define the packages available in the development shell
      buildInputs = with pkgs; [
        magick
      ];

      packages = [
        cvscript
        mcvscript
      ];

      # Environment variables and commands that should run when entering the shell
      shellHook = ''
        echo "use cv to convert the images"
        echo "use mcv to monitor and convert the images"
      '';

    };


  };
}
