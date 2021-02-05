def main(ctx):
    return [
        step("linux", "amd64", "docker.io/nixos/nix"),
        step("linux", "arm64", "docker.io/nickcao/nix-aarch64"),
        {
            "kind": "secret",
            "name": "cachix_token",
            "data": "phZuIBNAXrxnaa84cTWkm2OBR3OhdZ1Du3e3iJtEzp1CtVXCc4t52Afz6H5wrJuS/b9s24udCCDF6gqw+G1E6vRH2R0Ryz5RSZJn0UPRfT8aeMFHcHSLQ1m9oFe3p8bS+RErNrc1TEytop90xuP/RyIgTSHXwUN0ras+L32GSAAy4dRWhq9LFZ4DWmSWwJJcWr+oVEcGsLZ4EfOCEjXKB+L/1vmRVqnKAnNAfM+tqmBEnEY/q+MfDQyOuZuac2pjK/71/yU=",
        },
    ]

def step(os, arch, image):
    return {
        "kind": "pipeline",
        "type": "docker",
        "name": "nix-%s-%s" % (os, arch),
        "platform": {
            "os": os,
            "arch": arch,
        },
        "steps": [
            {
                "name": "check",
                "image": image,
                "commands": [
                    "nix-env -iA nixpkgs.nixFlakes",
                    "echo 'experimental-features = nix-command flakes ca-references' >> /etc/nix/nix.conf",
                    "nix profile install github:NixOS/nixpkgs/nixos-unstable-small#cachix github:NixOS/nixpkgs/nixos-unstable-small#git",
                    "cachix authtoken $CACHIX_TOKEN",
                    "cachix use nichi",
                    "cachix watch-exec nichi -- nix flake check -vL",
                ],
                "environment": {
                    "CACHIX_TOKEN": {
                        "from_secret": "cachix_token",
                    },
                },
            },
        ],
    }
