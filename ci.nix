let flake = (builtins.getFlake (builtins.toPath ./.));
in flake.inputs.nixpkgs.lib.recurseIntoAttrs flake.checks.x86_64-linux
